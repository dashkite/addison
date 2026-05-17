# Addison

Addison provides the foundational abstractions for reactive models in the Chicago System, enabling protocol-agnostic data interaction within the RMVC+R architecture.

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

# Background

Addison is a core module within the Chicago System that provides the foundational abstractions for reactive models. It primarily implements two types of models: **Atomic** and **Composite**, which serve as the "M" in the RMVC+R architecture. These models are designed to be protocol-agnostic, wrapping reactive resources (managed by Belmont) and providing a uniform interface for application logic to interact with data.

At its core, Addison leverages a mixin-based architecture to handle resource lifecycle and reactivity. The `Atomic` model manages a single resource, while the `Composite` model aggregates multiple sub-resources into a unified state, re-emitting sub-resource events with a `source` identifier. Both model types utilize the `resolveable` mixin, which ensures that mutations are queued until the model reaches a "valid" state—defined as having received its first protocol event (e.g., `value` or `not-found`). This guarantees sequential execution and state consistency regardless of the underlying storage latency.

Functionally, Addison models are themselves reactive event streams (async iterators), allowing them to be consumed directly in `for await...from` loops or via `EventReactor`. They translate raw resource events into high-level model events, handling complexities such as fallback values and "not found" semantics. By abstracting the details of resource resolution and state synchronization, Addison enables developers to build complex, data-driven components that remain decoupled from specific storage implementations.

# Installation

Use your favorite package manager:

```bash
npm install @dashkite/addison
```

# Usage

### Atomic Models

Atomic models represent a single resource.

```coffeescript
import Model from "@dashkite/addison/models/atomic"

class Greeting extends Model
  @make: -> super template: "local:/components/greeting"
  fallback: "hello!"

# usage
greeting = await Greeting.resolve()
greeting.put ( data ) -> "hola!"
```

### Composite Models

Composite models aggregate multiple resources into a single state.

```coffeescript
import Model from "@dashkite/addison/models/composite"

class PersonalizedGreeting extends Model
  @make: ->
    super
      greeting: template: "local:/components/greeting/{name}"
      profile: template: "local:/profile"

# usage
greeting = await PersonalizedGreeting.resolve greeting: name: "Dan"
```

# Other Resources

- [Reference](docs/reference.md)

# Status

Not suitable for production use. Please report any issues on the [GitHub repository](https://github.com/dashkite/addison).
