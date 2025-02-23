import { Queue } from "@dashkite/joy/iterable"
import * as Fn from "@dashkite/joy/function"
import EventReactor from "@dashkite/reactive/event-reactor"
import { getters } from "#helpers/meta"
import Addison from "../index"

Basic =

  resources: ( T, locators ) ->

    T.make = ->
      state = Addison.make locators
      self = Object.assign ( new @ ), { state }
      self

    T::resolve = ( specifier ) -> 
      @initialize?()
      await @state.resolve specifier
      @

    T.resolve = ( specifier ) ->
      T.make().resolve specifier

    getters T::,
      resources: -> @state.resources
      channel: -> @state.channel


export default Basic
