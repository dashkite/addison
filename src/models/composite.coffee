import { metaclass } from "@dashkite/joy/metaclass"
import { pipe } from "@dashkite/joy/function"
import { Queue } from "@dashkite/joy/iterable"
import { start } from "@dashkite/river"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"
import EventReactor from "@dashkite/reactive/event-reactor"

import Value from "@dashkite/addison/value"
import iterable from "@dashkite/addison/mixins/iterable"
import resolveable from "@dashkite/addison/mixins/resolveable"
import resourceful from "@dashkite/addison/mixins/resourceful"

class Composite extends do pipe [ 
    metaclass, iterable, 
    resolveable, resourceful 
  ]

  @getters

    valid: ->
      for key of @resources
        if !( Object.hasOwn @value, key )
          return false
      true

  @make: ( locators ) ->
    instance = Object.assign new @, { locators }
    instance

  constructor: ->
    super()
    @resources = {}
    @types = {}
    @outgoing = Channel.make()
    @incoming = Channel.make()
    @internal = Channel.make()
    @value ?= {}
    start @logic()

  _get: ->
    ( resource.get()) for name, resource of @resources
    return

  _put: ->
    ( resource.put @value[ name ]?.data ) for name, resource of @resources
    return

  _delete: ->
    ( resource.delete() ) for name, resource of @resources
    return

  _clear: -> @value = {}
  
  resolve: ( specifier ) ->
    for name, { type, locator... } of @locators
      @types[ name ] = type ? Value
      { bindings, rest... } = locator
      @resources[ name ] = await Belmont.resolve {
        rest...
        bindings: {
          specifier?[ name ]...
          bindings...
        }
      }
      @incoming.source do ( name, self = @ ) ->
        for await event from self.resources[ name ].subscribe()
          event.source = name
          yield event

    @internal.send name: "resolve"
    @

  listen: ->

    yield from EventReactor

      .make @incoming

      .bind @

      .forward "*"

      .when "resource.value, resource.created", ( event ) ->

        { source } = event
        @value[ source ] = Value.from event.value
  
        yield {
          event...
          scope: "model"
          source
          value: @value[ source ]
        }

        if @valid
          yield 
            name: "value"
            scope: "model"
            value: @value
          @internal.send name: "valid"

      .when "not-found", ( event ) ->
        { source } = event
        if ( fallback = @fallbacks?[ source ] )?
          T = @types[ source ]
          @value[ source ] = T.from fallback
          @resources[ source ].put fallback
          yield {
            name: "value"
            scope: "model"
            source
            value: @value[ source ]
          }
          yield {
            name: "value"
            scope: "model"
            @value
          }
        else
          @value[ source ] = undefined
        if @valid
          @internal.send name: "valid"

      .when "delete", ( event ) ->
        { source } = event
        @value[ source ] = undefined
        yield { name: "delete", scope: "model", source }

      .when "method-not-allowed[method='get']", ( event ) ->
        # you can't get this resource
        # so treat it as valid (but undefined)
        { source } = event
        @value[ source ] = undefined
        if @valid
          @internal.send name: "valid"

    await return

export { Composite }
export default Composite
