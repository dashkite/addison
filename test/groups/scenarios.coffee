import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import Lakeshore from "@dashkite/lakeshore"
import { remove } from "@dashkite/joy/array"
import { tee } from "@dashkite/joy/function"
import Model from "@dashkite/addison/composite"

class List extends Model

  @make: ->

    super
      internal: template: "mock:/scenarios/list"
      list: template: "mock:/scenarios/favorite-movies"

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

export default ->

  test "Scenarios", do ->

    Lakeshore.register "mock:/scenarios/list",
      get: -> description: "ok", content: selected: null
      put: -> description: "ok", exists: true

    Lakeshore.register "mock:/scenarios/favorite-movies",
      get: -> description: "ok", content: []
      put: -> description: "ok", exists: true

    list = List.make()

    [
      test "handles sequential mutations", ->

        await list.resolve()
        list.add "The Godfather"
        list.add "Ran"
        list.select "Ran"
        list.remove "Ran"

        await assert.expect ->
          ( list.value.list?.data.length == 1 ) &&
            ( list.value.list?.data[ 0 ] == "The Godfather" ) &&
            ( list.value.internal?.data.selected == "The Godfather" )
    ]
