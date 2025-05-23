import resource from "../src/mixins/resource"

class Greeting extends do ( resource template: "local:/components/greeting" )

  "set greeting": ( greeting ) ->
    @model.put ( state ) -> state = greeting
  
export default Greeting
