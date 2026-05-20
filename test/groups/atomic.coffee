import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import Lakeshore from "@dashkite/lakeshore"
import Atomic from "@dashkite/addison/atomic"
import { wait } from "../helpers"

export default ->

  test "Atomic", await do ({ greeting } = {}) ->

    Lakeshore.register "mock:/atomic/greeting",
      get: -> { description: "ok", content: "hello!" }
      put: -> { description: "ok", exists: true }
      delete: -> { description: "ok" }
      post: ( _, data ) -> 
        { description: "created", content: data, locator: { template: "mock:/greetings/1" } }

    greeting = Atomic.make template: "mock:/atomic/greeting"
    greeting.fallback = "hello!"

    [
      await test "throws if mutated before resolution", ->

        assert.rejects -> greeting.put ( v ) -> v
      
      await test "resolves successfully", ->

        await greeting.resolve()
        await wait greeting, ({ name, scope }) -> 
          ( name == "value" ) && ( scope == "resource" )
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
          ( name == "created" ) && ( scope == "resource" )
        assert.expect -> event.value.data == "hi!"

      await test "deletes resource", ->

        greeting.delete()
        await wait greeting, ({ name, scope }) -> 
          ( name == "deleted" ) && ( scope == "resource" )
        assert.expect -> greeting.value == undefined
    ]
