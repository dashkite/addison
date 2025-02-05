import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"

import * as Time from "@dashkite/joy/time"

import Providers from "@dashkite/belmont/providers"
import Halstead from "@dashkite/halstead"
Providers.add "local", Halstead

# test component
import Greeting from "./greeting"

do ->

  print await test "Addison", [

    test "Basic Component", ->

      greeting = await Greeting.make()

      await greeting[ "set greeting" ] "hello!"
      await greeting[ "set profile" ] email: "bob@acme.org"

      # wait for events to finish
      await Time.sleep 100

      await greeting.observe()

      await greeting[ "set greeting" ] "hola!"

      # wait for events to finish
      await Time.sleep 100

      console.log greeting.values

  ]

  process.exit if success then 0 else 1
