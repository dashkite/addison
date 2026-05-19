# Design

Addison provides the foundational abstractions for reactive models in the Chicago System. It bridges protocol-specific resource events into high-level, domain-specific state transitions using a centralized logic reactor architecture.

## Architecture

Addison models manage their behavior through a single logic reactor that linearizes observations and commands:

- **Logic Reactor (`_logic`)**: This reactor subscribes to an internal channel (`@internal`) that receives both resource events (observations) and developer commands (requests). By processing all inputs through a single loop, Addison ensures deterministic state transitions and eliminates race conditions between data arrival and mutation requests.
- **Request Queue (`requests`)**: Commands issued after a model is resolved but before it is fully initialized (receiving its first resource events) are queued. Once the model reaches an `initialized` state, the reactor drains this queue in the exact order the commands were received.
- **Outgoing Channel (`@outgoing`)**: This serves as the public event stream for the model. It yields high-level model events (e.g., aggregate `value` changes) and forwards relevant resource events.

## Resource Aggregation and Delegation

Addison uses a tiered strategy for model specialization:

- **`Composite`**: The foundational "Engine." It implements the complete logic reactor, resource aggregation, and lifecycle management. The aggregate state is maintained as a map of sub-resource values. An aggregate `value` event is emitted only when the overall model transitions to an initialized state or when one of its sub-resources updates, providing a unified view of the entire resource set.
- **`Atomic`**: A specialized view of a single resource. Rather than inheriting the engine's complexity, `Atomic` **delegates** to an internal `Composite` instance. It maps its single-resource interface (e.g., `value`, `put`) to a fixed internal key in a Composite instance, effectively acting as a decorator that provides a simplified consumer experience while reusing the engine's robust queuing and linearization logic.

## Lifecycle and Gating

Addison models follow an explicit lifecycle managed by the logic reactor:

1.  **`unresolved`**: The initial state. Any attempt to call resource methods (`put`, `get`, etc.) will result in an immediate rejection.
2.  **`resolving`**: Entered once `resolve()` is called. The reactor begins establishing connections to underlying resources. Resource methods are now accepted but are queued.
3.  **`resolved`**: Entered once the connections to underlying resources are established and the model begins waiting for the initial data.
4.  **`initialized`**: Entered once the first resource data has been received for all locators. Any queued requests are drained, and subsequent requests are executed immediately.

## Interface Design

### Public Interface

The public interface is minimal and declarative:

- **`@resolve(specifier)`**: A static helper for creating and initializing a model in a single step.
- **`Iterator Protocol`**: Models adhere to the [Iterator Protocol](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols), making them directly iterable event streams.
- **`get()`**: Signals the model to refresh its state. Returns a promise.
- **`put(mutator)`**: Submits a mutation request. Returns a promise.
- **`delete()`**: Signals the model to delete the underlying resources. Returns a promise.
- **`post(builder)`**: Submits a post request. Returns a promise.

### The Value Class

The `Value` class is the default wrapper for resource data. Its purpose is to provide a consistent interface for domain-specific logic to interact with raw data. 

#### Value Wrapper Interface

Any custom domain-specific value wrapper MUST implement the following interface:

- **`@from(data)`**: A static method that takes raw resource data and returns a new instance of the wrapper.
- **`data`**: A property containing the underlying serializable state of the resource.
