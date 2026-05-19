import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import { tee } from "@dashkite/joy/function"
import { sleep } from "@dashkite/joy/time"

import Providers from "@dashkite/belmont/providers"
import Lakeshore from "@dashkite/lakeshore"
Providers.add "mock", Lakeshore

import Value from "@dashkite/addison/value"

# test components
import Greeting from "./greeting"
import PersonalizedGreeting from "./personalized-greeting"
import List from "./list"

# Register mock responses
Lakeshore.register "mock:/components/greeting",
  get: -> { description: "ok", content: "hello!" }
  put: -> { description: "ok", exists: true }
  delete: -> { description: "ok" }
  post: ( _, data ) -> 
    { description: "created", content: data, locator: { template: "mock:/greetings/1" } }

Lakeshore.register "mock:/components/greeting/:name",
  get: ({ bindings }) -> { description: "ok", content: "hello, #{bindings.name}!" }
  put: -> { description: "ok", exists: true }

Lakeshore.register "mock:/profile",
  get: -> { description: "ok", content: { email: "dan@dashkite.com" } }
  put: -> { description: "ok", exists: true }
  delete: -> { description: "ok" }

Lakeshore.register "mock:/components/list",
  get: -> { description: "ok", content: { selected: null } }
  put: -> { description: "ok", exists: true }

Lakeshore.register "mock:/lists/favorite-movies",
  get: -> { description: "ok", content: [] }
  put: -> { description: "ok", exists: true }

wait = ( events, predicate, timeout = 1000 ) ->
  Promise.race [
    do ->
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
      await sleep timeout
      throw new Error "Timeout waiting for event"
  ]

do ->

  print await test "Addison", [

    test "Atomic", await do ({ greeting } = {}) ->

      greeting = Greeting.make()

      [
        await test "throws if mutated before resolution", ->
          assert.rejects -> greeting.put (v) -> v
        
        await test "resolves successfully", ->
          await greeting.resolve()
          await wait greeting, ({ name, scope }) -> 
            ( name == "value" ) && ( scope == "model" )
          assert.expect -> greeting.value.data == "hello!"

        await test "updates via put", ->
          greeting.put ( v ) -> 
            v.data = "hola!"
            v
          await assert.expect -> greeting.value?.data == "hola!"

        await test "creates via post", ->
          greeting.post ( v ) -> 
            v.data = "hi!"
            v
          event = await wait greeting, ({ name, scope }) -> 
            name == "created" && scope == "resource"
          assert.expect -> event.value.data == "hi!"

        await test "deletes resource", ->
          greeting.delete()
          await wait greeting, ({ name, scope }) -> 
            name == "deleted" && scope == "resource"
          assert.expect -> greeting.value == undefined
      ]

    test "Composite", await do ({ greeting } = {}) ->

      greeting = PersonalizedGreeting.make()

      [

        await test "throws if mutated before resolution", ->
          await assert.rejects -> greeting.put (v) -> v

        await test "queues early requests", ->
          # Issue a put immediately after starting resolve, without awaiting
          promise = greeting.resolve greeting: name: "Dan"
          greeting.put ( v ) ->
            v.greeting.data = "greetings!"
            v
          await promise
          # Wait for aggregate initialization
          await wait greeting, ({ name, scope }) -> 
            ( name == "value" ) && ( scope == "model" )
          # The put should have executed after initialization
          await assert.expect -> greeting.value.greeting?.data == "greetings!"

        await test "resolves successfully", ->
          # Already resolved from previous test, but we can check state
          assert.expect -> greeting.value.profile?.data.email == "dan@dashkite.com"

        await test "updates via put", ->
          greeting.put tee ({ profile }) -> 
            profile.data.email = "alice@acme.org"
          await assert.expect -> greeting.value.profile?.data.email == "alice@acme.org"

        await test "deletes aggregate", ->
          greeting.delete()
          await wait greeting, ({ name, source }) -> 
            ( name == "deleted" ) && ( source == "greeting" )
          assert.expect -> greeting.value.greeting == undefined

      ]

    test "Edge Cases", do ->
      [
        test "clears on method-not-allowed", ->
          Lakeshore.register "mock:/forbidden",
            get: -> { description: "method-not-allowed" }
          
          model = Greeting.make()
          model.locator.template = "mock:/forbidden"
          await model.resolve()
          
          await wait model, ({ name }) -> name == "method-not-allowed"
          assert.expect -> model.value == undefined
      ]

    test "Complex Model", do ->
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
  ]

  process.exit if success then 0 else 1
