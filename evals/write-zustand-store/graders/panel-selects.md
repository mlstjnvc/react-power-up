---
type: llm
focus: { source: file, path: src/components/CartPanel.tsx }
---

This React component reads from a Zustand store.

PASS if it reads store values through selectors, and every selector that returns a new object or array (e.g. `(s) => ({ ... })`, `(s) => [s.a, s.b]`, `(s) => s.lines.map(...)`) is wrapped in `useShallow` (or the derived array is computed outside the selector).

FAIL if it calls the store hook with no selector, or a selector returns a fresh object/array without `useShallow`.
