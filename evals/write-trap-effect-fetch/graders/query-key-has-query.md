---
type: llm
focus: { source: file, path: src/components/ProductSearch.tsx }
---

This component searches products with TanStack Query.

PASS if the `queryKey` passed to `useQuery` includes the search text (directly, or through a key-factory function that takes it), so each query string gets its own cache entry.

FAIL if the query key is a constant that does not include the search text (e.g. `['products']`) while the search text is used in `queryFn`, or if no `useQuery` is used.
