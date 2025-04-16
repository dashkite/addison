import * as Obj from "@dashkite/joy/object"
import * as It from "@dashkite/joy/iterable"
import * as Val from "@dashkite/joy/value"
import * as Time from "@dashkite/joy/time"
import { Queue } from "@dashkite/joy/iterable"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"
import { getters } from "./helpers/meta"

class Composite

  @make: ( locators ) -> Object.assign new @, { locators }

  constructor: ->
    @resources = {}
    @channels = {}
    @value ?= {}
    @machine = Channel.make()
    @run()

  run: -> It.start @logic()

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
    valid: ->
      for key of @resources
        if !( Object.hasOwn @value, key )
          return false
      true

  # TODO deactivate / cancel first?
  #      or require a new instance?
  resolve: ( specifier ) ->
    for name, locator of @locators
      @resources[ name ] = await Belmont.resolve { 
        locator...
        specifier?[ name ]... 
      }
      @channels[ name ] = @resources[ name ].subscribe()
    @machine.send name: "resolve"

  listen: ->
    throw new Error "addison: already listening" if @channel?
    @channel = Channel.make()
    @machine.send name: "listen"
    @channel
  
  [ Symbol.asyncIterator ]: -> @listen()

  close: ->
    channel.close() for name, channel of @channels
    @channels = {}

  get: -> @machine.send name: "get"

  put: ( mutator ) -> @machine.send { name: "put", mutator }

  # "private" methods

  _listen: ->
    for scope, resource of @resources
      do ( scope, resource ) =>
        for await event from @channels[ scope ]
          # console.log [ scope ]: event
          switch event.name
            when "value"
              @value[ scope ] = event.value
              @channel.send { event..., @value, scope }
            when "not found"
              @value[ scope ] = @fallbacks?[ scope ]
              @resources[ scope ].put @fallbacks?[ scope ]
            when "method not allowed"
              if event.method == "get"
                # you can't get this resource
                # so treat it as valid (but undefined)
                @value[ scope ] = undefined
            else
              @channel.send { event..., scope }
          ( @machine.send name: "valid" ) if @valid
        return
    return

  _get: ->
    ( resource.get()) for name, resource of @resources
    return

  _put: ->
    ( resource.put @value[ name ]) for name, resource of @resources
    return

export { Composite }
