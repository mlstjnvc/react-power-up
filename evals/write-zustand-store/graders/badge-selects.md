---
type: llm
focus: { source: file, path: src/components/CartBadge.tsx }
---

This React component reads from a Zustand store.

PASS if it reads store values through a selector (e.g. `useCartStore((s) => ...)` or an exported selector function), and if any selector returns a new object or array, it is wrapped in `useShallow`.

FAIL if it calls the store hook with no selector (`useCartStore()`), or a selector returns a fresh object/array literal without `useShallow`.
