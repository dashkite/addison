# Addison

Addison provides the foundational abstractions for reactive models in the Chicago System, enabling protocol-agnostic data interaction within the RMVC+R architecture.

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

# Background

Addison's primary purpose is to provide a unified, protocol-agnostic interface for interacting with reactive data. In the Chicago System's RMVC+R (Reactive Model-View-Controller + Resources) architecture, Addison serves as the "Model" layer. It abstracts away the complexities of the underlying resource protocols (handled by Belmont) and provides application logic with a consistent way to observe and mutate state.

By wrapping resources in **Atomic** (single-resource) or **Composite** (aggregate-resource) models, Addison allows developers to focus on domain logic rather than the mechanics of resource resolution, synchronization, and state management. Its built-in command queuing and centralized lifecycle management ensure that data remains consistent and predictable, even when dealing with high-latency or complex multi-resource dependencies.

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
- [Design](docs/design.md)

# Status

Not suitable for production use. Please report any issues on the [GitHub repository](https://github.com/dashkite/addison).
