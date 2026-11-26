---
type: llm
focus: { source: file, path: src/components/OrdersTable.tsx }
---

This React component uses TanStack Query v5.

PASS if the cancel-order mutation updates the cache after success: it calls `invalidateQueries` for the orders queries (or `setQueryData`) in `onSuccess`/`onSettled` (or the mutation is defined in another file that does so and is imported here).

FAIL if the cancel mutation never invalidates or updates any query, so the table would keep showing the order as open.
