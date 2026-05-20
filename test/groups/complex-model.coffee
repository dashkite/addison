import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import Lakeshore from "@dashkite/lakeshore"
import List from "../models/list"

export default ->
  test "Complex Model", do ->

    Lakeshore.register "mock:/complex/list",
      get: -> { description: "ok", content: { selected: null } }
      put: -> { description: "ok", exists: true }

    Lakeshore.register "mock:/complex/favorite-movies",
      get: -> { description: "ok", content: [] }
      put: -> { description: "ok", exists: true }

    list = List.make()
    # Override locators to use local mock paths
    list.locators.internal.template = "mock:/complex/list"
    list.locators.list.template = "mock:/complex/favorite-movies"

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
