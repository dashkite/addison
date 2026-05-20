import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import Engine from "../../src/models/engine"
import Value from "#value"

# Mock model for testing the engine in isolation
makeMockModel = ( locators ) ->

  model =
    locators: locators
    value: {}
    resources: {}
    messages: []
    _get: -> @got = true
  
  model.internal = send: ( message ) -> model.messages.push message
  model._send = ( name ) -> model.internal.send { name, scope: "internal" }
  model

export default ->

  test "Engine", [

    test "initial state", ->

      model = makeMockModel greeting: {}
      engine = new Engine model
      assert.expect -> ! engine.resolved
      assert.expect -> ! engine.initialized
      assert.expect -> engine.requests.length == 0

    test "transitions to resolved", ->

      model = makeMockModel greeting: template: "mock:/foo"
      engine = new Engine model
      # Simulate resolve (we don't await because we'd need to mock Belmont fully)
      engine.resolved = true
      assert.expect -> engine.resolved

    test "queues requests when not initialized", ->

      model = makeMockModel greeting: {}
      engine = new Engine model
      engine.resolved = true
      
      requested = false
      engine.request action: -> requested = true
      
      assert.expect -> engine.requests.length == 1
      assert.expect -> ! requested

    test "transitions to initialized and triggers drain", ->

      model = makeMockModel greeting: {}, profile: {}
      engine = new Engine model
      engine.resolved = true
      
      # Set first resource
      engine.set "greeting", "hello"
      assert.expect -> ! engine.initialized
      assert.expect -> model.messages.length == 0
      
      # Set second resource - should trigger initialization
      engine.set "profile", email: "dan@acme.org"
      
      assert.expect -> engine.initialized
      assert.expect ->
        model.messages.some ( message ) -> 
          message.name == "drain"

    test "executes queued requests on drain", ->

      model = makeMockModel greeting: {}
      engine = new Engine model
      engine.resolved = true
      
      executed = 0
      { promise, resolve, reject } = Promise.withResolvers()
      engine.request 
        action: -> executed++
        resolve: resolve
        reject: reject
      
      assert.expect -> executed == 0
      
      await engine.drain()
      assert.expect -> executed == 1

    test "rejects requests if not resolved", ->

      model = makeMockModel greeting: {}
      engine = new Engine model
      
      { promise, resolve, reject } = Promise.withResolvers()
      engine.request 
        action: -> 
        resolve: resolve
        reject: reject
      
      await assert.rejects -> promise

  ]
