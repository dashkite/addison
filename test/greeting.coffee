import Addison from "../src"

class Greeting

  @make: ->

    state = await Addison.make
      greeting: template: "local:/components/greeting"
      profile: template: "local:/profile"

    await state.resolve()

    Object.assign ( new @ ), { state, values: [] }
  
  start: -> 
    for await event from @state.observe()
      undefined
    undefined

  stop: -> @state.cancel()
  
  "set greeting": ( greeting ) ->
    @state.put [ "greeting" ], -> { greeting }

  "set profile": ( profile ) ->
    @state.put [ "profile" ], -> { profile }

export default Greeting