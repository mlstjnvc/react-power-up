---
type: llm
focus: { source: file, path: lib/store.ts }
---

This is the Redux store setup for a Next.js App Router app.

PASS if the file exports a factory function (e.g. `makeStore = () => configureStore(...)`) and does NOT create a store instance at module scope (no top-level `export const store = configureStore(...)` or `const store = configureStore(...)` evaluated on import).

FAIL if a store instance is created at module scope.
