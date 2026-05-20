import { sleep } from "@dashkite/joy/time"

wait = ( model, predicate ) ->

  Promise.race [

    do ->
      for await event from model
        if predicate event
          return event

    do ->
      await sleep 1000
      throw new Error "Timeout waiting for event"

  ]

export { wait }
