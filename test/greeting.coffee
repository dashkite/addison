import * as Obj from "@dashkite/joy/object"
import Montrose from "@dashkite/montrose"

class Greeting

  @make: ->

    greeting = await Montrose.resolve 
      template: "local:/components/greeting"

    profile = await Montrose.resolve 
      template: "local:/profile"

    Object.assign ( new @ ), { greeting, profile, values: [] }
  
  observe: ->

    self = @

    # we have to set up our local state before setting up
    # the observers because otherwise a non-local update
    # could trigger our observer before our local state
    # is fully initialized...

    state =
      
      greeting: Obj.get "value",
        await @greeting
          .get()
          .resolve "value"

      profile: Obj.get "value",
        await @profile
          .get()
          .resolve "value"

    @greeting
      .observe()
      .when "update", ({ value: greeting }) ->
        state.greeting = greeting
        self.values.push structuredClone state
      .run()

    @profile
      .observe()
      .when "update", ({ value: profile }) ->
        state.profile = profile
        self.values.push structuredClone state
      .run()

    @greeting.observer.dispatch name: "update", value: state.greeting
    @profile.observer.dispatch name: "update", value: state.profile

  cancel: ->
    @greeting.cancel()
    @profile.cancel()
  
  "set greeting": ( greeting ) ->
    @greeting
      .put greeting 
      .resolve "success"

  "set profile": ( profile ) ->
    @profile
      .put profile 
      .resolve "success"

  "delete item", transition [ "list", "state" ], ( item, { list, state }) ->
    if state.selected == item
      state.selected = list[0]
    Arr.remove item, list
    { list, state }


    # Promise.all [      
    #   @list
    #     .put list
    #     .resolve "success"
    #   @state
    #     .put state
    #     .resolve "success"
    # ]
export default Greeting