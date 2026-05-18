# Design

Addison provides the foundational abstractions for reactive models in the Chicago System. It bridges protocol-specific resource events into high-level, domain-specific state transitions using a simplified, "Model Engine" architecture.

## Architecture

Addison models manage their behavior through a single observation reactor and a serialized command queue:

- **Observation Reactor (`listen`)**: This reactor subscribes to the underlying resource events provided by Belmont. It translates raw protocol events (e.g., `resource.value`, `not-found`, `method-not-allowed`) into model-level state updates. In `Composite` models, it also handles the multiplexing of multiple resource streams into a single logical sequence.
- **Request Queue (`requests`)**: To ensure consistency, commands issued before the model is initialized (such as `put`, `delete`, or `post`) are queued as closures. These are executed sequentially once the model receives its first resource events and transitions to an `initialized` state.
- **Outgoing Channel (`@outgoing`)**: This serves as the public event stream for the model. It forwards relevant events to subscribers, allowing them to react to state changes, errors, and lifecycle events using standard reactive patterns (e.g., `for await...from` or `EventReactor`).

## Core Components

Addison employs a mixin-based strategy to provide shared model behavior:

- **`iterable`**: Provides standard async iterator support (`Symbol.asyncIterator`), allowing models to be used directly in reactive loops.
- **`Model`**: Implements the core "Model Engine" logic, including the initialization gating, request queuing, and the public method interfaces (`get`, `put`, `delete`, `post`).

## Initialization and Gating

Addison uses an explicit `initialized` state to manage the transition from "unresolved" to "ready":

- **Atomic Model**: Becomes initialized upon receiving its first resource state or error event.
- **Composite Model**: Becomes initialized only after all sub-resources have reported their initial state.

The `Model` mixin uses an `execute()` helper to gate commands. If a command is issued while `initialized` is false, it returns a promise that resolves only after the model is initialized and the command has been processed in order.

## Interface Design

### Public Interface

The public interface is minimal and declarative:

- **`@resolve(specifier)`**: A static helper for creating and initializing a model in a single step.
- **`listen()`**: Returns the model's event stream, providing access to state changes and protocol events.
- **`get()`**: Signals the model to refresh its state from the underlying resources. Returns a promise.
- **`put(mutator)`**: Submits a mutation request. The `mutator` receives the current state and returns the new state. Returns a promise.
- **`delete()`**: Signals the model to delete the underlying resources. Returns a promise.
- **`post(builder)`**: Submits a post request. The `builder` receives the current value and returns the data for the request body. Returns a promise.
- **`initialized`**: A getter that indicates whether the model is ready for interaction.

### Private/Internal Interface

The internal interface facilitates communication between the model's logic and its underlying resources:

- **`_get()`**, **`_put()`**, **`_delete()`**, and **`_post()`**: Implementation-specific methods for performing the actual resource operations.
- **`_initialized()`**: Signalled by the observation reactor to trigger the draining of the request queue.
- **`_clear()`**: Resets the model's value state (e.g., for deletions).

## The Value Class

The `Value` class is the default wrapper for resource data. Its purpose is to provide a consistent interface for domain-specific logic to interact with raw data. 

### Value Wrapper Interface

Any custom domain-specific value wrapper MUST implement the following interface:

- **`@from(data)`**: A static method that takes raw resource data and returns a new instance of the wrapper.
- **`data`**: A property containing the underlying serializable state of the resource.

## Resource Aggregation

The `Composite` class implements resource aggregation by multiplexing multiple resource streams into its own `incoming` channel. When a sub-resource emits an event, `Composite` attaches a `source` property to the event, identifying which resource it originated from. 

The aggregate state is maintained as a map of sub-resource values. An aggregate `value` event is emitted only when the overall model transitions to an initialized state or when one of its sub-resources updates, providing a unified view of the entire resource set to the consumer.
