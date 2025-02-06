import * as Arr from "@dashkite/joy/array"
import Addison from "../src"

class List

  @make: ->

    state = await Addison.resolve
      state: template: "local:/components/list"
      list: template: "local:/lists/favorite-movies"
    
    state.value =
      state: {}
      list: []

    Object.assign ( new @ ), { state }
  
  activate: -> 
    @state
      .observe()
      # .when "update", ({ value }) ->
      #   console.log value
      .run()

  deactivate: -> @state.cancel()
  
  "add item": ( item ) ->
    @state.transition [ "list" ], ({ list }) ->
      list.push item
      { list }

  "select item": ( item ) ->
    @state.transition [ "state" ], ({ state }) ->
      state.selected = item
      { state }

  "remove item": ( item ) ->
    @state.transition [ "state", "list" ], ({ state, list }) ->
      Arr.remove item, list
      if state.selected == item
        state.selected = list[0]
      { state, list }

export default List