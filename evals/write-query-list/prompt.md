---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create `src/components/OrdersTable.tsx`: a paginated table of orders using `fetchOrders` from `src/api/orders.ts`, with a status filter (all / open / shipped / cancelled), previous/next page buttons, loading and error states, and a "Cancel" button on open orders that calls `cancelOrder`. Put the query definitions in `src/api/orderQueries.ts`. Render the table in `src/App.tsx`.
