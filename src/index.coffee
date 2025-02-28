import * as Obj from "@dashkite/joy/object"
import Montrose from "@dashkite/montrose"
import Channel from "@dashkite/reactive/channel"

class Addison

  @make: ( locators ) ->
    self = new @
    self.locators = locators
    self.resources = {}
    self.value = {}
    self.channel = Channel.make()
    self

  # TODO deactivate / cancel first?
  #      or require a new instance?
  resolve: ( specifier ) ->
    for name, locator of @locators
      @resources[ name ] = await Montrose.resolve { locator..., specifier... }

  observe: ->

    @get Object.keys @resources
        
    for name, resource of @resources
      do ( name, resource ) =>
        for await event from resource.observe()
          switch event.name
            when "update" then @value[ name ] = event.value
          @channel.send if event.value?
            { event..., value: @value }
          else
            event

    @channel
  
  cancel: ->
    for name, resource of @resources
      resource.cancel()
    @channel.close()
    delete @channel

  get: ( names ) ->
    for name, resource of ( Obj.mask names, @resources )
      do ( name, resource ) =>
        for await event from resource.get()
          switch event.name
            when "value"
              @value[ name ] = event.value
              @channel.send
                name: "update"
                value: @value
            when "failure"
              @channel.send event
    undefined

  put: ( names, mutator ) ->
    updates = await mutator.apply @, [ Obj.mask names, @value ]
    for key, value of updates
      for await event from ( @resources[ key ].put value )
        continue
    undefined



export default Addison