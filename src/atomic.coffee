import * as Obj from "@dashkite/joy/object"
import * as Val from "@dashkite/joy/value"
import * as Time from "@dashkite/joy/time"
import { Queue } from "@dashkite/joy/iterable"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"
import { getters } from "./helpers/meta"

class Atomic

  @make: ( locator ) -> Object.assign new @, { locator }

  constructor: ->
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
              for mutator in puts
                @value = await mutator @value
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
            await event.mutator @value
            @_put()
          else
            puts.push event.mutator
    return

  getters @::,
    valid: -> Object.hasOwn @, "value"

  # TODO deactivate / cancel first?
  #      or require a new instance?
  resolve: ( specifier ) ->
    @resource = await Belmont.resolve { @locator..., specifier... }
    @incoming = @resource.subscribe()
    @machine.send name: "resolve"

  listen: ->
    throw new Error "addison: already listening" if @outgoing?
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
        when "not found"
          @value = @fallback
          @resource.put @fallback
        when "method not allowed"
          if event.method == "get"
            # you can't get this resource
            # so treat it as valid (but undefined)
            @value = undefined
        else
          @outgoing.send event
      ( @machine.send name: "valid" ) if @valid
    return

  _get: -> @resource.get()

  _put: -> @resource.put @value

export { Atomic }
