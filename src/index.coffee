import * as Obj from "@dashkite/joy/object"
import Belmont from "@dashkite/belmont"
import Channel from "@dashkite/reactive/channel"

class Addison

  @make: ( locators ) -> Object.assign new @, { locators }

  constructor: ->
    @resources = {}
    @channels = {}
    @value = {}

  # TODO deactivate / cancel first?
  #      or require a new instance?
  resolve: ( specifier ) ->
    for name, locator of @locators
      @resources[ name ] = await Belmont.resolve { locator..., specifier... }

  listen: ->
    for name, resource of @resources
      do ( name, resource ) =>
        @channels[ name ] = resource.subscribe()
        for await event from @channels[ name ]
          if event.name == "value"
            @value[ name ] = event.value
            yield { event..., @value }
          else
            yield event
  
  [ Symbol.asyncIterator ]: -> @listen()

  close: ->
    channel.close() for name, channel of @channels

  put: ( mutator ) ->
    await mutator.apply @, [ @value ]
    ( @resource[ key ].put value ) for key, value of @value
    return

export default Addison
