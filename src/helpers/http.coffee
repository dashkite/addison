HTTP =

  put: ( resource, value ) ->
    for await event from resource.put value
      # switch event.name
      #   when "failure" then @message event
      undefined
    undefined

export default HTTP