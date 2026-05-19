import { remove } from "@dashkite/joy/array"
import { tee } from "@dashkite/joy/function"
import Model from "@dashkite/addison/models/composite"

class List extends Model

  @make: ->
    super
      internal: template: "mock:/components/list"
      list: template: "mock:/lists/favorite-movies"

  fallbacks:
    list: []
    internal: {}

  add: ( item ) ->
    @put tee ({ list }) -> list.data.push item

  select: ( item ) ->
    @put tee ({ internal }) -> internal.data.selected = item

  remove: ( item ) ->
    @put tee ({ list, internal }) ->
      remove item, list.data
      if internal.data.selected == item
        internal.data.selected = list.data[0]

export default List