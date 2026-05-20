import { metaclass } from "@dashkite/joy/metaclass"
import { pipe, identity } from "@dashkite/joy/function"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"
import EventReactor from "@dashkite/reactive/event-reactor"
import Value from "#value"

import iterable from "#mixins/iterable"
import Engine from "./engine"

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
    if @resolution?
      return @resolution
    { promise, resolve, reject } = Promise.withResolvers()
    @resolution = promise
    @_send "resolve", { specifier, resolve, reject }
    promise

  _send: ( name, data ) ->
    @internal.send { name, scope: "internal", data... }

  _get: ->
    for name, resource of @resources
      await resource.get()
    return

  _put: ->
    for name, resource of @resources
      await resource.put @value[ name ]?.data
    return

  _delete: ->
    for name, resource of @resources
      await resource.delete()
    return

  _post: ( data ) ->
    for name, value of data
      await @resources[ name ].post value
    return

  _clear: -> @value = {}

  _logic: ->

    engine = new Engine @

    aggregate = do ( self = @ ) -> ->
      if engine.initialized
        yield { name: "value", scope: "model", value: self.value }

    fallback = ( source ) =>
      if ( result = @fallbacks?[ source ])?
        @resources[ source ].put result
      result

    EventReactor

      .make @internal
      .bind @      

      .forward "!internal.*"

      .when "internal.request", ( event ) ->
        engine.request event

      .when "internal.resolve", ( event ) ->
        engine.resolve event

      .when "internal.drain", ->
        engine.drain()

      .when "resource.value", ( event ) ->
        { source } = event
        engine.set source, event.value
        yield from aggregate()

      .when "resource.created", ( event ) ->
        { source } = event
        unless event.locator?
          engine.set source, event.value
          yield from aggregate()

      .when "resource.deleted", ( event ) ->
        engine.set event.source, undefined
        yield from aggregate()

      .when "failure", ( event ) ->
        { source, response } = event
        if response?.description == "not found"
          if ( data = fallback source )?
            engine.set source, data
          else
            engine.set source, undefined
        else
          engine.set source, undefined
        yield from aggregate()
        return

export { Composite }
export default Composite
