import { Queue } from "@dashkite/joy/iterable"
# TODO this might belong in Reactive
class Channel

  @make: ->
    Object.assign ( new @ ),
      closed: false
      queue: Queue.make()
      
  send: ( message ) ->
    if @closed
      throw new Error "send: channel closed"
    else
      @queue.enqueue message

  receive: -> 
    if @closed
      throw new Error "receive: channel closed"
    else
      @queue.dequeue()

  close: -> @closed = true
      
  apply: ->
    # TODO what if there are messages still in the queue?
    yield await @receive() until @closed
    undefined # don't return comprehension
            
  [ Symbol.asyncIterator ]: -> @apply()


export default Channel