import { metaclass } from "@dashkite/joy/metaclass"
import * as Obj from "@dashkite/joy/object"
import * as It from "@dashkite/joy/iterable"
import * as Val from "@dashkite/joy/value"
import * as Time from "@dashkite/joy/time"
import { Queue } from "@dashkite/joy/iterable"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"

class Composite extends metaclass()

  @make: ( locators ) ->
    instance = Object.assign new @, { locators }
    instance

  constructor: ->
    super()
    @resources = {}
    @channels = {}
    @value ?= {}
    @machine = Channel.make()
    @run()

  @getters
    valid: ->
      for key of @resources
        if !( Object.hasOwn @value, key )
          return false
      true

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
              value = @value
              for mutator in puts
                value = await mutator value
              puts = []
              @value = value
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
        when "remove"
          @_remove() if resolved
        when "value"
          if event.internalSource == "resource"
            { property } = event
            @value[ property ] = event.value
            @channel.send { event..., scope: "model", source: property }
            if @valid
              @channel.send name: "value", value: @value, scope: "model"
        when "created"
          if event.internalSource == "resource"
            { property } = event
            @value[ property ] = event.value
            @channel.send { event..., scope: "model", source: property }
            if @valid
              @channel.send name: "value", value: @value, scope: "model"
        when "delete"
          if event.internalSource == "resource"
            { property } = event
            @channel.send { event..., scope: "model", source: property }
            delete @value[ property ]
            if @valid
              @channel.send name: "value", value: @value, scope: "model"
        when "not-found"
          if event.internalSource == "resource"
            { property } = event
            if ( fallback = @fallbacks?[ property ] )?
              @value[ property ] = fallback
              @resources[ property ].put fallback
              @channel.send { name: "value", value: @value, scope: "model", property, event... }
            else
              @value[ property ] = undefined
              @channel.send { event..., scope: "model", source: property }
        when "method-not-allowed"
          if event.internalSource == "resource"
            { property } = event
            if event.method == "get"
              # you can't get this resource
              # so treat it as valid (but undefined)
              @value[ property ] = undefined
            else
              @channel.send { event..., scope: "model", source: property }
        else
          if event.internalSource == "resource"
            { property } = event
            @channel.send { event..., scope: "model", source: property }

      if !valid && @valid
        @machine.send name: "valid"

    return

  resolve: ( specifier ) ->
    for name, locator of @locators
      @resources[ name ] = await Belmont.resolve {
        locator...
        specifier?[ name ]...
      }
      @channels[ name ] = @resources[ name ].subscribe()
    @machine.send name: "resolve"

  listen: ->
    if @channel?
      throw new Error "addison: already listening"
    else
      @channel = Channel.make()
      @machine.send name: "listen"
      @channel

  [ Symbol.asyncIterator ]: -> @listen()

  close: ->
    channel.close() for name, channel of @channels
    @channels = {}

  get: ->
    @machine.send name: "get"
    return

  put: ( mutator ) ->
    @machine.send { name: "put", mutator }
    return

  remove: ->
    @machine.send name: "remove"
    return

  # "private" methods

  _listen: ->
    for property, resource of @resources
      do ( property, resource ) =>
        for await event from @channels[ property ]
          @machine.send {
            event...
            internalSource: "resource"
            property
            resource
          }
        return
    return

  _get: ->
    ( resource.get()) for name, resource of @resources
    return

  _put: ->
    ( resource.put @value[ name ]) for name, resource of @resources
    return

  _remove: ->
    ( resource.delete()) for name, resource of @resources
    return

export { Composite }
export default Composite
