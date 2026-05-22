# Design

Addison provides the foundational abstractions for reactive models in the Chicago System. It bridges protocol-specific resource events into high-level, domain-specific state transitions using a centralized logic reactor architecture.

## Architecture

Addison models manage their behavior through a single logic reactor (`_logic`) that linearizes observations and commands. This reactor delegates state and queue management to a dedicated **Model Engine**:

- **Logic Reactor (`_logic`)**: Processes all inputs from the internal channel (`@internal`), ensuring deterministic state transitions and eliminating race conditions.
- **Model Engine (`Engine`)**: Manages the model's lifecycle state (unresolved, resolving, resolved, initialized) and its command queue. It ensures that commands are executed sequentially and correctly gates them based on the model's readiness.
- **Request Serialization**: Commands issued after resolution but before initialization are queued by the Engine. Once initialized, the Engine drains this queue, ensuring strict FIFO execution.
- **Outgoing Channel (`@outgoing`)**: Yields high-level model events (aggregate `value` changes) and forwards individual resource events.

## Resource Aggregation and Delegation

Addison uses a tiered strategy for model specialization:

- **`Composite`**: The foundational aggregate model. It coordinates multiple resources via the Engine. The aggregate state is a map of sub-resource values. It emits an aggregate `value` event when initialized or when sub-resources update, providing a unified view of the system.
- **`Atomic`**: A specialized view of a single resource. It delegates all core logic to an internal `Composite` instance using a fixed internal key (`$`). `Atomic` acts as a decorator, providing a simplified single-value interface while inheriting the Engine's robust queuing and linearization.

## Lifecycle and Gating

Addison models follow an explicit lifecycle:

1.  **`unresolved`**: Initial state. Commands result in an immediate rejection.
2.  **`resolving`**: Entered on `resolve()`. Connections to resources are being established. Commands are queued.
3.  **`resolved`**: Connections are established; waiting for initial data. Commands are queued.
4.  **`initialized`**: First resource data has been received for all locators. Queued requests are drained; subsequent requests execute immediately.

## Error Handling and Resiliency

Addison treats models as **Reactive Viewports**. The engine acts as a "reliable narrator" for the resource's current state:

- **Unified Failures**: Definitive resource failures (unauthorized, forbidden, method-not-allowed, server errors) automatically clear the resource's state (`undefined`).
- **Fallbacks**: If a resource returns "Not Found," the model can automatically apply a predefined fallback value, allowing the aggregate state to remain usable even in the absence of remote data.
- **Rejection Propagation**: Mutation requests (`put`, `post`, `delete`) propagate rejections directly to the developer. If a provider throws or a mutator fails, the promise returned by the model method will reject with that error.
- **Event Scopes**: Individual resource updates maintain their original scope (e.g., `scope: "resource"`), while only the final aggregate state transition uses `scope: "model"`.

## Value Type Contract

Addison enforces **Snapshot Isolation** to prevent accidental mutation of the model's internal state. By providing **Value Semantics** through **Defensive Copying**, the engine ensures that every read operation returns an **Isolated Snapshot**. To support this, all resource value types MUST implement the following contract:

- **Static `@from(data)`**: A static method that takes raw (or cloned) resource data and returns a new instance of the value wrapper.
- **`data` property**: A property containing the serializable state of the resource. This property MUST be compatible with `structuredClone`.

The default `Value` class provided by Addison adheres to this contract. Developers implementing custom domain-specific value wrappers must ensure they provide the static `from` method and that their `data` is cloneable.
