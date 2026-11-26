# React Router, library mode (`REACT-RR-*`)

Rules for React Router in **data mode** (`createBrowserRouter`, loaders, actions) and **declarative mode** (`<BrowserRouter>`, `<Routes>`). v8 is primary. v8 needs React ≥ 19.2.7, so React 18 projects stay on v7, and v7 differences are noted. **Framework mode** (formerly Remix: `react-router.config.ts`, route modules, typegen) is detected but not covered in depth. Apply the core React rules there, plus the rules below that apply to it.

URL state (search params) is covered in REACT-STATE-010. Validating where you redirect to is REACT-RR-005, and the general rule is in `security.md`.

---

### REACT-RR-001 · Load route data in a `loader`, not in a component effect  `warn`

**Why:** In data mode, a route's `loader` runs before the route renders and in parallel with its parent loaders. Navigation then waits for the data, there's no loading flash, no request waterfall and no race. Fetching in a `useEffect` inside the route component throws all of that away (see REACT-EFF-005).
**Source:** https://reactrouter.com/start/data/data-loading

```tsx
// ❌
function Invoice() {
  const { id } = useParams()
  const [invoice, setInvoice] = useState<Invoice | null>(null)
  useEffect(() => { void getInvoice(id!).then(setInvoice) }, [id])
  return invoice ? <InvoiceView invoice={invoice} /> : <Spinner />
}

// ✅
const router = createBrowserRouter([
  {
    path: '/invoices/:id',
    loader: async ({ params }) => getInvoice(parseId(params.id)),
    Component: Invoice,
  },
])
function Invoice() {
  const invoice = useLoaderData<Awaited<ReturnType<typeof getInvoice>>>()
  return <InvoiceView invoice={invoice} />
}
```

**Applies:** React Router ≥ 6.4 data mode (v7, v8) · **Exceptions:**
- Declarative mode has no loaders: use the project's data layer (TanStack Query), or REACT-EFF-005's race-safe effect.
- When the project uses TanStack Query, the loader can `ensureQueryData` and the component can `useQuery` (see `tanstack-query.md`).

### REACT-RR-002 · Treat `params` and search params as untrusted strings  `warn`

**Why:** `useParams()` and loader `params` are typed `string | undefined`, and search params are whatever the user typed in the address bar. Passing them unchecked into numbers, enums, API calls or URLs produces `NaN` pages, invalid requests, and injection into other URLs. Parse them, encode them, and handle the invalid case (a 404 or a default value).
**Source:** https://reactrouter.com/api/hooks/useParams · https://reactrouter.com/api/hooks/useSearchParams

```tsx
// ❌
loader: async ({ params }) => fetch(`/api/invoices/${params.id}`).then((r) => r.json())

// ✅
loader: async ({ params }) => {
  const id = params.id
  if (!id || !/^[0-9a-f-]{36}$/.test(id)) throw data('Invoice not found', { status: 404 })
  const res = await fetch(`/api/invoices/${encodeURIComponent(id)}`)
  if (!res.ok) throw data('Invoice not found', { status: res.status })
  return parseInvoice(await res.json())
}
```

**Applies:** React Router ≥ 6.4 (`data` helper: ≥ 7) · **Exceptions:** none.

### REACT-RR-003 · Navigate internally with `<Link>`/`<NavLink>`, not `<a href>`  `warn`

**Why:** A plain `<a href="/orders">` to an internal route does a full page reload. It refetches everything, loses client state and skips the router's loaders, pending UI and transitions. `<Link to>` navigates client-side, and `<NavLink>` adds the active state (with `aria-current`).
**Source:** https://reactrouter.com/api/components/Link · https://reactrouter.com/start/declarative/navigating#navlink

```tsx
// ❌
<a href={`/orders/${order.id}`}>View</a>

// ✅
<Link to={`/orders/${order.id}`}>View</Link>
<NavLink to="/orders" end>Orders</NavLink>
```

**Applies:** React Router ≥ 6 · **Exceptions:** external URLs; links that deliberately reload (`reloadDocument`).

### REACT-RR-004 · Never call `navigate()` during render; redirect in a loader or action, or render `<Navigate>`  `error`

**Why:** `navigate()` is a side effect. Called during render, it triggers a state update in the router while React renders, which React warns about, runs twice under StrictMode, and can loop. For "must be signed in" or "moved" pages, `redirect()` from a loader or action (data mode) happens before rendering. In declarative mode, render `<Navigate to=… replace />`.
**Source:** https://reactrouter.com/api/hooks/useNavigate · https://reactrouter.com/api/utils/redirect

```tsx
// ❌
function Account() {
  const user = useUser()
  const navigate = useNavigate()
  if (!user) navigate('/login')                  // during render
  return <Profile user={user!} />
}

// ✅ (data mode)
{ path: '/account', loader: async () => { const user = await getUser(); if (!user) throw redirect('/login'); return user }, Component: Account }

// ✅ (declarative mode)
function Account() {
  const user = useUser()
  if (!user) return <Navigate to="/login" replace />
  return <Profile user={user} />
}
```

**Applies:** React Router ≥ 6 · **Exceptions:** `navigate()` in event handlers and effects, its intended use.

### REACT-RR-005 · Only redirect to validated same-site paths  `error`

**Why:** A `?redirect=`, `?next=` or `returnTo` value passed straight to `navigate`, `redirect` or `<Navigate>` is an **open redirect**. An attacker sends `…/login?redirect=https://evil.example`, and after signing in the user lands on a phishing page served from your link. Accept only relative paths that start with a single `/`, and fall back to a default otherwise.
**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html

```tsx
// ❌
const [params] = useSearchParams()
navigate(params.get('redirect') ?? '/')

// ✅
function safeRedirect(target: string | null, fallback = '/'): string {
  if (!target || !target.startsWith('/') || target.startsWith('//') || target.includes('\\')) return fallback
  return target
}
navigate(safeRedirect(params.get('redirect')))
```

**Applies:** any router (this is the React Router form; see `security.md` for TanStack Router and Next.js) · **Exceptions:** an explicit allow-list of external hosts, checked by parsing with `new URL()`.

### REACT-RR-006 · Give the route tree an error boundary  `warn`

**Why:** Without an `ErrorBoundary` (or `errorElement`), an error thrown in a loader, an action or a route component shows React Router's default developer error screen to users. Add one at the root at least, and nested ones where a section can fail independently. Use `isRouteErrorResponse` to render 404s and other thrown responses properly.
**Source:** https://reactrouter.com/how-to/error-boundary#data-mode

```tsx
// ❌
createBrowserRouter([{ path: '/', Component: Root, children: [/* … */] }])

// ✅
function RootErrorBoundary() {
  const error = useRouteError()
  if (isRouteErrorResponse(error)) return <h1>{error.status} {error.statusText}</h1>
  return <h1>Something went wrong.</h1>
}
createBrowserRouter([{ path: '/', Component: Root, ErrorBoundary: RootErrorBoundary, children: [/* … */] }])
```

**Applies:** React Router ≥ 6.4 data mode (`ErrorBoundary` as a component: ≥ 6.9) · **Exceptions:** declarative mode, which uses a React error boundary instead (REACT-COMP-010).

### REACT-RR-007 · v8: import from `react-router` (DOM-only APIs from `react-router/dom`); `react-router-dom` is gone  `error`

**Why:** React Router v8 removed the `react-router-dom` package. Imports from it don't resolve after upgrading, and installing it next to v8 pulls in a second, mismatched router. Everything comes from `react-router`. `RouterProvider` for the DOM comes from `react-router/dom`.
**Source:** https://reactrouter.com/upgrading/v7#react-router-dom

```tsx
// ❌ (v8)
import { Link, useNavigate } from 'react-router-dom'
import { RouterProvider } from 'react-router-dom'

// ✅ (v8)
import { Link, useNavigate } from 'react-router'
import { RouterProvider } from 'react-router/dom'
```

**Applies:** React Router ≥ 8. On v7, `react-router-dom` still works as a re-export: follow the project, but prefer `react-router` in new code · **Exceptions:** none.

### REACT-RR-008 · Mutate through route `action`s with `<Form>` or `useFetcher`  `warn`

**Why:** An `action` with `<Form method="post">` (navigating) or `fetcher.Form` (in place) gives you pending state through `useNavigation`/`fetcher.state`, and automatic **revalidation** of every loader on the page afterwards. A hand-rolled `onSubmit` + `fetch` gets neither, so the page shows stale loader data.
**Source:** https://reactrouter.com/start/data/actions · https://reactrouter.com/start/data/actions#calling-actions-with-a-fetcher

```tsx
// ❌
async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
  e.preventDefault()
  await fetch('/api/projects', { method: 'POST', body: new FormData(e.currentTarget) })
}

// ✅
{ path: '/projects/new', action: async ({ request }) => {
    const form = await request.formData()
    const project = await createProject(parseProjectForm(form))
    return redirect(`/projects/${project.id}`)
  }, Component: NewProject }
function NewProject() {
  const navigation = useNavigation()
  return (
    <Form method="post">
      <label>Name <input name="name" required /></label>
      <button type="submit" disabled={navigation.state === 'submitting'}>Create</button>
    </Form>
  )
}
```

**Applies:** React Router ≥ 6.4 data mode · **Exceptions:** forms managed by React Hook Form, which can call `useSubmit()` or `fetcher.submit()` from `handleSubmit`.

### REACT-RR-009 · Split large routes with `lazy`  `info`

**Why:** Importing every route component eagerly puts the whole app into the first bundle. The route object's `lazy` property loads a route's component, loader and action only when it's matched.
**Source:** https://reactrouter.com/start/data/route-object#lazy

```tsx
// ❌
import { Reports } from './routes/reports'
{ path: '/reports', Component: Reports }

// ✅
{ path: '/reports', lazy: async () => ({ Component: (await import('./routes/reports')).Reports }) }
```

**Applies:** React Router ≥ 6.4 data mode · **Exceptions:** small apps, and routes on the critical path.
