iterable = ( base ) ->
  class extends base
    [ Symbol.asyncIterator ]: -> @

    next: ->
      value = await @outgoing.receive()
      { done: false, value }

export default iterable