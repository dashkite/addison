import * as Fn from "@dashkite/joy/function"
import Basic from "../src/mixins/basic"
import { getters } from "../src/helpers/meta"

{ resources, defaults } = Basic


class Greeting

  resources @,
    greeting: template: "local:/components/greeting"
    profile: template: "local:/profile"

  listen: -> @state.listen()

  close: -> @state.close()
  
  "set greeting": ( greeting ) ->
    @state.put Fn.tee ( state ) -> state.greeting = greeting
  
  "set profile": ( profile ) ->
    @state.put  Fn.tee ( state ) -> state.profile = profile

export default Greeting
