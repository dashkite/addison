import Model from "@dashkite/addison/models/atomic"

class Greeting extends Model

  @make: -> super template: "mock:/components/greeting"
  
  fallback: "hello!"

export default Greeting
