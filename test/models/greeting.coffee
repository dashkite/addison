import Lakeshore from "@dashkite/lakeshore"
import Model from "@dashkite/addison/models/atomic"

Lakeshore.register "mock:/components/greeting",
  get: -> { description: "ok", content: "hello!" }
  put: -> { description: "ok", exists: true }
  delete: -> { description: "ok" }
  post: ( _, data ) -> 
    { description: "created", content: data, locator: { template: "mock:/greetings/1" } }

class Greeting extends Model

  @make: -> super template: "mock:/components/greeting"
  
  fallback: "hello!"

export default Greeting
