import { metaclass } from "@dashkite/joy/metaclass"
import { pipe, tee } from "@dashkite/joy/function"
import Channel from "@dashkite/reactive/channel"
import EventReactor from "@dashkite/reactive/event-reactor"

import iterable from "#mixins/iterable"
import Model from "@dashkite/addison/composite"

class Atomic extends do pipe [ metaclass, iterable ]

  @make: ( locator ) -> 
    Object.assign new @, { 
      locator
      model: Model.make $: locator
    }

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
    for await { event..., value, source } from @model
      if event.scope == "model"
        yield { event..., value: value?.$ }
      else
        yield { event..., value }

export { Atomic }
export default Atomic
