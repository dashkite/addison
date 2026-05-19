import Model from "@dashkite/addison/models/composite"

class Greeting extends Model

  @make: ->
    super
      greeting: template: "mock:/components/greeting/{name}"
      profile: template: "mock:/profile"

  @resolve: ( bindings ) -> 
    @make()
      .resolve bindings
  
  fallbacks:
    greeting: "hello!"
  
export default Greeting
