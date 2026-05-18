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

  constructor: ->
    super()
    @resources = {}
    @value = {}
    @outgoing = Channel.make()
    @internal = Channel.make()
    @outgoing.source @_logic()

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

  execute: ( action ) ->
    { promise, resolve, reject } = Promise.withResolvers()
    @_send "request", { resolve, reject, action }
    promise

  resolve: ( specifier ) -> 
    @_send "resolve", { specifier }
    @

  _send: ( name, data ) ->
    @internal.send { name, scope: "internal", data... }

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

  _logic: ->
    
    self = @
    types = {}
    initialized = false
    resolved = false
    requests = []

    has = ( key ) -> Object.hasOwn self.value, key

    set = ( key, value ) ->

      self.value[ key ] = 
        if value?
          T = types[ key ] ? Value
          T.from value

      if !initialized

        initialized = 
          Object
            .keys self.locators
            .every has

        if initialized
          self._send "drain"

      self.value[ key ]

    run = ({ resolve, reject, action }) ->
      try
        resolve await action.call self
      catch error
        reject error

    EventReactor

      .make @internal
      .bind @      

      .forward "!internal.*"

      .when "internal.request", ({ action, resolve, reject }) ->
        if resolved
          if initialized && ( requests.length == 0 )
            await run { action, resolve, reject }
          else 
            requests.push { action, resolve, reject }
        else 
          reject new Error "addison: 
            attempt to invoke a resource method
            but the model is unresolved
            (resolve was never called)"

      .when "internal.resolve", ( event ) ->
        { specifier } = event
        for name, { type, locator... } of @locators
          types[ name ] = type ? Value
          { bindings, rest... } = locator
          @resources[ name ] = await Belmont.resolve {
            rest...
            bindings: {
              specifier?[ name ]...
              bindings...
            }
          }
          incoming = @resources[ name ].subscribe()
          @internal.source do ( name, incoming ) ->
            for await event from incoming
              yield { event..., source: name }
        resolved = true
        @_get()

      .when "internal.drain", ->
        ( await run requests.shift()) while requests.length > 0

      .when "resource.value", ( event ) ->
        { source } = event
        value = set source, event.value
        yield { event..., scope: "model", value }
        if initialized
          yield { name: "value", scope: "model", value: @value }

      .when "resource.created", ( event ) ->
        { source } = event
        unless event.locator?
          value = set source, event.value
          if initialized
            yield { name: "value", scope: "model", value: @value }

      .when "response.not-found", ( event ) ->
        { source } = event
        fallback = @fallbacks?[ source ] ? @fallback
        if fallback?
          value = set source, fallback
          @resources[ source ].put fallback
          yield { name: "value", scope: "model", value }
          if initialized
            yield { name: "value", scope: "model", value: @value }
        else
          set source, undefined

      # TODO allow for whitespace in selector list
      .when "resource.deleted,*.method-not-allowed[method='get']", 
        ( event ) ->
          { source } = event
          set source, undefined

export { Composite }
export default Composite
