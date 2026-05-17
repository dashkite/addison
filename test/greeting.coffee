import Model from "@dashkite/addison/models/atomic"

class Greeting extends Model

  @make: -> super template: "local:/components/greeting"
  
  fallback: "hello!"

export default Greeting
