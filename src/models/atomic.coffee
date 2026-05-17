import { metaclass } from "@dashkite/joy/metaclass"
import { pipe } from "@dashkite/joy/function"
import { start } from "@dashkite/river"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"
import EventReactor from "@dashkite/reactive/event-reactor"

import Value from "@dashkite/addison/value"
import iterable from "@dashkite/addison/mixins/iterable"
import resolveable from "@dashkite/addison/mixins/resolveable"
import resourceful from "@dashkite/addison/mixins/resourceful"

class Atomic extends do pipe [ 
    metaclass, iterable, 
    resolveable, resourceful 
  ]

  @getters
    valid: -> Object.hasOwn @, "value"

  @make: ({ type, locator... }) -> 
    type ?= Value
    Object.assign new @, { type, locator }

  constructor: ->
    super()
    @resource = {}
    @internal = Channel.make()
    @outgoing = Channel.make()
    start @logic()

  resolve: ( specifier ) ->
    { bindings, rest... } = @locator
    @resource = await Belmont.resolve {
      rest...
      bindings: { specifier..., bindings... }
    }
    @incoming = @resource.subscribe()
    @internal.send name: "resolve"
    @

  _get: -> @resource.get()

  _put: -> @resource.put @value.data

  _delete: -> @resource.delete()

  _clear: -> @value = undefined

  listen: ->

    yield from EventReactor

      .make @incoming
      .bind @

      .forward "*"

      .when "resource.value, resource.created", ( event ) ->
        @value = @type.from event.value
        @internal.send name: "valid"
        yield { event..., @value, scope: "model" }

      .when "not-found", ->
        if ( fallback = @fallback )?
          @value = @type.from fallback
          @internal.send name: "valid"
          @resource.put fallback
        else
          @value = undefined
          @internal.send name: "valid"

      .when "delete", ->
        @value = undefined
        yield { name: "delete", scope: "model" }

      .when "method-not-allowed", ( event ) ->
        if event.method == "get"
          # you can't get this resource
          # so treat it as valid (but undefined)
          @value = undefined
          @internal.send name: "valid"
      
    await return

export { Atomic }
export default Atomic
