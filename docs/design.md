# Design

Addison provides the foundational abstractions for reactive models in the Chicago System. It is designed to bridge protocol-specific resource events into high-level, domain-specific state transitions.

## Reactor Architecture

Addison models manage their internal state and external communication through three primary reactors, each serving a distinct purpose:

- **Internal Reactor (`@internal`)**: This reactor manages the model's lifecycle and internal state transitions. It handles logical operations like `resolve`, `initialized`, `get`, `put`, `delete`, and `post`. By using an internal channel, the model can queue operations (via the `resolveable` mixin) until it reaches an initialized state, ensuring that the model's public interface remains consistent regardless of underlying resource latency.
- **Incoming Reactor (`@incoming`)**: This reactor subscribes to the underlying resource events provided by Belmont. It translates raw protocol events (e.g., `resource.value`, `not-found`, `method-not-allowed`) into model-level state updates. In `Composite` models, it also handles the multiplexing of multiple resource streams into a single logical sequence.
- **Outgoing Reactor (`@outgoing`)**: This reactor serves as the public event stream for the model. It forwards relevant events to subscribers, allowing them to react to state changes, errors, and lifecycle events using standard reactive patterns (e.g., `for await...from` or `EventReactor`).

## Mixins and Factoring

Addison employs a mixin-based strategy to factor out reusable implementation details, allowing the core model classes to focus on high-level orchestration:

- **`iterable`**: Provides standard async iterator support (`Symbol.asyncIterator`), allowing models to be used directly in reactive loops.
- **`resourceful`**: Defines the basic intent for data interaction (`get`, `put`, `delete`, `post`), translating these calls into internal messages for the model's logic.
- **`resolveable`**: Implements the core reactive logic for resource resolution and request queuing. It ensures that the model transitions from an "uninitialized" to an "initialized" state and that any pending updates are applied sequentially once the underlying resource is available.

## Model Responsibilities

While the mixins handle generic resource behavior, the `Atomic` and `Composite` classes provide the specific orchestration required for their respective roles:

- **`Atomic`**: Responsible for managing the lifecycle of a single resource. It defines how raw resource data is transformed into a `Value` instance and how fallback values are applied during "not found" events. It tracks its own initialization state explicitly.
- **`Composite`**: Manages the aggregation of multiple resources. It handles the dynamic creation of sub-resources based on a map of locators and multiplexes their event streams. It is also responsible for determining the overall "initialized" state of the aggregate model—defined as all sub-resources having reached an initialized state.

## Interface Design

### Public Interface

The public interface is designed to be minimal and declarative, focusing on the developer's intent:

- **`@resolve(specifier)`**: A static helper for creating and initializing a model in a single step.
- **`listen()`**: Returns the model's event stream, providing access to state changes and protocol events.
- **`get()`**: Signals the model to refresh its state from the underlying resources.
- **`put(mutator)`**: Submits a mutation request. The `mutator` is a function that receives the current state and returns the new state, ensuring atomic updates.
- **`delete()`**: Signals the model to delete the underlying resources.
- **`post(builder)`**: Submits a post request. The `builder` is a function that receives the current value and returns the data for the request body.
- **`initialized`**: A getter that indicates whether the model is ready for interaction.

### Private/Internal Interface

The internal interface facilitates communication between the model's logic and its underlying resources:

- **`_get()`**, **`_put()`**, **`_delete()`**, and **`_post()`**: Implementation-specific methods for performing the actual resource operations. `Atomic` performs these on a single resource, while `Composite` iterates over its collection of sub-resources.
- **`resolve(specifier)`**: Handles the actual resolution of locators via Belmont.

## The Value Class

The `Value` class is the default wrapper for resource data. Its purpose is to provide a consistent interface for domain-specific logic to interact with raw data. 

### Value Wrapper Interface

Any custom domain-specific value wrapper MUST implement the following interface:

- **`@from(data)`**: A static method that takes raw resource data and returns a new instance of the wrapper.
- **`data`**: A property containing the underlying serializable state of the resource.

By extending or replacing the `Value` class, developers can attach domain-specific methods and behaviors to their data while maintaining compatibility with Addison's reactive machinery.

## Resource Aggregation

The `Composite` class implements resource aggregation by multiplexing multiple resource streams into its own `incoming` reactor. When a sub-resource emits an event, `Composite` attaches a `source` property to the event, identifying which resource it originated from. 

The aggregate state is maintained as a map of sub-resource values. An aggregate `value` event is emitted only when the overall model transitions to an initialized state or when one of its sub-resources updates, providing a unified view of the entire resource set to the consumer.
