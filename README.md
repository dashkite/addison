# Addison

*Base classes for the Chicago RMVC architecture.*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

Addison provides the foundational `Controller` and `Model` classes for building reactive applications using the Chicago RMVC (Reactive Model-View-Controller) architecture.

## Installation

Use your favorite package manager:

```bash
npm install @dashkite/addison
```

## Usage

Extend the `Controller` and `Atomic` (Model) classes to build your application logic.

```coffeescript
import { Controller } from "@dashkite/addison"
import { Atomic } from "@dashkite/addison/models/atomic"

class MyModel extends Atomic
  # ... model logic

class MyController extends Controller
  # ... controller logic
```

## Status

Not suitable for production use. Please report any issues on the [GitHub repository](https://github.com/dashkite/addison).
