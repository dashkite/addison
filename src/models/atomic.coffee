import { metaclass } from "@dashkite/joy/metaclass"
import { pipe, tee } from "@dashkite/joy/function"
import Channel from "@dashkite/reactive/channel"
import EventReactor from "@dashkite/reactive/event-reactor"

import iterable from "#mixins/iterable"
import Model from "@dashkite/addison/composite"

class Atomic extends do pipe [ metaclass, iterable ]

  @make: ( locator ) -> 
    model = Model.make $: locator
    self = Object.assign new @, { locator, model }
    self.model.fallbacks = $: self.fallback
    self

  @resolve: ( specifier ) ->
    ( @make specifier )
      .resolve specifier

  @getters
    value: -> @model.value.$

  constructor: ->
    super()
    @outgoing = Channel.make()

  resolve: ( specifier ) ->
    promise = @model.resolve $: specifier
    @outgoing.source @_listen()
    promise

  get: -> @model.get()

  put: ( mutator ) ->
    @model.put tee ( value ) ->
      value.$ = await mutator value.$

  delete: -> @model.delete()

  post: ( builder ) ->
    @model.post ( value ) ->
      $: await builder value.$

  _listen: ->
    for await { event..., source } from @model
      if source? || ( event.scope != "model" )
        yield event

export { Atomic }
export default Atomic
