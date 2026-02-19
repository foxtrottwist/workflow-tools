# Root Cause Tracing

Backward trace methodology for finding where things go wrong.

## The Backward Trace

Start at the failure point. Work backward through the call stack.

At each layer, answer three questions:
1. What data arrived here?
2. Is it what was expected?
3. Where did it come from?

Continue until you find the layer where correct data enters and incorrect data exits. That's your root cause location.

## Stack Forensics

When you have an error with a stack trace:

1. **Read bottom-up.** The bottom of the stack is where execution started. The top is where it failed.
2. **Find the boundary.** Identify which frame is your code vs library code. The bug is almost always in your code, at the boundary where it hands off to the library.
3. **Check the frame before the error.** The failing line is a symptom. The frame that called it with wrong arguments is the cause.

## Polluter Detection (Test Isolation)

When tests pass individually but fail together, one test is "polluting" shared state:

1. **Binary search.** Run the failing test with half the test suite. Narrow down which tests cause the failure.
2. **Check shared state.** Global variables, singletons, module-level state, environment variables, file system artifacts.
3. **Verify isolation.** Run the suspect test, then immediately run the failing test. If it fails, you've found the polluter.

## Environment Forensics

When the same code behaves differently across environments:

- **Diff configurations.** Every config file, environment variable, feature flag.
- **Check versions.** Runtime version, dependency versions, OS version.
- **Check state.** Database contents, cache state, file system contents.
- **Network.** DNS resolution, firewall rules, proxy settings, API endpoint URLs.

The bug is in the delta. Find what's different between working and broken environments.
