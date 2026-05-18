import { metaclass } from "@dashkite/joy/metaclass"
import { pipe, identity } from "@dashkite/joy/function"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"
import EventReactor from "@dashkite/reactive/event-reactor"
import Value from "@dashkite/addison/value"

import iterable from "@dashkite/addison/mixins/iterable"

class Composite extends do pipe [ metaclass, iterable ]

  @make: ( locators ) ->
    instance = Object.assign new @, { locators }
    instance

  @resolve: ( specifier ) ->
    ( @make specifier )
      .resolve specifier

  @getters
    initialized: ->
      switch @_status
        when "resolved"
          Object
            .values @_initialized
            .every identity
        when "initialized"
          true
        else
          false

  constructor: ->
    super()
    @resources = {}
    @types = {}
    @requests = []
    @value = {}
    @_initialized = {}
    @outgoing = Channel.make()

  get: -> 
    @execute ->
      @_get()

  put: ( mutator ) ->
    @execute ->
      @value = await mutator @value
      @_put()

  delete: ->
    @execute ->
      @_clear()
      @_delete()

  post: ( builder ) ->
    @execute ->
      @_post await builder @value

  _start: ->
    if @initialized
      @_start = ->
      ( await action.call @ ) for action in @requests
      @requests = []
      undefined

  execute: ( action ) ->
    switch @_status
      when "resolving", "resolved"
        { promise, resolve, reject } = Promise.withResolvers()
        @requests.push ->
          Promise
            .resolve action.call @
            .then resolve
            .catch reject
        promise
      when "initialized"
        action.call @
      else
        throw new Error "addison: 
          attempt to invoke a resource method
          but the model is unresolved
          (resolve was never called)"

  resolve: ( specifier ) ->
    @_status = "resolving"
    @incoming = Channel.make()
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
      incoming = @resources[ name ].subscribe()
      @incoming.source do ( name, incoming ) ->
        for await event from incoming
          yield { event..., source: name }
      @_initialized[ name ] = false
    @_status = "resolved"
    @outgoing.source @_listen()
    @_get()
    @

  _get: ->
    ( resource.get()) for name, resource of @resources
    return

  _put: ->
    ( resource.put @value[ name ]?.data ) for name, resource of @resources
    return

  _delete: ->
    ( resource.delete()) for name, resource of @resources
    return

  _post: ( data ) ->
    ( @resources[ name ].post value ) for name, value of data
    return

  _clear: -> @value = {}

  _listen: ->

    EventReactor

      .make @incoming
      .bind @      

      .forward "*"

      .when "resource.value", ( event ) ->
        { source } = event
        @value[ source ] = Value.from event.value
        yield { event..., scope: "model", source, value: @value[ source ] }
        @_initialized[ source ] = true
        if @initialized
          @_status = "initialized"
          yield { name: "value", scope: "model", value: @value }
        @_start()

      .when "resource.created", ( event ) ->
        { source } = event
        unless event.locator?
          @value[ source ] = Value.from event.value
          @_initialized[ source ] = true
          if @initialized
            @_status = "initialized"
            yield { name: "value", scope: "model", value: @value }
        yield { event..., scope: "model", source }
        @_start()

      .when "not-found", ( event ) ->
        { source } = event
        fallback = @fallbacks?[ source ] ? @fallback
        if fallback?
          T = @types[ source ] ? Value
          @value[ source ] = value = T.from fallback
          @resources[ source ].put fallback
          yield { event..., name: "value", scope: "model", source, value }
          @_initialized[ source ] = true
          if @initialized
            @_status = "initialized"
            yield { name: "value", scope: "model", value: @value }
        else
          @value[ source ] = undefined
          @_initialized[ source ] = true
          if @initialized then @_status = "initialized"
        yield event
        @_start()

      .when "delete", ( event ) ->
        { source } = event
        @value[ source ] = undefined
        yield { event..., name: "delete", scope: "model", source }

      .when "method-not-allowed[method='get']", ( event ) ->
        { source } = event
        @value[ source ] = undefined
        @_initialized[ source ] = true
        if @initialized then @_status = "initialized"
        yield event
        @_start()

export { Composite }
export default Composite
