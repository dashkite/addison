import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import { tee } from "@dashkite/joy/function"
import Lakeshore from "@dashkite/lakeshore"
import Composite from "@dashkite/addison/composite"
import { wait } from "../helpers"

export default ->
  test "Composite", await do ({ greeting } = {}) ->

    Lakeshore.register "mock:/composite/greeting/:name",
      get: ({ bindings }) -> { description: "ok", content: { data: "hello, #{bindings.name}!" } }
      put: -> { description: "ok", exists: true }

    Lakeshore.register "mock:/composite/profile",
      get: -> { description: "ok", content: { email: "dan@dashkite.com" } }
      put: -> { description: "ok", exists: true }
      delete: -> { description: "ok" }

    greeting = Composite.make
      greeting: template: "mock:/composite/greeting/{name}"
      profile: template: "mock:/composite/profile"
    
    greeting.fallbacks = greeting: "hello!"

    [

      await test "throws if mutated before resolution", ->
        await assert.rejects -> greeting.put ( v ) -> v

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
        # Wait for resource-level update
        await wait greeting, ({ name, scope, source }) ->
          ( name == "value" ) && ( scope == "resource" ) && ( source == "profile" )
        await assert.expect -> greeting.value.profile?.data.email == "alice@acme.org"

      await test "deletes aggregate", ->
        greeting.delete()
        await wait greeting, ({ name, source }) -> 
          ( name == "deleted" ) && ( source == "greeting" )
        assert.expect -> greeting.value.greeting == undefined

    ]
