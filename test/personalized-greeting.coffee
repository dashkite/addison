import * as Fn from "@dashkite/joy/function"
import { resources } from "../src/mixins/resources"

class Greeting extends do (
    resources
      greeting: template: "local:/components/greeting"
      profile: template: "local:/profile"
  )
  
  "set greeting": ( greeting ) ->
    @model.put Fn.tee ( state ) -> state.greeting = greeting
  
  "set profile": ( profile ) ->
    @model.put  Fn.tee ( state ) -> state.profile = profile

export default Greeting
