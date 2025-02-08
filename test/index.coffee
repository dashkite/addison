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
    for i in [0...10]
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
      await greeting[ "set greeting" ] "hello!"
      await greeting[ "set profile" ] email: "bob@acme.org"

      greeting.activate()

      await expect ->
        greeting.state.value.profile? &&
          greeting.state.value.greeting?

      await greeting[ "set greeting" ] "hola!"
    
      await expect ->
        greeting.state.value.greeting == "hola!"

    test "Complex Component", ->

      list = await List.resolve()

      # initializing for testing purposes
      # (not actually part of the test)
      list.state.value = { list: [], state: {}}
      await list[ "add item" ] "The Godfather"
      await list[ "add item" ] "Ran"
      await list[ "select item" ] "Ran"

      # list.activate()

      # await expect ->
      #   list.state.value.state?.selected? &&
      #     ( list.state.value.list?.length == 2 ) &&
      #     ( list.state.resources.state.resource.observers.size > 0 ) &&
      #     ( list.state.resources.list.resource.observers.size > 0 )

      await list[ "remove item" ] "Ran"
    
      await expect ->
        ( list.state.value.list.length == 1 ) &&
          ( list.state.value.state.selected == "The Godfather" )


  ]

  process.exit if success then 0 else 1
