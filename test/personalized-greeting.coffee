import Model from "@dashkite/addison/models/composite"

class Greeting extends Model

  @make: ->
    super
      greeting: template: "local:/components/greeting/{name}"
      profile: template: "local:/profile"

  @resolve: ( bindings ) -> 
    @make()
      .resolve bindings
  
  fallbacks:
    greeting: "hello!"
  
export default Greeting
