import * as Arr from "@dashkite/joy/array"
import * as Meta from "@dashkite/joy/metaclass"
import Basic from "../src/mixins/basic"

{ resources, transitions } = Basic

class List

  Meta.mixin @, [

    resources
      state: template: "local:/components/list"
      list: template: "local:/lists/favorite-movies"

    transitions

      "add item": 
        scope: [ "list" ], 
        transition: ( item, { list }) ->
          list.push item
          { list }

      "select item":
        scope: [ "state" ]
        transition: ( item, { state }) ->
          state.selected = item
          { state }

      "remove item":
        scope: [ "state", "list" ], 
        transition: ( item, { state, list }) ->
          Arr.remove item, list
          if state.selected == item
            state.selected = list[0]
          { state, list }

  ]


export default List