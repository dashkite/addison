# Recipes

This document provides task-based scenarios for interacting with Addison models. It demonstrates how to leverage both Atomic and Composite patterns, moving from common data access strategies to more nuanced state management.

## Atomic Models

Atomic models provide a focused viewport into a single reactive resource. They are the ideal abstraction when a developer needs to synchronize a single component with a remote entity.

### How to read a basic atomic resource?

A developer needs to fetch a single entity and display its contents.

Addison enables this by pairing an `Atomic` subclass with a Belmont locator. By calling `resolve`, the model initiates the connection and automatically retrieves the initial state, which becomes accessible via the `value` property.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

class Greeting extends Atomic
  @make: -> super template: "mock:/greeting"

# implementation of component lifecycle setup goes here
model = await Greeting.resolve()
console.log model.value
```

**Algorithm:**
1. Define a class extending `Atomic`.
2. Override the `@make` factory to provide the target locator template.
3. Call `resolve` on the class to instantiate and connect the model.
4. Access the retrieved snapshot via the `value` property.

### How to mutate an atomic resource?

A developer needs to update the state of a resource based on an interactive event.

Addison enables this through the `put` method. Instead of imperatively sending data, the developer passes a mutator function. The model engine provides the mutator with the most current isolated snapshot, guaranteeing that modifications are safely sequenced.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

class Counter extends Atomic
  @make: -> super template: "mock:/counter"

counter = await Counter.resolve()

# implementation of click event handler goes here
await counter.put ( data ) -> 
  data.count += 1
  data
```

**Algorithm:**
1. Resolve the `Atomic` model.
2. Call the `put` method.
3. Provide an asynchronous mutator function.
4. Modify and return the state provided to the mutator.

### How to dynamically post to an atomic resource?

A developer needs to append new records or trigger an action on a collection resource.

Addison handles this with the `post` method. By providing a builder function, developers can conditionally construct the outgoing payload using the resource's current state. 

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

class Guestbook extends Atomic
  @make: -> super template: "mock:/guestbook"

book = await Guestbook.resolve()

# implementation of form submission handler goes here
await book.post ( state ) ->
  signature: "Ada Lovelace"
  timestamp: Date.now()
```

**Algorithm:**
1. Resolve the `Atomic` model.
2. Call the `post` method.
3. Provide an asynchronous builder function.
4. Return the new payload object from the builder.

### How to gracefully handle missing resources?

A developer needs to ensure the application maintains a high-quality human experience (HX) when a remote resource returns a "Not Found" error.

Addison allows creators to declare a `fallback` property directly on the model definition. If the underlying Belmont provider yields a 404 response, the engine automatically substitutes the fallback value, maintaining application stability.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

class Configuration extends Atomic
  @make: -> super template: "mock:/config"
  fallback: { theme: "light" }

config = await Configuration.resolve()
```

**Algorithm:**
1. Define a class extending `Atomic`.
2. Declare a `fallback` property with a default object.
3. Resolve the model; it will substitute the fallback if the remote resource is missing.

### How to delete an atomic resource?

A developer needs to remove a resource entirely.

Addison provides a straight-forward `delete` method. Once invoked, the model communicates the deletion to Belmont and subsequently clears its internal cache, rendering the `value` as `undefined`.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

class Session extends Atomic
  @make: -> super template: "mock:/session"

session = await Session.resolve()

# implementation of logout sequence goes here
await session.delete()
```

**Algorithm:**
1. Resolve the `Atomic` model.
2. Call the `delete` method.
3. Await the operation to ensure the local state transitions to `undefined`.

## Composite Models

Composite models aggregate multiple locators into a unified, synchronized state map. They are highly effective for complex application views that rely on disparate data sources.

### How to read a basic composite resource?

A developer needs to gather data from multiple distinct endpoints before rendering a dashboard.

Addison solves this by allowing creators to define a map of locators in the `Composite` model. Calling `resolve` establishes connections to all defined resources simultaneously, and the model only initializes once all initial payloads arrive.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

class Dashboard extends Composite
  @make: ->
    super
      profile: template: "mock:/profile"
      settings: template: "mock:/settings"

# implementation of route resolution goes here
dashboard = await Dashboard.resolve()
console.log dashboard.value.profile
console.log dashboard.value.settings
```

**Algorithm:**
1. Define a class extending `Composite`.
2. Override the `@make` factory, passing a map of named locators.
3. Call `resolve` to connect all underlying resources.
4. Access the synchronized aggregate map via the `value` property.

### How to update specific fields in a composite resource?

A developer needs to update a single setting within a broader dashboard state.

Addison routes the aggregate state map into the `put` mutator. Developers modify the specific keys they care about, and the Model Engine automatically calculates the differences, dispatching individual update commands only to the modified resources.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

class Dashboard extends Composite
  @make: ->
    super
      profile: template: "mock:/profile"
      settings: template: "mock:/settings"

dashboard = await Dashboard.resolve()

# implementation of settings toggle goes here
await dashboard.put ( map ) ->
  map.settings.theme = "dark"
  map
```

**Algorithm:**
1. Resolve the `Composite` model.
2. Call the `put` method with a mutator.
3. Modify specific sub-resource states within the provided aggregate map.
4. Return the entire updated map.

### How to conditionally refresh specific resources?

A developer needs to refresh a frequently changing resource without polling the static resources in the same composite model.

Addison's `get` method optionally accepts an array of resource keys. When provided, the engine will only dispatch fetch requests to those specific providers, minimizing network traffic.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

class Dashboard extends Composite
  @make: ->
    super
      profile: template: "mock:/profile"
      activity: template: "mock:/activity"

dashboard = await Dashboard.resolve()

# implementation of polling interval goes here
await dashboard.get [ "activity" ]
```

**Algorithm:**
1. Resolve the `Composite` model.
2. Call the `get` method, passing an array of string keys.
3. The model engine refreshes only the targeted resources.

### How to broadcast creations across a composite state?

A developer needs to dispatch multiple disparate payloads across the aggregate structure in a single action.

Addison provides the `post` builder function for composite models, which returns a map of payloads keyed to specific sub-resources. The engine iterates over this map and issues the corresponding HTTP POST actions via Belmont.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

class Dashboard extends Composite
  @make: ->
    super
      logs: template: "mock:/logs"
      metrics: template: "mock:/metrics"

dashboard = await Dashboard.resolve()

# implementation of bulk reporting trigger goes here
await dashboard.post ( map ) ->
  logs: { event: "startup" }
  metrics: { load_time: 120 }
```

**Algorithm:**
1. Resolve the `Composite` model.
2. Call the `post` method with a builder.
3. Return a map where the keys match the composite locators and the values are the intended payloads.

### How to partially destroy a composite state?

A developer needs to clear specific pieces of data from the aggregate view without tearing down the entire model.

Addison's `delete` method accepts an optional array of keys. The engine will dispatch delete commands only to those providers, turning those specific keys in the aggregate state map to `undefined`.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

class Dashboard extends Composite
  @make: ->
    super
      profile: template: "mock:/profile"
      cache: template: "mock:/cache"

dashboard = await Dashboard.resolve()

# implementation of cache clearing action goes here
await dashboard.delete [ "cache" ]
```

**Algorithm:**
1. Resolve the `Composite` model.
2. Call the `delete` method, passing an array of string keys.
3. The engine zeroes out those targeted resources locally and remotely.
