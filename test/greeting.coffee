import Addison from "../src"

class Greeting

  @make: ->

    state = await Addison.make
      greeting: template: "local:/components/greeting"
      profile: template: "local:/profile"

    await state.resolve()

    Object.assign ( new @ ), { state, values: [] }
  
  activate: -> 
    @state
      .observe()
      # .when "update", ({ value }) ->
      #   console.log value
      .run()

  deactivate: -> @state.cancel()
  
  "set greeting": ( greeting ) ->
    @state.transition [ "greeting" ], -> { greeting }

  "set profile": ( profile ) ->
    @state.transition [ "profile" ], -> { profile }

export default Greeting