# Technical Notes

### RMVC+R and Reactive Resources Goals

Addison sits at the core of the RMVC+R (Reactive Model-View-Controller + Resources) architecture within the DashKite ecosystem. The RMVC+R architecture treats an entire application as a set of interacting event streams and logical resources. By abstracting data access into reactive event streams, developers can decouple application logic from underlying transport protocols. 

Within this architecture, Addison serves as the Model layer, encapsulating domain logic and providing serializable, predictable data interfaces for Controllers and Views to consume. The underlying resources operate as reactors modeled on RESTful principles, where mutations (like `put` or `post`) produce events rather than direct imperative responses. This ensures that the application remains cleanly synchronized through purely reactive subscriptions.

### Locators and Belmont Providers

Addison models do not directly execute network or persistence operations. Instead, they rely on locators to abstract routing constraints. These locators are processed by Belmont, DashKite's core reactive resource manager. Because Belmont dynamically maps abstract resource locators to concrete providers based on protocol schemes, Addison's architecture remains completely decoupled from any specific underlying protocol or API implementation.

### Sky API and Logical Resource Spaces

While Addison is technically decoupled from any specific API structure, in practice, DashKite ecosystems commonly pair Addison models with Sky API resolvers. The Sky API explicitly models an application's interface as constraint-based hypermedia, using URL Codex templates to group HTTP resources under related names. By passing Sky API locators into Addison models, developers can effortlessly reason about and interact with entire logical resource spaces, leveraging the flexibility and metaprogramming capabilities of the Sky API JSON schemas without leaking transport complexity into the Model layer.

### Architecture and Linearization

Addison models manage their behavior through a single logic reactor (`_logic`) that linearizes observations and commands. This reactor delegates state and queue management to a dedicated Model Engine. The Engine processes all inputs from the internal channel (`@internal`), ensuring deterministic state transitions and eliminating race conditions.

### Command Gating and Execution

The Model Engine manages the command queue and gating based on the model's lifecycle. Commands issued after resolution but before initialization are queued. Once initialized, the Engine drains this queue, ensuring strict FIFO execution. The outgoing channel (`@outgoing`) yields high-level aggregate value events and forwards individual resource events.

### Resource Aggregation Design

Addison uses a tiered strategy for model specialization. The `Composite` model acts as the foundational aggregate, coordinating multiple resources. The aggregate state is a map of sub-resource values. In contrast, the `Atomic` model is a specialized view for a single resource. It delegates all core logic to an internal `Composite` instance using a fixed key (`$`), decorating it to provide a simplified single-value interface.

### Explicit Lifecycle Phases

Models follow a specific lifecycle: `unresolved` (commands are immediately rejected), `resolving` (connections are being established, commands are queued), `resolved` (connections established, awaiting data, commands queued), and finally `initialized` (data received for all locators, queued requests drained).

### Error Handling and Snapshot Isolation

Addison treats models as Reactive Viewports where the engine acts as a reliable narrator for the state. Definitive resource failures automatically clear the resource's state. Snapshot Isolation is enforced to prevent accidental mutation; read operations return an Isolated Snapshot through Defensive Copying. Resource value types must provide a static `@from` method and cloneable data.
