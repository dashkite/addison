import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"

import * as Time from "@dashkite/joy/time"

import Providers from "@dashkite/belmont/providers"
import Halstead from "@dashkite/halstead"
Providers.add "local", Halstead

# test components
import Greeting from "./greeting"
import PersonalizedGreeting from "./personalized-greeting"
import List from "./list"

do ->

  print await test "Addison", [

    test "Atomic", ->

      greeting = await Greeting.resolve()

      greeting.listen()

      greeting[ "set greeting" ] "hello!"
      greeting[ "set greeting" ] "hola!"
    
      await assert.expect ->
        greeting.model.value == "hola!"

    test "Composite", ->

      greeting = await PersonalizedGreeting.resolve()

      greeting.listen()

      greeting[ "set greeting" ] "hello!"
      greeting[ "set profile" ] email: "bob@acme.org"
      # update value
      greeting[ "set greeting" ] "hola!"
    
      await assert.expect ->
        greeting.model.value.greeting == "hola!"

    test "Complex Component", ->

      list = await List.resolve()

      list.listen()

      list[ "add item" ] "The Godfather"
      list[ "add item" ] "Ran"
      list[ "select item" ] "Ran"
      list[ "remove item" ] "Ran"
    
      await assert.expect timeout: 5000, ->
        # console.log list.state.value
        ( list.model.value.list?.length == 1 ) &&
          ( list.model.value.internal?.selected == "The Godfather" )

  ]

  process.exit if success then 0 else 1
