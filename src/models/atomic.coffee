import { metaclass } from "@dashkite/joy/metaclass"
import * as Obj from "@dashkite/joy/object"
import * as Val from "@dashkite/joy/value"
import * as Time from "@dashkite/joy/time"
import { Queue } from "@dashkite/joy/iterable"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"

class Atomic extends metaclass()

  @make: ( locator ) -> Object.assign new @, { locator }

  @getters
    valid: -> Object.hasOwn @, "value"

  constructor: ->
    super()
    @resource = {}
    @machine = Channel.make()
    @run()

  run: ->
    for await state from @logic()
      undefined
    return

  logic: ->

    puts = []
    valid = false
    listen = false
    resolved = false

    yield name: "start"

    for await event from @machine
      switch event.name
        when "resolve"
          resolved = true
          yield event
          if listen then @_listen()
          @_get()
        when "valid"
          if !valid
            valid = true
            yield event
            if puts.length > 0
              value = @value
              for mutator in puts
                value = await mutator value
              @value = value
              puts = []
              @_put()
        when "listen"
          if resolved
            @_listen()
            yield event
          else
            listen = true
        when "get"
          @_get() if resolved
        when "put"
          if valid
            @value = await event.mutator @value
            @_put()
          else
            puts.push event.mutator
    return

  resolve: ( specifier ) ->
    @resource = await Belmont.resolve { @locator..., specifier... }
    @incoming = @resource.subscribe()
    @machine.send name: "resolve"

  listen: ->
    if @outgoing?
      throw new Error "addison: already listening"
    else
      @outgoing = Channel.make()
      @machine.send name: "listen"
      @outgoing

  [ Symbol.asyncIterator ]: -> @listen()

  close: ->
    @incoming.close()
    delete @incoming

  get: -> @machine.send name: "get"

  put: ( mutator ) -> @machine.send { name: "put", mutator }

  # "private" methods

  _listen: ->
    for await event from @incoming
      switch event.name
        when "value", "created"
          @value = event.value
          @outgoing.send { event..., scope: "model" }
        when "delete"
          delete @value
          @outgoing.send { event..., scope: "model" }
        when "not-found"
          if ( fallback = @fallback )?
            @value = fallback
            @resource.put fallback
          else
            @value = undefined
            @outgoing.send { event..., scope: "model" }
        when "method-not-allowed"
          if event.method == "get"
            # you can't get this resource
            # so treat it as valid (but undefined)
            @value = undefined
          else
            @outgoing.send { event..., scope: "model" }
        else
          @outgoing.send { event..., scope: "model" }
      ( @machine.send name: "valid" ) if @valid
    return

  _get: -> @resource.get()

  _put: -> @resource.put @value

export { Atomic }
export default Atomic
