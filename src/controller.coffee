import { metaclass } from "@dashkite/joy/metaclass"

class Controller extends metaclass()

  @resolve: ( specifier ) -> @make().resolve specifier

  resolve: ( specifier ) ->
    await @model.resolve specifier
    await @start?()
    @

  listen: -> @model.listen()

  close: -> @model.close()
  
export { Controller }
export default Controller