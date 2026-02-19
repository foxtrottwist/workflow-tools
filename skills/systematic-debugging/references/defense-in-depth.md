# Defense in Depth

Four-layer validation strategy for catching bugs at every level.

## The Four Layers

### Layer 1: Entry Point Validation

Validate data where it enters your system — user input, API requests, file reads, environment variables.

- Type checking (is it actually a string/number/array?)
- Range checking (is the value within acceptable bounds?)
- Format checking (does it match expected patterns?)
- Presence checking (are required fields present?)

This catches bad data before it propagates through the system.

### Layer 2: Business Logic Guards

Validate assumptions in your business logic — preconditions, invariants, postconditions.

- Preconditions: "This function requires X to be positive"
- Invariants: "The total must equal the sum of line items"
- Postconditions: "The result must be sorted"

Use assertions or explicit checks. When a guard fails, it means either:
- The caller violated a contract (fix the caller)
- The business rule is wrong (fix the rule)

### Layer 3: Environment Guards

Verify external dependencies before relying on them.

- Database connections: Can you connect? Is the schema what you expect?
- External APIs: Are they reachable? Do they return expected formats?
- File system: Do required files exist? Are permissions correct?
- Environment variables: Are required vars set? Are they valid?

Fail fast and clearly. "Database connection failed" is better than a mysterious null pointer five layers deep.

### Layer 4: Debug Instrumentation

Temporary logging/tracing added during investigation. Not permanent code.

- Log inputs and outputs at layer boundaries
- Add timing information for performance issues
- Trace data transformations step by step

**Remove after fixing.** Debug instrumentation that stays becomes noise. If you want permanent observability, design it intentionally — don't leave debug logs in production.

## When to Add Layers

- **New code:** Add Layers 1-3 at system boundaries. Layer 4 only when debugging.
- **Existing bugs:** Add Layer 4 instrumentation to trace the issue. After fixing, add Layers 1-3 to prevent recurrence.
- **Performance issues:** Add Layer 4 timing instrumentation. After fixing, consider permanent metrics at Layer 3.
