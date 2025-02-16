import { Queue } from "@dashkite/joy/iterable"
import * as Fn from "@dashkite/joy/function"
import EventReactor from "@dashkite/reactive/event-reactor"
import Addison from "../index"

Basic =

  resources: ( locators ) ->
    ( T ) ->
      T.make = ->
        state = Addison.make locators
        self = Object.assign ( new @ ), { state }
        self
      T::resolve = ( specifier ) ->
        await @state.resolve specifier
        @initialize?()

  activate: activate = ( decorator ) ->
    ( T ) ->
      T::activate = -> ( decorator.apply @, [ @state.observe() ]).run() 
      T::deactivate = -> @state.cancel()

  reactor: Fn.pipe [
    Fn.tee ( T ) ->
      T::initialize = -> @queue = new Queue
      T::apply = ->
        self = @
        EventReactor.from do ->
          loop yield await self.queue.dequeue()
    activate ( observer ) -> 
      observer.when "update", ({ value }) => @queue.enqueue value
  ]
  
  transition: ( name, scope, transition ) ->
    ( T ) ->
      T::[ name ] = Fn.arity ( transition.length - 1 ), 
        ( args... ) ->
          @state.transition scope, ( state ) =>
            transition.apply @, [ args..., state ]

  transitions: ( dictionary ) ->
    Fn.pipe do ->
      for name, { scope, transition } of dictionary
        Fn.tee Basic.transition name, scope, transition

export default Basic