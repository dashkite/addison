import EventReactor from "@dashkite/reactive/event-reactor"

resolveable = ( base ) ->

  class extends base

    @resolve: ( specifier ) ->
      ( @make specifier )
        .resolve()

    logic: ->

      requests = []
      valid = false
      resolved = false

      yield name: "start"

      yield from EventReactor

        .make @internal

        .bind @

        .when "resolve", ( event ) ->
          resolved = true
          @outgoing.source @listen()
          @_get()

        .when "valid", ( event ) ->
          if !valid
            valid = true
            ( await action() ) for action in requests
            requests = []

        .when "get", ->
          @_get() if resolved

        .when "put", ( event ) ->
          action = =>
            @value = await event.mutator @value
            @_put()
          if valid then await action() else requests.push action

        .when "delete", ->
          action = =>
            @_clear()
            @_delete()
          if valid then await action() else requests.push action

      await return

export default resolveable
