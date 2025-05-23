import Composite from "../models/composite"
import Controller from "../controller"

resources = ( locators ) ->

  ( Base = Controller ) ->

    class extends Base

      @make = ->
        Object.assign ( new @ ),
          model: Composite.make locators

      @getters
        resources: -> @model.resources
        channel: -> @model.channel

      @fallbacks: ( value ) ->
        @::start = -> @model.fallbacks = value

export { resources }
export default resources