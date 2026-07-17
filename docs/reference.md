# Reference

This document provides the API reference for Addison's core classes. It details the methods and properties necessary to interact with both single and aggregate reactive resources within the Chicago System.

## Locators

A locator is an object containing protocol and path definitions (e.g., `template: "local:/foo"`) that tells the Belmont resource manager how to find and connect to a resource. Addison models are built around locators rather than direct HTTP clients, completely decoupling the Model layer from the underlying network protocols.

## Sky API

While Addison uses abstract locators and Belmont providers, it is heavily optimized for use with Sky API resolvers. The Sky API organizes HTTP resources using URL Codex templates to form logical resource spaces. Developers can pass Sky API locators into Addison's `@make` and specify dynamic values through a **specifier** object during resolution, unlocking immense flexibility and constraint-based hypermedia support.

## Core Callbacks

Before exploring the individual classes, it is helpful to understand the common callback structures frequently passed into Addison models:

- **mutator**: An asynchronous function passed to the `put` method. It receives the current data state and returns the new desired state, ensuring transactions are based on the latest internal engine narrative.
- **builder**: An asynchronous function passed to the `post` method. It receives the current data state and returns a payload to be appended or processed by the resource provider.

## Value

The `Value` class serves as the foundational envelope for resource data. By providing explicit snapshot isolation through defensive copying, it ensures that your application logic cannot accidentally mutate the internal cache of the Addison engine.

### @from:

$@from: raw\_data \to value\_instance$

Takes raw, serializable data originating from a resource provider and returns a freshly minted `Value` instance. This creates a defensive boundary around the data.

```coffeescript
import Value from "@dashkite/addison/value"

snapshot = Value.from { status: "active" }
assert.equal snapshot.data.status, "active"
```

### data

$data \to serializable\_object$

Retrieves the underlying data payload associated with this value. Since Addison guarantees snapshot isolation, manipulating this object will not corrupt the Model Engine's source of truth.

```coffeescript
import Value from "@dashkite/addison/value"

snapshot = Value.from { status: "active" }
assert.equal snapshot.data.status, "active"
```

## Atomic

The `Atomic` model wraps a single resource locator. It decorates an underlying `Composite` model, providing a streamlined, single-value interface while preserving the robust command gating and event serialization provided by the Engine.

### @make:

$@make: locator \to atomic\_model$

Instantiates a new `Atomic` model configured with the provided resource locator. This operation is synchronous and does not initiate any remote connections.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

Greeting = Atomic.make template: "local:/greeting"
assert.ok Greeting.resolve?
```

### @resolve:

$@resolve: specifier \dashrightarrow promise\_of\_atomic\_model$

A convenience factory that immediately creates and resolves an `Atomic` model using the provided specifier. This is ideal when you don't need to hold onto the uninitialized class constructor.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

greeting = await Atomic.resolve { id: "123" }
assert.ok greeting.put?
```

### value

$value \to snapshot\_data$

Retrieves the current isolated snapshot of the atomic resource's state. If the model is not yet initialized, this property returns `undefined`.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

greeting = await Atomic.resolve { id: "123" }
assert.ok greeting.value?
```

### resolve:

$resolve: specifier \dashrightarrow promise\_of\_atomic\_model$

Initiates the connection to the underlying resource utilizing the provided specifier for binding context. This method returns a promise that resolves when the Belmont connection is successfully established, enabling subsequent commands. Repeated calls return the original promise.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

class Greeting extends Atomic
  @make: -> super template: "mock:/greeting"

model = Greeting.make()
resolved = await model.resolve {}
assert.equal resolved, model
```

### get:

$get: \to \emptyset$

Dispatches a fetch request to the underlying resource to retrieve its latest state. The model linearly queues this command, ensuring it waits for initialization before executing.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

greeting = await Atomic.resolve {}
await greeting.get()
assert.ok greeting.value?
```

### put:

$put: mutator \dashrightarrow \emptyset$

Safely updates the atomic resource's state. The provided mutator function receives the current unwrapped data and must return the new data state. This ensures transactions are based on the latest narrative maintained by the Model Engine.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

counter = await Atomic.resolve {}
await counter.put ( data ) -> data.count += 1
assert.ok counter.value.count > 0
```

### delete:

$delete: \to \emptyset$

Dispatches a command to destroy the underlying resource. Once acknowledged by the provider, the model will transition its internal state to `undefined`.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

temporary = await Atomic.resolve {}
await temporary.delete()
assert.equal temporary.value, undefined
```

### post:

$post: builder \dashrightarrow \emptyset$

Constructs and dispatches a new payload to the resource. The `builder` function is provided the current unwrapped data, allowing the payload to depend on the existing state.

```coffeescript
import Atomic from "@dashkite/addison/models/atomic"

collection = await Atomic.resolve {}
await collection.post ( data ) -> { item: "new" }
```

## Composite

The `Composite` model aggregates multiple resource locators into a unified state map. It tracks the lifecycle of all constituent resources simultaneously, emitting high-level events only when the entire aggregate state shifts.

### @make:

$@make: locator\_map \to composite\_model$

Instantiates a new `Composite` model configured with a map of named resource locators. This synchronously establishes the model structure without executing remote requests.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

Dashboard = Composite.make 
  profile: template: "mock:/profile"
  settings: template: "mock:/settings"

assert.ok Dashboard.resolve?
```

### @resolve:

$@resolve: specifier \dashrightarrow promise\_of\_composite\_model$

A streamlined factory that instantiates and instantly resolves a `Composite` model against the provided specifier, returning a promise of the ready-to-use model.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

dashboard = await Composite.resolve { userId: "123" }
assert.ok dashboard.put?
```

### value

$value \to snapshot\_map$

Retrieves a map containing isolated snapshots of every constituent resource's current state. The map keys correspond to the names defined in the locator map during initialization.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

dashboard = await Composite.resolve {}
assert.ok dashboard.value.profile?
assert.ok dashboard.value.settings?
```

### resolve:

$resolve: specifier \dashrightarrow promise\_of\_composite\_model$

Initiates connections to all underlying resources defined in the locator map. It distributes the specifier bindings to each locator. This returns a promise that resolves once all Belmont resource connections are fully established.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

class Dashboard extends Composite
  @make: -> super profile: template: "mock:/profile"

model = Dashboard.make()
resolved = await model.resolve {}
assert.equal resolved, model
```

### get:

$get: keys \to \emptyset$

Dispatches fetch requests. If `keys` is provided as an array of strings, it only fetches those specific sub-resources; otherwise, it fetches all associated resources to refresh the aggregate state.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

dashboard = await Composite.resolve {}
# refresh only the profile resource
await dashboard.get [ "profile" ]
```

### put:

$put: mutator \dashrightarrow \emptyset$

Updates the aggregate resource state. The mutator function receives the full aggregate value map and must return an updated map. The model engine calculates the differences and safely delegates the specific resource updates to Belmont.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

dashboard = await Composite.resolve {}
await dashboard.put ( map ) ->
  map.settings.theme = "dark"
  map
assert.equal dashboard.value.settings.theme, "dark"
```

### delete:

$delete: keys \to \emptyset$

Issues a deletion command. If `keys` is provided as an array of strings, it selectively deletes the targeted sub-resources. If no keys are provided, it destroys all resources within the composite structure.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

dashboard = await Composite.resolve {}
# delete only the profile resource
await dashboard.delete [ "profile" ]
assert.equal dashboard.value.profile, undefined
```

### post:

$post: builder \dashrightarrow \emptyset$

Constructs and distributes payloads across the aggregate state. The `builder` function receives the aggregate value map and returns a map of data targeted at specific sub-resources to execute the corresponding posts.

```coffeescript
import Composite from "@dashkite/addison/models/composite"

dashboard = await Composite.resolve {}
await dashboard.post ( map ) ->
  profile: { status: "updated" }
```
