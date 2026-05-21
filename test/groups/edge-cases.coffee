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
          assert.equal model.value, undefined

      test "handles variant initialization", ->

        do ({ model } = {}) ->

          Lakeshore.register "mock:/edge-cases/mixed/a",
            get: -> description: "ok", content: "A"
          Lakeshore.register "mock:/edge-cases/mixed/b",
            get: -> description: "not found"
          Lakeshore.register "mock:/edge-cases/mixed/c",
            get: -> description: "not found"

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

          assert.equal model.value.a.data, "A"
          assert.equal model.value.b.data, "B"
          assert.equal model.value.c, undefined

      test "clears state on definitive failures", ->

        do ({ model } = {}) ->

          Lakeshore.register "mock:/edge-cases/errors/unauthorized",
            get: -> description: "unauthorized"
          
          model = Atomic.make template: "mock:/edge-cases/errors/unauthorized"
          await model.resolve()
          
          await wait model, ({ name }) -> name == "failure"
          assert.equal model.value, undefined

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

          assert.equal model.value.data.items.length, 5
          assert.deepEqual model.value.data.items, [ 1..5 ]

      test "throws on resolve with empty locators", ->

        do ({ model } = {}) ->

          model = Composite.make {}
          await assert.rejects -> model.resolve()

      test "is idempotent on multiple resolve calls", ->

        do ({ model } = {}) ->

          Lakeshore.register "mock:/edge-cases/idempotency",
            get: -> description: "ok", content: "ok"
          
          model = Atomic.make template: "mock:/edge-cases/idempotency"
          
          p1 = model.resolve()
          p2 = model.resolve()
          
          assert.equal p1, p2
          
          await p1
          p3 = model.resolve()
          assert.equal p1, p3

      test "handles targeted get", ->

        do ({ model, counters } = {}) ->

          counters = a: 0, b: 0
          Lakeshore.register "mock:/edge-cases/targeted/get/a",
            get: -> description: "ok", content: ++counters.a
          Lakeshore.register "mock:/edge-cases/targeted/get/b",
            get: -> description: "ok", content: ++counters.b
          
          model = Composite.make
            a: template: "mock:/edge-cases/targeted/get/a"
            b: template: "mock:/edge-cases/targeted/get/b"
          
          await model.resolve()
          await wait model, ({ name, scope }) -> 
            ( name == "value" ) && ( scope == "model" )

          assert.equal counters.a, 1
          assert.equal counters.b, 1
          
          await model.get "a"

          # verify that the value event for a shows up
          await wait model, ({ name, source }) -> 
            ( name == "value" ) && ( source == "a" )
          
          assert.equal counters.a, 2
          assert.equal counters.b, 1

      test "handles targeted delete", ->

        do ({ model } = {}) ->

          Lakeshore.register "mock:/edge-cases/targeted/delete/a",
            get: -> description: "ok", content: "A"
            delete: -> description: "ok"
          Lakeshore.register "mock:/edge-cases/targeted/delete/b",
            get: -> description: "ok", content: "B"
            delete: -> description: "ok"
          
          model = Composite.make
            a: template: "mock:/edge-cases/targeted/delete/a"
            b: template: "mock:/edge-cases/targeted/delete/b"
          
          await model.resolve()
          await wait model, ({ name, scope }) -> 
            ( name == "value" ) && ( scope == "model" )

          await model.delete "a"

          # verify that the deleted event for a shows up
          await wait model, ({ name, source }) -> 
            ( name == "deleted" ) && ( source == "a" )
          
          assert.equal model.value.a, undefined
          assert model.value.b?

      test "ensures snapshot safety", ->

        do ({ model } = {}) ->

          Lakeshore.register "mock:/edge-cases/snapshot",
            get: -> description: "ok", content: foo: "bar"
          
          model = Atomic.make template: "mock:/edge-cases/snapshot"
          await model.resolve()

          await wait model, ({ name, scope }) -> 
            ( name == "value" ) && ( scope == "resource" )
          
          # Get value and attempt to mutate it directly
          val = model.value
          val.data.foo = "mutated"
          
          # Subsequent read should be unchanged
          assert.equal model.value.data.foo, "bar"
          
          # Verify aggregate level safety as well
          model = Composite.make a: template: "mock:/edge-cases/snapshot"
          await model.resolve()

          await wait model, ({ name, scope }) -> 
            ( name == "value" ) && ( scope == "model" )
          
          agg = model.value
          delete agg.a
          assert model.value.a?
    ]
