---
type: llm
focus: { source: file, path: src/routes/products.tsx }
---

This is a TanStack Router file route for a paginated, filterable product list.

PASS if either (a) the route's `loader` receives the search values through `loaderDeps` and uses them, or (b) the data is fetched with TanStack Query (`useQuery`/`useSuspenseQuery`, optionally preloaded with `ensureQueryData` in the loader) with the page, category and search text included in the query key.

FAIL if a loader reads search params without `loaderDeps` (e.g. from `window.location` or a closure), or the query key omits page/category/search.
