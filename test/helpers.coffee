import { sleep } from "@dashkite/joy/time"

wait = ( events, predicate, timeout = 1000 ) ->
  Promise.race [
    do ->
      if events.receive?
        loop
          event = await events.receive()
          return event if predicate event
      else
        loop
          { done, value } = await events.next()
          break if done == true
          return value if predicate value
    do ->
      await sleep timeout
      throw new Error "Timeout waiting for event"
  ]

export { wait }
