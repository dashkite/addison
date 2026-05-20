import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import Lakeshore from "@dashkite/lakeshore"
import { sleep } from "@dashkite/joy/time"
import Composite from "@dashkite/addison/composite"
import Atomic from "@dashkite/addison/atomic"
import { wait } from "../helpers"

export default ->

  test "Edge Cases", [

      test "clears on method-not-allowed", ->

        do ({ model } = {}) ->

          Lakeshore.register "mock:/edge-cases/method-not-allowed",
            get: -> description: "method-not-allowed"
          
          model = Atomic.make template: "mock:/edge-cases/method-not-allowed"

          await model.resolve()
          
          await wait model, ({ name }) -> name == "failure"
          assert.expect -> model.value == undefined

      test "handles variant initialization", ->

        do ({ model } = {}) ->

          Lakeshore.register "mock:/edge-cases/mixed/a",
            get: -> { description: "ok", content: "A" }
          Lakeshore.register "mock:/edge-cases/mixed/b",
            get: -> { description: "not found" }
          Lakeshore.register "mock:/edge-cases/mixed/c",
            get: -> { description: "not found" }

          model = Composite.make
            a: template: "mock:/edge-cases/mixed/a"
            b: template: "mock:/edge-cases/mixed/b"
            c: template: "mock:/edge-cases/mixed/c"
          
          model.fallbacks = b: "B"

          await model.resolve()

          # Wait for aggregate initialization
          await wait model, ({ name, scope, source }) -> 
            ( name == "value" ) &&
              ( scope == "model" ) &&
              ( !source? )

          assert.expect ->
            ( model.value.a.data == "A" ) &&
            ( model.value.b.data == "B" ) &&
            ( model.value.c == undefined )

      test "clears state on definitive failures", ->

        do ({ model } = {}) ->

          Lakeshore.register "mock:/edge-cases/errors/unauthorized",
            get: -> { description: "unauthorized" }
          
          model = Atomic.make template: "mock:/edge-cases/errors/unauthorized"
          await model.resolve()
          
          await wait model, ({ name }) -> name == "failure"
          assert.expect -> model.value == undefined

      test "propagates provider rejections", ->

        do ({ model } = {}) ->

          Lakeshore.register "mock:/edge-cases/crash",
            get: -> description: "ok", content: "foo"
            put: -> throw new Error "unexpected error"
          
          model = Atomic.make template: "mock:/edge-cases/crash"
          await model.resolve()
          
          await assert.rejects -> 
            model.put ( v ) -> v

      test "serializes rapid sequential mutations", ->

        do ({ model, items } = {}) ->

          Lakeshore.register "mock:/edge-cases/stress",
            get: -> { description: "ok", content: { items } }
            put: ( _, { items }) -> 
              await sleep 10 # Introduce some latency
              description: "ok", exists: true, content: { items }
          
          items = []
          model = Atomic.make template: "mock:/edge-cases/stress"
          await model.resolve()

          # Fire 5 synchronous updates
          results = for i in [ 1..5 ]
            do ( i ) ->
              model.put ( value ) -> 
                value.data.items.push i
                value
          
          # Wait for all of them to resolve
          await Promise.all results

          assert.expect ->
            model.value.data.items.length == 5

          assert.deepEqual [ 1..5 ], model.value.data.items

      test "throws on resolve with empty locators", ->

        do ({ model } = {}) ->

          model = Composite.make {}
          await assert.rejects -> model.resolve()

      test "is idempotent on multiple resolve calls", ->

        do ({ model } = {}) ->

          Lakeshore.register "mock:/edge-cases/idempotency",
            get: -> { description: "ok", content: "ok" }
          
          model = Atomic.make template: "mock:/edge-cases/idempotency"
          
          p1 = model.resolve()
          p2 = model.resolve()
          
          assert.expect -> p1 == p2
          
          await p1
          p3 = model.resolve()
          assert.expect -> ( await p3 ) == model
    ]
