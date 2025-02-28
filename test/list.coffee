import * as Arr from "@dashkite/joy/array"
import * as Meta from "@dashkite/joy/metaclass"
import Basic from "../src/mixins/basic"
import HTTP from "../src/helpers/http"
import { getters } from "../src/helpers/meta"

{ resources, transitions } = Basic

class List

  resources @,
    internal: template: "local:/components/list"
    list: template: "local:/lists/favorite-movies"

  getters @,
    resources: -> @state.resources

  "add item": ( item ) ->
    @state.put [ "list" ], ({ list }) -> 
      list.push item
      { list }

  "select item":( item ) ->
    @state.put [ "internal" ], ({ internal }) ->
      internal.selected = item
      { internal }

  "remove item": ( item ) ->
    @state.put [ "list", "internal" ], ({ list, internal }) ->
      Arr.remove item, list
      if internal.selected == item
        internal.selected = list[0]
      { list, internal }
 
export default List