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
    initialized: -> @_initialized

  @make: ({ type, locator... }) -> 
    type ?= Value
    Object.assign new @, { type, locator }

  constructor: ->
    super()
    @resource = {}
    @internal = Channel.make()
    @outgoing = Channel.make()
    @_initialized = false
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

  _post: ( data ) -> @resource.post data

  _clear: -> @value = undefined

  listen: ->

    yield from EventReactor

      .make @incoming
      .bind @

      .forward "*"

      .when "resource.value", ( event ) ->
        @value = @type.from event.value
        @_initialized = true
        @internal.send name: "initialized"
        yield { event..., @value, scope: "model" }

      .when "resource.created", ( event ) ->
        unless event.locator?
          @value = @type.from event.value
          @_initialized = true
          @internal.send name: "initialized"
        yield { event..., scope: "model" }

      .when "not-found", ->
        if ( fallback = @fallback )?
          @value = @type.from fallback
          @resource.put fallback
        else
          @value = undefined
        @_initialized = true
        @internal.send name: "initialized"

      .when "delete", ->
        @_clear()
        yield { name: "delete", scope: "model" }

      .when "method-not-allowed", ( event ) ->
        if event.method == "get"
          # you can't get this resource
          # so treat it as valid (but undefined)
          @value = undefined
          @_initialized = true
          @internal.send name: "initialized"
      
    await return

export { Atomic }
export default Atomic
