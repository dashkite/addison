import * as Arr from "@dashkite/joy/array"
import Basic from "../src/mixins/basic"
import { getters } from "../src/helpers/meta"

{ resources, defaults } = Basic

class List

  resources @,
    internal: template: "local:/components/list"
    list: template: "local:/lists/favorite-movies"

  defaults @,
    list: []
    internal: {}

  listen: -> @state.listen()

  close: -> @state.close()

  "add item": ( item ) ->
    @state.put ({ list }) -> 
      list.push item

  "select item": ( item ) ->
    @state.put ({ internal }) ->
      internal.selected = item

  "remove item": ( item ) ->
    @state.put ({ list, internal }) ->
      Arr.remove item, list
      if internal.selected == item
        internal.selected = list[0]

export default List