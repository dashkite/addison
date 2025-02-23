import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"

import * as Time from "@dashkite/joy/time"

import Providers from "@dashkite/belmont/providers"
import Halstead from "@dashkite/halstead"
Providers.add "local", Halstead

frame = ->
  new Promise ( resolve ) ->
    queueMicrotask resolve

expect = ( assertion ) ->
  new Promise ( resolve, reject ) ->
    for i in [0...100]
      if assertion()
        resolve()
        break
      await frame()
    reject new Error "expect: assertion timeout"

# test components
import Greeting from "./greeting"
import List from "./list"

do ->

  print await test "Addison", [

    test "Basic Component", ->

      greeting = await Greeting.make()

      # initializing for testing purposes
      # (not actually part of the test)
      greeting[ "set greeting" ] "hello!"
      greeting[ "set profile" ] email: "bob@acme.org"
      # initialize values
      greeting.start()
      # update value
      greeting[ "set greeting" ] "hola!"
    
      await expect ->
        greeting.state.value.greeting == "hola!"

    test "Complex Component", ->

      list = await List.resolve()

      list.state.value = { list: [], internal: {}}
      list[ "add item" ] "The Godfather"
      list[ "add item" ] "Ran"
      list[ "select item" ] "Ran"
      list[ "remove item" ] "Ran"
    
      await expect ->
        ( list.state.value.list.length == 1 ) &&
          ( list.state.value.internal.selected == "The Godfather" )

  ]

  process.exit if success then 0 else 1
