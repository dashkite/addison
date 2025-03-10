import * as Obj from "@dashkite/joy/object"
import * as Val from "@dashkite/joy/value"
import * as Time from "@dashkite/joy/time"
import { Queue } from "@dashkite/joy/iterable"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"

class Addison

  @make: ( locators ) -> Object.assign new @, { locators }

  constructor: ->
    @resources = {}
    @channels = {}
    @value ?= {}

  isValid: ->
    for key of @resources
      if !( Object.hasOwn @value, key )
        return false
    true

  # TODO deactivate / cancel first?
  #      or require a new instance?
  resolve: ( specifier ) ->
    for name, locator of @locators
      @resources[ name ] = await Belmont.resolve { locator..., specifier... }
      @channels[ name ] = @resources[ name ].subscribe()
    @get()

  listen: ->
    throw new Error "addison: already listening" if @channel?
    # TODO make idempotent or throw already listening?
    @channel = Channel.make()
    for scope, resource of @resources
      do ( scope, resource ) =>
        for await request from @channels[ scope ]
          for await event from request.reactor
            switch event.name
              when "value"
                @value[ scope ] = event.value
                @channel.send { event..., @value, scope }
              when "failure"
                # TODO restrict to not found error?
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
    if await Time.expect => @isValid()
      await mutator.call @, @value
      ( @resources[ key ].put value ) for key, value of @value
      return
    else
      throw new Error "addison: unable to initialize value"

export default Addison
