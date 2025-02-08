import * as Obj from "@dashkite/joy/object"
import Observer from "@dashkite/belmont/observer"
import Montrose from "@dashkite/montrose"

class Addison

  @resolve: ( locators ) ->
    self = new @
    self.locators = locators
    self.resources = {}
    self.value = {}

    for name, locator of locators
      self.resources[ name ] = await Montrose.resolve locator

    self

  observe: ->

    # TODO should we initialize values in a separate method
    #      ... or should that be in resolve

    # we have to set up our local state before setting up
    # the observers because otherwise a non-local update
    # could trigger our observer before our local state
    # is fully initialized...

    @observer = Observer.make()

    self = @

    do ->

      for name, resource of self.resources
        self.value[ name ] = Obj.get "value",
          await resource
            .get()
            .resolve "value"

      for name, resource of self.resources
        do ( name, resource ) ->
          resource
            .observe()
            .each ( event ) ->
              self.observer.dispatch if event.value?
                { event..., value: self.value }
              else
                event
            .when "update", ({ value: update }) ->
              # TODO save previous state
              # TODO allow component processing
              self.value[ name ] = update
            .run()

      self.observer.dispatch name: "update", value: self.value

    @observer
  
  cancel: ->
    for name, resource of @resources
      resource.cancel()

  transition: ( names, transition ) ->
    patch = await transition.apply @, [ Obj.mask names, @value ]
    resources = @resources
    Promise.all do ->
      for key, value of patch
        do ( resource = resources[ key ]) ->
          resource
            .put value 
            .resolve "success"  

export default Addison