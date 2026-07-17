# Testing

This document explains how testing is organized and executed for the Addison repository.

## How to run the test suite?

The testing process relies on the Genie task manager. The suite verifies the internal queuing, state transitions, and asynchronous operations of the Addison models.

To run the complete test suite, execute the following command:

```bash
npx genie test
```

## How are tests structured?

The tests ensure that the reactive abstractions accurately wrap and relay the underlying resource protocols.

- **Atomic Model Tests**: Validate that the atomic interface correctly delegates calls to the underlying composite model and accurately relays fallback values.
- **Composite Model Tests**: Validate aggregate resource fetch, mutation, and state tracking, ensuring that errors or delayed initialization properly queue operations.
- **Engine Logic Tests**: Ensure that the gating and sequential draining mechanisms accurately process asynchronous commands without race conditions.
