# TanStack Router (`REACT-TSR-*`)

Rules for TanStack Router v1 (`@tanstack/react-router`) in React SPAs. File-based routing is the default:
- **Vite:** `@tanstack/router-plugin`, with `tanstackRouter({ target: 'react', autoCodeSplitting: true })` placed **before** `react()` in `vite.config.ts`.
- **Other bundlers:** the `@tanstack/router-cli` generator.

Both write `routeTree.gen.ts`. Code-based routing (`createRoute`) follows the same rules. Search-param validation uses the project's schema library; examples use Zod.

---

### REACT-TSR-001 · Never edit `routeTree.gen.ts` by hand  `warn`

**Why:** The route tree is regenerated from `src/routes/` by the router plugin or CLI on every change. Manual edits are silently overwritten, and they desync the types. Change the route files instead. Exclude the generated file from linting and formatting.
**Source:** https://tanstack.com/router/latest/docs/installation/with-vite#ignoring-the-generated-route-tree-file

```tsx
// ❌ editing src/routeTree.gen.ts to add a route

// ✅ create src/routes/invoices.$invoiceId.tsx; the plugin regenerates the tree
export const Route = createFileRoute('/invoices/$invoiceId')({ component: InvoicePage })
```

**Applies:** TanStack Router ≥ 1 with file-based routing · **Exceptions:** none.

### REACT-TSR-002 · Register the router type once  `warn`

**Why:** TanStack Router's type safety (typed `to`, `params`, `search` and hook results everywhere) comes from registering the router instance through module augmentation. Without it, `Link` and `useNavigate` accept any string and the hooks return loose types, so typos in paths compile.
**Source:** https://tanstack.com/router/latest/docs/guide/type-safety

```tsx
// ❌
const router = createRouter({ routeTree })
// (no Register augmentation)

// ✅ (src/main.tsx or src/router.tsx)
const router = createRouter({ routeTree, context: { queryClient } })
declare module '@tanstack/react-router' {
  interface Register { router: typeof router }
}
```

**Applies:** TanStack Router ≥ 1 · **Exceptions:** none.

### REACT-TSR-003 · Validate and type search params with `validateSearch`  `warn`

**Why:** Search params are user input. Reading them raw (`useSearch({ strict: false })`, `location.search`) gives untyped, unvalidated values: `?page=abc` becomes `NaN`, and unknown sort keys reach the API. `validateSearch` with a schema parses, types and defaults them in one place. Use `.catch()` so a malformed URL falls back instead of erroring.
**Source:** https://tanstack.com/router/latest/docs/guide/search-params#validating-search-params · https://tanstack.com/router/latest/docs/guide/search-params#zod

```tsx
// ❌
export const Route = createFileRoute('/products')({ component: Products })
function Products() {
  const search = useSearch({ strict: false }) as { page?: string }
  const page = Number(search.page)
  // …
}

// ✅
const productSearch = z.object({
  page: z.number().int().min(1).catch(1),
  sort: z.enum(['newest', 'price']).catch('newest'),
  q: z.string().catch(''),
})
export const Route = createFileRoute('/products')({ validateSearch: productSearch, component: Products })
function Products() {
  const { page, sort, q } = Route.useSearch()         // typed and validated
  // …
}
```

**Applies:** TanStack Router ≥ 1 (passing a Standard Schema such as Zod ≥ 3.24 directly; older Zod via `@tanstack/zod-adapter`) · **Exceptions:** none.

### REACT-TSR-004 · Search params used by a loader must go through `loaderDeps`  `error`

**Why:** Loader results are cached by path and `loaderDeps`. A loader that reads search params from anywhere else (closing over `location`, or reading `window.location`) caches one result for all search values. Changing `?page=` shows the old page's data. Declare the search values as `loaderDeps`, and read them from `deps`.
**Source:** https://tanstack.com/router/latest/docs/guide/data-loading#using-loaderdeps-to-access-search-params

```tsx
// ❌
export const Route = createFileRoute('/posts')({
  validateSearch: z.object({ page: z.number().catch(1) }),
  loader: () => fetchPosts({ page: Number(new URLSearchParams(window.location.search).get('page') ?? 1) }),
})

// ✅
export const Route = createFileRoute('/posts')({
  validateSearch: z.object({ page: z.number().catch(1) }),
  loaderDeps: ({ search: { page } }) => ({ page }),
  loader: ({ deps: { page } }) => fetchPosts({ page }),
})
```

**Applies:** TanStack Router ≥ 1 · **Exceptions:** none.

### REACT-TSR-005 · Build links from `to` + `params` + `search`, not string templates  `warn`

**Why:** `` <Link to={`/invoices/${id}`}> `` bypasses route type checking. A renamed route or a missing param still compiles, and values aren't encoded. `to="/invoices/$invoiceId"` with `params={{ invoiceId }}` is checked against the route tree, and the router encodes the values.
**Source:** https://tanstack.com/router/latest/docs/guide/navigation#dynamic-links · https://tanstack.com/router/latest/docs/guide/navigation#search-param-links

```tsx
// ❌
<Link to={`/invoices/${invoice.id}?tab=items`}>Open</Link>
navigate({ to: `/invoices/${invoice.id}` })

// ✅
<Link to="/invoices/$invoiceId" params={{ invoiceId: invoice.id }} search={{ tab: 'items' }}>Open</Link>
navigate({ to: '/invoices/$invoiceId', params: { invoiceId: invoice.id } })
```

**Applies:** TanStack Router ≥ 1 · **Exceptions:** external URLs, which use a plain `<a>`.

### REACT-TSR-006 · Check auth in `beforeLoad` and `throw redirect()`, not in the component  `warn`

**Why:** A component that checks auth after mounting has already started its loaders and briefly rendered protected UI. `beforeLoad` runs before child loaders and components, and `throw redirect({ to: '/login', search: { redirect: location.href } })` stops navigation cleanly. This is UX only: the API must still authorize every request (see `security.md`), and the `redirect` value must be validated before use (REACT-RR-005 applies the same way).
**Source:** https://tanstack.com/router/latest/docs/guide/authenticated-routes#the-route-beforeload-option

```tsx
// ❌
function Dashboard() {
  const { auth } = Route.useRouteContext()
  if (!auth.user) return <Navigate to="/login" />
  return <DashboardView />
}

// ✅ (src/routes/_authed.tsx: layout route guarding its children)
export const Route = createFileRoute('/_authed')({
  beforeLoad: ({ context, location }) => {
    if (!context.auth.user) throw redirect({ to: '/login', search: { redirect: location.href } })
  },
})
```

**Applies:** TanStack Router ≥ 1 (router context typed with `createRootRouteWithContext`) · **Exceptions:** none.

### REACT-TSR-007 · With TanStack Query, `ensureQueryData` in the loader and `useSuspenseQuery` in the component  `warn`

**Why:** Fetching in the loader *and* separately in the component (or copying loader data into Query) gives two caches that disagree. The documented integration: the loader calls `queryClient.ensureQueryData(options)` to start or reuse the cached request before render. The component reads the same `queryOptions` with `useSuspenseQuery`, so data is never undefined and stays in Query's cache, with refetching and invalidation.
**Source:** https://tanstack.com/router/latest/docs/guide/external-data-loading#a-more-realistic-example-using-tanstack-query · https://tanstack.com/router/latest/docs/integrations/query#preload-with-a-loader-and-read-with-a-hook

```tsx
// ❌
export const Route = createFileRoute('/posts/$postId')({
  loader: ({ params }) => fetchPost(params.postId),
  component: () => { const post = Route.useLoaderData(); const { data } = useQuery(postQuery(post.id)); /* … */ },
})

// ✅
const postQuery = (postId: string) => queryOptions({ queryKey: ['posts', postId], queryFn: () => fetchPost(postId) })
export const Route = createFileRoute('/posts/$postId')({
  loader: ({ context: { queryClient }, params: { postId } }) => queryClient.ensureQueryData(postQuery(postId)),
  component: PostPage,
})
function PostPage() {
  const { postId } = Route.useParams()
  const { data: post } = useSuspenseQuery(postQuery(postId))
  return <h1>{post.title}</h1>
}
```

**Applies:** TanStack Router ≥ 1 + TanStack Query ≥ 5 · **Exceptions:** projects without Query, which use loaders alone (with `staleTime` and `loaderDeps`).

### REACT-TSR-008 · Use route-bound hooks; reserve `strict: false` for shared components  `warn`

**Why:** `Route.useParams()`, `Route.useSearch()` and `Route.useLoaderData()` (or `useParams({ from: '/invoices/$invoiceId' })`) are typed exactly for that route. `strict: false` returns a loose union of every route's params, and hides mistakes. Use it only in genuinely shared components that render under many routes.
**Source:** https://tanstack.com/router/latest/docs/guide/type-safety#fixing-the-component-context-problem

```tsx
// ❌ (inside the invoice route's own component)
const { invoiceId } = useParams({ strict: false })

// ✅
const { invoiceId } = Route.useParams()
// in a different file: const { invoiceId } = getRouteApi('/invoices/$invoiceId').useParams()
```

**Applies:** TanStack Router ≥ 1 · **Exceptions:** shared layout or breadcrumb components that run under many routes.

### REACT-TSR-009 · Throw `notFound()` for missing data, and give routes error and pending UI  `warn`

**Why:** A loader that returns `null` for a missing entity makes every component handle "not found" itself, usually as a crash on `post.title`. `throw notFound()` renders the route's `notFoundComponent`. `errorComponent` and `pendingComponent` (or router-wide defaults) make failures and slow loads presentable, instead of blank.
**Source:** https://tanstack.com/router/latest/docs/guide/not-found-errors#throwing-your-own-notfound-errors · https://tanstack.com/router/latest/docs/guide/data-loading

```tsx
// ❌
loader: async ({ params }) => (await getPost(params.postId)) ?? null

// ✅
export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params }) => {
    const post = await getPost(params.postId)
    if (!post) throw notFound()
    return post
  },
  notFoundComponent: () => <p>Post not found.</p>,
  errorComponent: ({ error }) => <p role="alert">Couldn't load the post{error instanceof Error ? `: ${error.message}` : '.'}</p>,
  pendingComponent: () => <p>Loading…</p>,
})
```

**Applies:** TanStack Router ≥ 1 · **Exceptions:** router-wide `defaultNotFoundComponent`/`defaultErrorComponent`, which cover routes that don't define their own.
