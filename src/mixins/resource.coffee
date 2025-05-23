import Atomic from "../models/atomic"
import Controller from "../controller"

resource = ( locator ) ->

  ( Base = Controller ) ->

    class extends Base

      @make: ->
        Object.assign ( new @ ),
          model: Atomic.make locator

      @getters
        resource: -> @model.resource
        channel: -> @model.outgoing

      @fallback: ( value ) ->
        @::start = -> @model.fallback = value


export { resource }
export default resource