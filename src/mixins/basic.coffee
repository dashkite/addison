import * as Fn from "@dashkite/joy/function"
import Addison from "../index"

Basic =

  resources: ( locators ) ->
    ( T ) ->
      T.resolve = ->
        state = await Addison.resolve locators
        Object.assign ( new @ ), { state }

  transition: ( name, scope, transition ) ->
    ( T ) ->
      T::[ name ] = Fn.arity ( transition.length - 1 ), 
        ( args... ) ->
          @state.transition scope, ( state ) ->
            transition args..., state

  transitions: ( dictionary ) ->
    Fn.pipe do ->
      for name, { scope, transition } of dictionary
        Fn.tee Basic.transition name, scope, transition

export default Basic