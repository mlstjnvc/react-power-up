---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a products page at `/products` as a file route `src/routes/products.tsx`. It lists products from `fetchProducts` in `src/api/products.ts` with a category filter (all / books / games / music), a search box, and previous/next paging. The filter, search text and page must be in the URL so the page can be shared. Each product links to `/products/$productId` (create that route too, in `src/routes/products.$productId.tsx`, showing just the product id for now).
