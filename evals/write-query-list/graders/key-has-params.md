---
type: llm
focus: { source: file, path: src/api/orderQueries.ts }
---

These are TanStack Query definitions for a paginated, filterable orders list.

PASS if the query key for the orders list includes both the page and the status filter (directly or via a key factory), so each page/filter combination has its own cache entry.

FAIL if the list query key omits the page or the status while the query function uses them.
