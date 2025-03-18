import Basic from "../src/mixins/basic"
import { getters } from "../src/helpers/meta"

{ resource } = Basic

class Greeting

  resource @, template: "local:/components/greeting"

  listen: -> @state.listen()

  close: -> @state.close()
  
  "set greeting": ( greeting ) ->
    @state.put ( state ) -> state = greeting
  
export default Greeting
