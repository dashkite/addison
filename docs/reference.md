# Reference

## Value

### @from
$@from: data \to value$

Returns a new Value instance with the provided data.

### data
$data \to any$

The underlying data associated with the value.

## Atomic

Represents a model for a single resource.

### @make
$@make: options \to atomic$

Creates a new Atomic model instance. `options` may include a `type` (defaults to Value) and `locator` properties.

### @resolve
$@resolve: specifier \dashrightarrow atomic$

Creates and resolves an Atomic model instance using the provided specifier.

### resolve
$resolve: specifier \dashrightarrow atomic$

Resolves the model's resource using the provided specifier.

### listen
$listen: : \to async\_iterator$

Returns an async iterator that yields model events.

### get
$get: : \to \emptyset$

Triggers a fetch of the resource state.

### put
$put: mutator \to \emptyset$

Updates the resource state using the provided mutator function.

### delete
$delete: : \to \emptyset$

Triggers a deletion of the resource.

### valid
$valid \to boolean$

True if the model has received its first protocol event and its value is initialized.

## Composite

Represents a model that aggregates multiple resources.

### @make
$@make: locators \to composite$

Creates a new Composite model instance with the specified map of locators.

### @resolve
$@resolve: specifier \dashrightarrow composite$

Creates and resolves a Composite model instance using the provided specifier.

### resolve
$resolve: specifier \dashrightarrow composite$

Resolves all underlying resources using the provided specifier.

### listen
$listen: : \to async\_iterator$

Returns an async iterator that yields aggregated model events.

### get
$get: : \to \emptyset$

Triggers a fetch for all underlying resources.

### put
$put: mutator \to \emptyset$

Updates the aggregate state using the provided mutator function.

### delete
$delete: : \to \emptyset$

Triggers a deletion of all underlying resources.

### valid
$valid \to boolean$

True if all underlying resources have received their first protocol event.
