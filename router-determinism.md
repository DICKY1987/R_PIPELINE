# Router Determinism Preference

This proposal documents a minimal, non-breaking enhancement to the router to:

- Prefer deterministic adapters when `prefer_deterministic: true` and complexity is within a safe threshold.
- Annotate routing reasoning strings with a determinism analysis warning when step parameters appear non-deterministic (random, time, uuid, entropy sources).
- Degrade gracefully when the deterministic engine module is unavailable (analysis is best-effort only).

Rationale
- Align routing behavior with the system’s determinism-first principle.
- Provide visibility into potential non-determinism at decision time, not just at execution time.

Compatibility
- The logic is additive and non-blocking; existing routes remain valid.
- When the engine is unavailable, routing proceeds without annotations or preference changes.

Testing Approach
- Unit test stubs can simulate steps with `prefer_deterministic` and confirm deterministic alternatives are chosen when available and safe.
- Reasoning strings should include a `[determinism: warn …]` suffix when analysis flags issues.