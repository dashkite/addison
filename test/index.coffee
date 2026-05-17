import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"

import { tee } from "@dashkite/joy/function"

import Providers from "@dashkite/belmont/providers"
import Halstead from "@dashkite/halstead"
Providers.add "local", Halstead

import Value from "@dashkite/addison/value"

# test components
import Greeting from "./greeting"
import PersonalizedGreeting from "./personalized-greeting"
import List from "./list"

wait = ( events, predicate ) ->
  if events.receive?
    loop
      event = await events.receive()
      return event if predicate event
  else
    loop
      { done, value } = await events.next()
      break if done == true
      return value if predicate value

do ->

  print await test "Addison", [

    test "Atomic", ->

      do ({ greeting } = {}) ->

        greeting = await Greeting.resolve()

        # Wait for a non-protocol event (value or created)
        event = await wait greeting, ({ name, scope }) -> 
          ( name in [ "value", "created" ]) &&
            ( scope == "resource" )

        assert event?
      
        greeting.put ( greeting ) -> 
          greeting.data = "hola!"
          greeting
        
        await assert.expect -> 
          greeting.value.data == "hola!"

        greeting.delete()
        event = await wait greeting, ({ name, scope }) -> 
          name == "delete" && scope == "model"
        
        assert event?
        assert greeting.value == undefined

    test "Composite", ->

      do ({ greeting } = {}) ->

        greeting = await PersonalizedGreeting.resolve greeting: name: "Dan"

        greeting.put tee ({ greeting }) -> greeting.data = "hola!"
        
        # Wait for the forwarded sub-resource event
        event = await wait greeting, ({ name, scope, source }) -> 
          ( name in [ "value", "created" ]) && 
            ( scope == "model" ) &&
            ( source == "greeting" )
        
        assert event?

        greeting.put tee ( value ) -> 
          value.profile = Value.from email: "alice@acme.org"

        # Wait for the forwarded sub-resource event
        event = await wait greeting, ({ name, scope, source }) -> 
          ( name in [ "value", "created" ]) && 
            ( scope == "resource" ) &&
            ( source == "profile" )
        
        assert event?

        # Wait for the aggregate value event
        event = await wait greeting, ({ name, scope, source }) -> 
          ( name in [ "value", "created" ]) && 
            ( scope == "model" ) &&
            ( source == "profile" )

        assert event?

        await assert.expect ->
          greeting.value.greeting.data == "hola!"

        greeting.delete()
        
        # Verify sub-resource delete events are forwarded
        event = await wait greeting, ({ name, scope, source }) -> 
          name == "delete" && scope == "model" && source == "greeting"
        assert event?

        event = await wait greeting, ({ name, scope, source }) -> 
          name == "delete" && scope == "model" && source == "profile"
        assert event?

        assert greeting.value.greeting == undefined
        assert greeting.value.profile == undefined

    test "Complex", ->

      do ({ list } = {}) ->

        list = List.make()
        await list.resolve()

        list.add "The Godfather"
        list.add "Ran"
        list.select "Ran"
        list.remove "Ran"

        await assert.expect ->
          ( list.value.list?.data?.length == 1 ) &&
            ( list.value.list?.data?[ 0 ] == "The Godfather" ) &&
            ( list.value.internal?.data.selected == "The Godfather" )

  ]

  process.exit if success then 0 else 1
