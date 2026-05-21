import Belmont from "@dashkite/belmont"
import Value from "#value"

filter = ( name, incoming ) ->
  for await event from incoming
    yield { event..., source: name }

class Engine

  constructor: ( @model ) ->
    @initialized = false
    @resolved = false
    @requests = []

  has: ( key ) => Object.hasOwn @model._value, key

  set: ( key, value ) ->

    @model._value[ key ] = 
      if value?
        T = @model.types[ key ] ? Value
        T.from value

    if !@initialized

      @initialized = 
        Object
          .keys @model.locators
          .every @has

      if @initialized
        @model._send "drain"

    @model._value[ key ]

  run: ({ resolve, reject, action }) ->
    try
      resolve await action.call @model
    catch error
      reject error

  request: ({ action, resolve, reject }) ->
    if @resolved
      if @initialized && ( @requests.length == 0 )
        await @run { action, resolve, reject }
      else 
        @requests.push { action, resolve, reject }
    else 
      reject new Error "addison: 
        attempt to invoke a resource method
        but the model is unresolved
        (resolve was never called)"

  resolve: ({ specifier, resolve, reject }) ->
    
    if @resolved
      return resolve @model

    try

      if ( !@model.locators? ) || ( Object.keys( @model.locators ).length == 0 )
        throw new Error "addison: 
          attempt to resolve a model with 
          missing or empty locators"

      promised =
        for name, { type, locator... } of @model.locators
          @model.types[ name ] = type ? Value
          { bindings, rest... } = locator        
          do ( name ) =>
            resource = @model.resources[ name ] = 
              await Belmont.resolve {
                rest...
                bindings: { specifier?[ name ]... , bindings... }
              }
            @model.internal.source ( filter name, resource.subscribe())
            resource
      await Promise.all promised
      @resolved = true
      @model._get()
      resolve @model

    catch error
      reject error

  drain: ->
    while @requests.length > 0
      await @run @requests.shift()

export default Engine
