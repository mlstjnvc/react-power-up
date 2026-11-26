# TanStack Query (`REACT-QUERY-*`)

Rules for TanStack Query v5 (`@tanstack/react-query`): query keys, client lifetime, mutations, dependent queries and SSR. Where server data should live in the first place is covered in [`state.md`](state.md). Next.js App Router specifics are in `nextjs.md`.

---

### REACT-QUERY-001 · Put every variable the query function uses into the query key  `error`

**Why:** The key is the cache identity. If `queryFn` reads `page`, `filters` or `userId` but the key doesn't include them, every value shares one cache entry. The UI then shows data for the previous parameters, and changing them doesn't refetch.
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/query-keys#if-your-query-function-depends-on-a-variable-include-it-in-your-query-key

```tsx
// ❌
useQuery({ queryKey: ['orders'], queryFn: () => fetchOrders({ page, status }) })

// ✅
useQuery({ queryKey: ['orders', { page, status }], queryFn: () => fetchOrders({ page, status }) })
```

**Applies:** TanStack Query ≥ 4 · **Exceptions:** values that don't change the result (e.g. an auth token handled by the fetch client).

### REACT-QUERY-002 · Define each query once with `queryOptions` (a key factory)  `warn`

**Why:** Writing the same key and `queryFn` by hand in several components, and again in `invalidateQueries`, `prefetchQuery` and `setQueryData`, lets them drift. Then invalidation misses and prefetches don't match. `queryOptions` keeps key, function and options together, and types `getQueryData` from the key.
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/query-options

```tsx
// ❌
useQuery({ queryKey: ['todo', id], queryFn: () => fetchTodo(id) })
queryClient.invalidateQueries({ queryKey: ['todos', id] })      // typo: never matches

// ✅
export const todoQueries = {
  all: () => ['todos'] as const,
  detail: (id: string) => queryOptions({ queryKey: [...todoQueries.all(), id], queryFn: () => fetchTodo(id) }),
}
useQuery(todoQueries.detail(id))
queryClient.invalidateQueries({ queryKey: todoQueries.all() })
```

**Applies:** TanStack Query ≥ 5 (`queryOptions`) · **Exceptions:** a one-off query used in exactly one place.

### REACT-QUERY-003 · Create the `QueryClient` once: never during render, never shared across server requests  `error`

**Why:**
- A `new QueryClient()` in a component body creates a fresh, empty cache on every render. Nothing is ever cached, and queries refetch in loops.
- On the server, a module-scope client is shared by **all** requests, so users can see each other's data.
- **In a SPA:** create it once at module scope.
- **In SSR:** create it per request on the server, and once per browser session on the client (`useState(() => new QueryClient())`, or the docs' `getQueryClient()` helper).
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/ssr#initial-setup · https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr#initial-setup

```tsx
// ❌
function Providers({ children }: { children: React.ReactNode }) {
  const queryClient = new QueryClient()                 // new cache every render
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
}

// ✅ (SSR-safe)
function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({ defaultOptions: { queries: { staleTime: 60_000 } } }))
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
}
```

**Applies:** TanStack Query ≥ 4 · **Exceptions:** tests, which create a fresh client per test on purpose (see `testing.md`).

### REACT-QUERY-004 · Read query data from the query; don't copy it into state  `warn`

**Why:** `useEffect(() => setItems(data), [data])`, or copying `data` into a store, creates a second source of truth. It's a render behind, misses background refetches, and goes stale after invalidation. Derive what you need from `data` during render, or with `select`.
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/does-this-replace-client-state · https://react.dev/learn/choosing-the-state-structure#avoid-redundant-state

```tsx
// ❌
const { data } = useQuery(todoQueries.list())
const [todos, setTodos] = useState<Todo[]>([])
useEffect(() => { if (data) setTodos(data) }, [data])

// ✅
const { data: openTodos = [] } = useQuery({ ...todoQueries.list(), select: (todos) => todos.filter((t) => !t.done) })
```

**Applies:** TanStack Query ≥ 4 · **Exceptions:** seeding an *editable draft* (a form's initial values) from query data, done once by keying the form component on the data's id (see REACT-EFF-003).

### REACT-QUERY-005 · v5: no `onSuccess` / `onError` / `onSettled` on queries  `error`

**Why:** v5 removed these callbacks from `useQuery`. Code that passes them silently does nothing in JavaScript and fails to compile in TypeScript. They were also unreliable: they ran once per observer, not once per fetch. Handle side effects in mutations, derive from `data`, or use the global `QueryCache` callbacks for things like error toasts.
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5#callbacks-on-usequery-and-queryobserver-have-been-removed

```tsx
// ❌ (v5)
useQuery({ queryKey: ['me'], queryFn: fetchMe, onSuccess: (me) => setTheme(me.theme) })

// ✅ (v5)
const { data: me } = useQuery({ queryKey: ['me'], queryFn: fetchMe })
const theme = me?.theme ?? 'light'                       // derive; don't sync
// global error handling:
const queryClient = new QueryClient({ queryCache: new QueryCache({ onError: (error) => toast(error.message) }) })
```

**Applies:** TanStack Query ≥ 5 · **Exceptions:** `useMutation`, which still has `onSuccess`/`onError`/`onSettled`.

### REACT-QUERY-006 · After a mutation, invalidate or update the affected queries  `error`

**Why:** A mutation that changes server data, but doesn't touch the cache, leaves every list and detail view showing the old data until some unrelated refetch. Invalidate the affected keys in `onSuccess` (or `onSettled`), or write the returned entity with `setQueryData`.
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/invalidations-from-mutations

```tsx
// ❌
const mutation = useMutation({ mutationFn: createTodo })

// ✅
const queryClient = useQueryClient()
const mutation = useMutation({
  mutationFn: createTodo,
  onSuccess: () => queryClient.invalidateQueries({ queryKey: todoQueries.all() }),
})
```

**Applies:** TanStack Query ≥ 4 · **Exceptions:** mutations whose result no query displays.

### REACT-QUERY-007 · Optimistic cache updates must cancel, snapshot and roll back  `error`

**Why:** Writing an optimistic value with `setQueryData` without first cancelling in-flight refetches lets an older response overwrite it. Without a snapshot and an `onError` rollback, a failed request leaves the wrong data on screen. The documented sequence is: `cancelQueries` → snapshot → `setQueryData` → roll back in `onError` → invalidate in `onSettled`. For UI-only optimism, rendering `mutation.variables` while it's pending is simpler and needs no rollback.
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates#via-the-cache · https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates#via-the-ui

```tsx
// ❌
useMutation({
  mutationFn: updateTodo,
  onMutate: (next: Todo) => queryClient.setQueryData(['todos', next.id], next),
})

// ✅
useMutation({
  mutationFn: updateTodo,
  onMutate: async (next: Todo) => {
    const key = todoQueries.detail(next.id).queryKey
    await queryClient.cancelQueries({ queryKey: key })
    const previous = queryClient.getQueryData(key)
    queryClient.setQueryData(key, next)
    return { previous, key }
  },
  onError: (_err, _next, ctx) => { if (ctx) queryClient.setQueryData(ctx.key, ctx.previous) },
  onSettled: (_data, _err, next) => queryClient.invalidateQueries({ queryKey: todoQueries.detail(next.id).queryKey }),
})
```

**Applies:** TanStack Query ≥ 5 (on 4, the same steps with v4 signatures) · **Exceptions:** none when writing to the cache optimistically.

### REACT-QUERY-008 · Express dependencies with the key and `enabled`, not with effects and `refetch()`  `warn`

**Why:** `useEffect(() => { refetch() }, [userId])` fights the cache: it refetches the *old* key, races, and runs twice under StrictMode. Put the parameter in the key so changing it fetches automatically. Use `enabled` to wait for a value the query depends on.
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/dependent-queries#usequery-dependent-query

```tsx
// ❌
const { data: projects, refetch } = useQuery({ queryKey: ['projects'], queryFn: () => fetchProjects(user?.id) })
useEffect(() => { void refetch() }, [user?.id, refetch])

// ✅
const userId = user?.id
const { data: projects } = useQuery({
  queryKey: ['projects', userId],
  queryFn: () => fetchProjects(userId!),                 // safe: only runs when enabled
  enabled: !!userId,
})
```

**Applies:** TanStack Query ≥ 4 · **Exceptions:** an explicit user-triggered "Refresh" button, which may call `refetch()` from its handler.

### REACT-QUERY-009 · Use the v5 names: `isPending`, `gcTime`, one options object  `warn`

**Why:**
- v5 supports only the single-object signature (`useQuery({ queryKey, queryFn })`), and renamed `cacheTime` to `gcTime`.
- The "no data yet" status is `isPending`/`status === 'pending'`. In v5, `isLoading` means "pending **and** currently fetching", so it's `false` for a disabled query with no data, and a guard built on it lets `undefined` data through.
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5#supports-a-single-signature-one-object · https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5#rename-cachetime-to-gctime

```tsx
// ❌ (v5)
const { data, isLoading } = useQuery(['user', id], () => fetchUser(id), { cacheTime: 300_000 })
if (isLoading) return <Spinner />
return <p>{data.name}</p>                               // data may still be undefined

// ✅ (v5)
const { data, isPending, isError, error } = useQuery({ queryKey: ['user', id], queryFn: () => fetchUser(id), gcTime: 300_000 })
if (isPending) return <Spinner />
if (isError) return <p role="alert">{error.message}</p>
return <p>{data.name}</p>
```

**Applies:** TanStack Query ≥ 5. On v4, the old names are correct, so don't flag them · **Exceptions:** none.

### REACT-QUERY-010 · Pass the query's `signal` to the request  `info`

**Why:** TanStack Query provides an `AbortSignal` to every `queryFn`. Passed to `fetch` (or the HTTP client), it cancels requests that are no longer needed, when the key changes or the component unmounts. Ignore it, and stale requests keep running.
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/query-cancellation#using-fetch

```tsx
// ❌
queryFn: () => fetch(`/api/search?q=${encodeURIComponent(q)}`).then((r) => r.json())

// ✅
queryFn: ({ signal }) => fetch(`/api/search?q=${encodeURIComponent(q)}`, { signal }).then((r) => r.json())
```

**Applies:** TanStack Query ≥ 4 · **Exceptions:** request helpers that don't accept a signal.

### REACT-QUERY-011 · SSR: prefetch on the server, pass a dehydrated cache, and set `staleTime` above zero  `warn`

**Why:**
- Fetching only on the client after an SSR page loads shows a spinner the server could have avoided.
- Prefetching into a *per-request* client and wrapping the client tree in `HydrationBoundary` with `dehydrate(queryClient)` ships the data with the HTML.
- With the default `staleTime: 0`, the client refetches everything immediately after hydration, so set a positive default.
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr#prefetching-and-de-hydrating-data · https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr#initial-setup

```tsx
// ❌ (App Router page)
export default function PostsPage() {
  return <Posts />                                       // client component fetches after hydration
}

// ✅ (App Router page, server component)
export default async function PostsPage() {
  const queryClient = new QueryClient()                  // per request
  await queryClient.prefetchQuery(postQueries.list())
  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <Posts />                                          {/* useQuery(postQueries.list()) finds the data */}
    </HydrationBoundary>
  )
}
```

**Applies:** TanStack Query ≥ 5 with SSR (Next.js App Router; see `nextjs.md`) · **Exceptions:** data that must be fresh on every client view, where `staleTime: 0` is intended for that query.
