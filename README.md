# Addison

*Foundational abstractions for reactive models*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

Addison provides the foundational abstractions for reactive models in the Chicago System. It enables protocol-agnostic data interaction within the RMVC+R architecture, acting as the Model layer. By abstracting resource protocols and providing a consistent way to observe and mutate state, it allows developers to focus on domain logic over mechanics.

## Features

- Unifies protocol-agnostic interface for reactive data interaction.
- Provides robust command queuing and sequential request processing.
- Offers both atomic (single) and composite (aggregate) resource models.
- Integrates centralized lifecycle and gating management.
- Handles explicit fallback mechanisms and resilient error propagation.

## Installation

```bash
pnpm install @dashkite/addison
```

## Usage

This example illustrates how to define and use an atomic model for a greeting resource.

```coffeescript
import Model from "@dashkite/addison/models/atomic"

class Greeting extends Model
  @make: -> super template: "local:/components/greeting"
  fallback: "hello!"

greeting = await Greeting.resolve()
await greeting.put ( data ) -> "hola!"
```

## Other Resources

- [Reference](docs/reference.md)
- [Recipes](docs/recipes.md)
- [Technical Notes](docs/technical-notes.md)
- [Testing](docs/testing.md)
