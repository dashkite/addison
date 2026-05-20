import Lakeshore from "@dashkite/lakeshore"
import { remove } from "@dashkite/joy/array"
import { tee } from "@dashkite/joy/function"
import Model from "@dashkite/addison/composite"

Lakeshore.register "mock:/components/list",
  get: -> { description: "ok", content: { selected: null } }
  put: -> { description: "ok", exists: true }

Lakeshore.register "mock:/lists/favorite-movies",
  get: -> { description: "ok", content: [] }
  put: -> { description: "ok", exists: true }

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
        internal.data.selected = list.data[ 0 ]

export default List
