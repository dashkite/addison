import * as Obj from "@dashkite/joy/object"
import * as Val from "@dashkite/joy/value"
import * as Time from "@dashkite/joy/time"
import { Queue } from "@dashkite/joy/iterable"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"
import { getters } from "./helpers/meta"

class Addison

  @make: ( locators ) -> Object.assign new @, { locators }

  constructor: ->
    @resources = {}
    @channels = {}
    @value ?= {}

  getters @::,
    starting: ->
      for key of @resources
        if ( Object.hasOwn @value, key )
          return false
      true
    running: -> !@starting
    waiting: -> !@listening
    listening: -> @channel?

  # TODO deactivate / cancel first?
  #      or require a new instance?
  resolve: ( specifier ) ->
    for name, locator of @locators
      @resources[ name ] = await Belmont.resolve { locator..., specifier... }
      @channels[ name ] = @resources[ name ].subscribe()
    @get()

  when: ( state, f ) ->
    if await Time.expect => @[ state ]
      f.call @
    else 
      throw new Error "addison: never reached [ #{ state } ]"

  listen: ->
    @when "waiting", =>
      # TODO make idempotent or throw already listening?
      @channel = Channel.make()
      for scope, resource of @resources
        do ( scope, resource ) =>
          for await event from @channels[ scope ]
            switch event.name
              when "value"
                @value[ scope ] = event.value
                @channel.send { event..., @value, scope }
              when "not found"
                if !( Object.hasOwn @value, scope )
                  @value[ scope ] = @defaults?[ scope ]
                  @resources[ scope ].put @defaults?[ scope ]
              else
                @channel.send { event..., scope }
          return
      @channel
  
  [ Symbol.asyncIterator ]: -> @listen()

  close: ->
    channel.close() for name, channel of @channels
    @channels = {}

  get: ->
    ( resource.get()) for name, resource of @resources
    return

  put: ( mutator ) ->
    @when "running", =>
      await mutator.call @, @value
      ( @resources[ key ].put value ) for key, value of @value
      return

export default Addison
