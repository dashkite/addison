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

wait = ( events, predicate ) ->
  loop
    event = await events.receive()
    return event if predicate event

do ->

  print await test "Addison", [

    test "Atomic", ->

      greeting = await Greeting.resolve()
      events = greeting.listen()

      greeting[ "set greeting" ] "hello!"
      
      # Wait for a non-protocol event (value or created)
      event = await wait events, ( e ) -> e.name in [ "value", "created" ]

      assert.equal "resource", event.scope
    
      await assert.expect ->
        greeting.model.value == "hello!"

    test "Composite", ->

      greeting = await PersonalizedGreeting.resolve()
      events = greeting.listen()

      greeting[ "set greeting" ] "hello!"
      
      # Wait for the forwarded sub-resource event
      event = await wait events, ( e ) -> 
        ( e.name in [ "value", "created" ] ) && ( e.source == "greeting" )
      
      assert.equal "resource", event.scope

      greeting[ "set profile" ] email: "bob@acme.org"

      # Wait for the forwarded sub-resource event
      event = await wait events, ( e ) -> 
        ( e.name in [ "value", "created" ] ) && ( e.source == "profile" )
      
      assert.equal "resource", event.scope

      # Wait for the aggregate value event
      event = await wait events, ( e ) -> 
        ( e.name == "value" ) && ( e.scope == "model" )

      assert.equal undefined, event.source
    
      await assert.expect ->
        greeting.model.value.greeting == "hello!"

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
