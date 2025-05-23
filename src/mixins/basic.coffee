import { Queue } from "@dashkite/joy/iterable"
import * as Fn from "@dashkite/joy/function"
import { metaclass } from "@dashkite/joy/metaclass"
import EventReactor from "@dashkite/reactive/event-reactor"
import { getters } from "../helpers/meta"
import { Composite, Atomic } from "../index"


Basic =

  resource: ( T, locator ) ->

    T.make = ->
      model = Atomic.make locator
      self = Object.assign ( new @ ), { model }
      self

    T::resolve = ( specifier ) -> 
      await @model.resolve specifier
      await @start?()
      @

    T.resolve = ( specifier ) ->
      @make().resolve specifier

    getters T::,
      resource: -> @model.resource
      channel: -> @model.outgoing    

  resources: ( T, locators ) ->

    T.make = ->
      model = Composite.make locators
      self = Object.assign ( new @ ), { model }
      self

    T::resolve = ( specifier ) -> 
      await @model.resolve specifier
      await @start?()
      @

    T.resolve = ( specifier ) ->
      @make().resolve specifier

    getters T::,
      resources: -> @model.resources
      channel: -> @model.channel

  fallbacks: ( T, fallbacks ) ->
    T::start = -> @model.fallbacks = fallbacks

  fallback: ( T, fallback ) ->
    T::start = -> @model.fallback = fallback

  
export default Basic
