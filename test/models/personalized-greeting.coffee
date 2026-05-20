import Lakeshore from "@dashkite/lakeshore"
import Model from "@dashkite/addison/models/composite"

Lakeshore.register "mock:/components/greeting/:name",
  get: ({ bindings }) -> { description: "ok", content: { data: "hello, #{bindings.name}!" } }
  put: -> { description: "ok", exists: true }

Lakeshore.register "mock:/profile",
  get: -> { description: "ok", content: { email: "dan@dashkite.com" } }
  put: -> { description: "ok", exists: true }
  delete: -> { description: "ok" }

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
