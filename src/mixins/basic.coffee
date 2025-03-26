import { Queue } from "@dashkite/joy/iterable"
import * as Fn from "@dashkite/joy/function"
import EventReactor from "@dashkite/reactive/event-reactor"
import { getters } from "../helpers/meta"
import { Composite, Atomic } from "../index"

Basic =

  resource: ( T, locator ) ->

    T.make = ->
      state = Atomic.make locator
      self = Object.assign ( new @ ), { state }
      self

    T::resolve = ( specifier ) -> 
      await @state.resolve specifier
      await @start?()
      @

    T.resolve = ( specifier ) ->
      @make().resolve specifier

    getters T::,
      resource: -> @state.resource
      channel: -> @state.outgoing    

  resources: ( T, locators ) ->

    T.make = ->
      state = Composite.make locators
      self = Object.assign ( new @ ), { state }
      self

    T::resolve = ( specifier ) -> 
      await @state.resolve specifier
      await @start?()
      @

    T.resolve = ( specifier ) ->
      @make().resolve specifier

    getters T::,
      resources: -> @state.resources
      channel: -> @state.channel

  fallbacks: ( T, fallbacks ) ->
    T::start = -> @state.fallbacks = fallbacks

  fallback: ( T, fallback ) ->
    T::start = -> @state.fallback = fallback

  
export default Basic
