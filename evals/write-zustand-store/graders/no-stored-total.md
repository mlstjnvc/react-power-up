---
type: llm
focus: { source: file, path: src/stores/cart.ts }
---

This is a Zustand cart store.

PASS if the cart total and item count are derived from the lines (computed in a selector function or a derived getter that reads the lines), not stored as separate state fields that actions update by hand.

FAIL if `total` or `count` (or similar) is a stored state field that actions increment or recompute and write back with `set`.
