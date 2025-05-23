import * as Arr from "@dashkite/joy/array"
import * as Fn from "@dashkite/joy/function"
import resources from "../src/mixins/resources"

class List extends do (
    resources
      internal: template: "local:/components/list"
      list: template: "local:/lists/favorite-movies"
  )

  @fallbacks
    list: []
    internal: {}

  "add item": ( item ) ->
    @model.put Fn.tee ({ list }) -> 
      list.push item

  "select item": ( item ) ->
    @model.put Fn.tee ({ internal }) ->
      internal.selected = item

  "remove item": ( item ) ->
    @model.put Fn.tee ({ list, internal }) ->
      Arr.remove item, list
      if internal.selected == item
        internal.selected = list[0]

export default List