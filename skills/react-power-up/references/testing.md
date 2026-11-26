# Testing (`REACT-TEST-*`)

Rules for component and hook tests with **Vitest** (Jest notes inline), **React Testing Library** (RTL), **user-event** and **MSW** (v3 primary, v2 noted). Use the project's existing runner and libraries. If there's no test setup, offer one, and don't install anything unasked (SKILL.md step 6).

**What to test:** what the user sees and does. Render the component, interact the way a user would, and assert on the screen (roles, labels, text), not on internal state.

---

### REACT-TEST-001 · Query by role, label or text; `getByTestId` is the last resort  `warn`

**Why:** Queries that mirror how users and assistive technology find elements (`getByRole('button', { name: 'Save' })`, `getByLabelText('Email')`) survive refactors and double as accessibility checks. Test ids and CSS selectors couple tests to markup, and pass even when the control has no accessible name.
**Source:** https://testing-library.com/docs/queries/about#priority

```tsx
// ❌
expect(container.querySelector('.submit-btn')).toBeDisabled()
await user.type(screen.getByTestId('email'), 'a@b.co')

// ✅
await user.type(screen.getByLabelText('Email'), 'a@b.co')
expect(screen.getByRole('button', { name: 'Sign in' })).toBeEnabled()
```

**Applies:** `@testing-library/react` ≥ 13 · **Exceptions:** elements with no accessible role or text (a canvas chart), which may use `data-testid`.

### REACT-TEST-002 · Interact with `user-event`, not `fireEvent`  `warn`

**Why:** `fireEvent.change` dispatches one synthetic event. `user-event` simulates what a browser does for a real interaction: focus, keydown/keypress/input/keyup per character, pointer events, and checks that the element is visible and enabled. Tests with `fireEvent` pass on things a user couldn't actually do. Create the user with `userEvent.setup()`, and `await` every call.
**Source:** https://testing-library.com/docs/user-event/intro#differences-from-fireevent

```tsx
// ❌
fireEvent.change(screen.getByLabelText('Quantity'), { target: { value: '3' } })
fireEvent.click(screen.getByRole('button', { name: 'Add' }))

// ✅
const user = userEvent.setup()
render(<AddToCart productId="p1" />)
await user.clear(screen.getByLabelText('Quantity'))
await user.type(screen.getByLabelText('Quantity'), '3')
await user.click(screen.getByRole('button', { name: 'Add' }))
```

**Applies:** `@testing-library/user-event` ≥ 14 · **Exceptions:** events user-event doesn't model (custom events, `scroll`), which use `fireEvent`.

### REACT-TEST-003 · Wait for async UI with `findBy*`/`waitFor`, never fixed sleeps  `warn`

**Why:** `await new Promise((r) => setTimeout(r, 500))` is flaky in both directions: too short on a slow CI machine, wasted time everywhere else. `findBy*` queries retry until the element appears or a timeout passes. `waitFor` retries an assertion, and `waitForElementToBeRemoved` waits for spinners to go away.
**Source:** https://testing-library.com/docs/dom-testing-library/api-async#findby-queries · https://testing-library.com/docs/dom-testing-library/api-async#waitfor

```tsx
// ❌
render(<OrdersTable />)
await new Promise((r) => setTimeout(r, 1000))
expect(screen.getByText('Order #1001')).toBeInTheDocument()

// ✅
render(<OrdersTable />)
expect(await screen.findByText('Order #1001')).toBeInTheDocument()
```

**Applies:** `@testing-library/react` ≥ 13 · **Exceptions:** code driven by timers, which uses fake timers (`vi.useFakeTimers()`, with `userEvent.setup({ advanceTimers: vi.advanceTimersByTime })`) instead of real waits.

### REACT-TEST-004 · Assert on behaviour, not implementation details  `warn`

**Why:** Tests that inspect a component's state, call its internal functions, or assert that a child component rendered with certain props break on every refactor and miss real bugs (the state is right, but nothing appears on screen). Assert on what the user sees: text, roles, enabled/disabled state, navigation, and calls that cross the boundary (network requests, callbacks passed in).
**Source:** https://testing-library.com/docs/guiding-principles

```tsx
// ❌
const { result } = renderHook(() => useCart())
act(() => result.current.add(item))
expect(result.current.items).toHaveLength(1)                      // (only valid for testing the hook itself)
expect(mockCartBadge).toHaveBeenCalledWith({ count: 1 })           // asserting child props

// ✅
const user = userEvent.setup()
render(<ProductPage product={item} />)
await user.click(screen.getByRole('button', { name: 'Add to cart' }))
expect(screen.getByRole('status')).toHaveTextContent('1 item in cart')
```

**Applies:** any runner · **Exceptions:** testing a custom hook's contract with `renderHook` (the hook *is* the unit); callback props passed in by the test (`onSubmit` mocks), which are the component's public interface.

### REACT-TEST-005 · Mock the network with MSW handlers, not by stubbing `fetch` per test  `warn`

**Why:** `vi.spyOn(global, 'fetch').mockResolvedValue(…)` couples each test to how the code calls `fetch` (URL format, init object, `res.json()` vs `res.text()`), and breaks as soon as the code switches to another client. MSW intercepts at the network level, so the same handlers work for `fetch`, axios, TanStack Query and Server-side code, and tests read like the API contract.
- **MSW 3:** request handlers come from `msw/http`, and the Node server from `msw/node`. MSW 3 also requires Node ≥ 22.
- **MSW 2:** the same APIs are imported from `msw`.
**Source:** https://mswjs.io/docs/quick-start · https://mswjs.io/docs/migrations/2.x-to-3.x#imports

```ts
// ❌
vi.spyOn(globalThis, 'fetch').mockResolvedValue(new Response(JSON.stringify([{ id: 'o1' }])))

// ✅ src/test/server.ts
import { http, HttpResponse } from 'msw/http'          // MSW 2: from 'msw'
import { setupServer } from 'msw/node'
export const server = setupServer(
  http.get('/api/orders', () => HttpResponse.json({ orders: [{ id: 'o1', customer: 'Ada', total: 42, status: 'open' }], page: 1, pageCount: 1 })),
)
// per test: server.use(http.get('/api/orders', () => new HttpResponse(null, { status: 500 })))
```

**Applies:** MSW ≥ 2 (entry points as noted); only when MSW is in the project. Never add it unasked · **Exceptions:** pure functions that take an injected client, which can receive a fake directly.

### REACT-TEST-006 · Isolate tests: a fresh `QueryClient` (no retries) and fresh stores, and reset MSW handlers after each test  `warn`

**Why:**
- A `QueryClient` shared across tests carries cached data from one test into the next, so results depend on test order.
- Default retries (3, with backoff) make every error-state test wait several seconds, and then time out.
- Global stores (Zustand, Redux) leak state between tests the same way.
- Per-test MSW overrides (`server.use`) leak unless reset.
- Fail on requests no handler covers, so a typo'd URL can't silently hit the real network. In MSW 3 that option is `onUnhandledFrame` (renamed from v2's `onUnhandledRequest`).
**Source:** https://tanstack.com/query/latest/docs/framework/react/guides/testing#turn-off-retries · https://mswjs.io/docs/api/setup-server/listen#onunhandledframe · https://mswjs.io/docs/migrations/2.x-to-3.x#onunhandledrequest

```tsx
// ❌
const queryClient = new QueryClient()                              // module scope, retries on, shared
const wrapper = ({ children }: { children: React.ReactNode }) => <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>

// ✅ src/test/utils.tsx
export function renderWithClient(ui: React.ReactElement) {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
}
// src/test/setup.ts
beforeAll(() => server.listen({ onUnhandledFrame: 'error' }))      // MSW 2: { onUnhandledRequest: 'error' }
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

**Applies:** TanStack Query ≥ 4, MSW ≥ 2, any store · **Exceptions:** none.

### REACT-TEST-007 · Render routed components inside a router (and their providers)  `warn`

**Why:** Components that use `Link`, `useNavigate`, `useLoaderData` or `useSearchParams` throw outside a router. Mocking the router hooks hides real behaviour. Render them in a test router:
- **React Router:** `createRoutesStub` (data mode), or `createMemoryRouter` / `<MemoryRouter>`.
- **TanStack Router:** a test router with `createMemoryHistory`.
- **Next.js:** mock `next/navigation` hooks only at that boundary.
**Source:** https://reactrouter.com/start/data/testing

```tsx
// ❌
vi.mock('react-router', () => ({ useNavigate: () => vi.fn(), useLoaderData: () => ({ id: 'p1' }) }))

// ✅ (React Router v7/v8)
const Stub = createRoutesStub([{ path: '/projects/:id', Component: ProjectPage, loader: () => ({ id: 'p1', name: 'Apollo' }) }])
render(<Stub initialEntries={['/projects/p1']} />)
expect(await screen.findByRole('heading', { name: 'Apollo' })).toBeInTheDocument()
```

**Applies:** React Router ≥ 7 (`createRoutesStub`), TanStack Router ≥ 1 · **Exceptions:** presentational components that don't use router APIs.

### REACT-TEST-008 · Next.js: unit-test synchronous components and Server Action functions; cover async Server Components with E2E  `info`

**Why:** Vitest and RTL don't support rendering **async** Server Components, as the Next.js testing guide states. Don't contort them into unit tests. Test the pieces that are testable: the data and validation functions they call, Server Actions as plain async functions (with the session and DB mocked at their boundary), and client components with RTL. Cover the full page with an E2E test (e.g. Playwright, if the project has it).
**Source:** https://nextjs.org/docs/app/guides/testing/vitest

```ts
// ❌ render(<OrderPage params={Promise.resolve({ id: 'o1' })} />)   // async Server Component in RTL

// ✅
vi.mock('@/lib/auth', () => ({ getCurrentUser: vi.fn().mockResolvedValue(null) }))
test('rejects unauthenticated updates', async () => {
  await expect(updateQuantity({ itemId: crypto.randomUUID(), qty: 2 })).rejects.toThrow('Unauthorized')
})
```

**Applies:** Next.js ≥ 13.4 App Router · **Exceptions:** synchronous Server Components, which render fine in RTL.

### REACT-TEST-009 · Don't wrap RTL calls in `act()` yourself  `info`

**Why:** `render`, `fireEvent`, `user-event` and the async utilities already wrap their work in `act()`. Wrapping them again adds noise and hides the real cause of an "update not wrapped in act" warning, which is usually an async update nobody waited for. Fix it with `await screen.findBy…`/`waitFor`. When you do need `act` directly, import it from `@testing-library/react` (RTL recommends that over `react`). Never import it from `react-dom/test-utils`, which React 19 removed.
**Source:** https://testing-library.com/docs/react-testing-library/api#act · https://react.dev/blog/2024/04/25/react-19-upgrade-guide#removed-react-dom-test-utils

```tsx
// ❌
await act(async () => { render(<Profile />) })
await act(async () => { await user.click(screen.getByRole('button', { name: 'Save' })) })

// ✅
render(<Profile />)
await user.click(screen.getByRole('button', { name: 'Save' }))
expect(await screen.findByText('Saved')).toBeInTheDocument()
```

**Applies:** `@testing-library/react` ≥ 13 · **Exceptions:** driving fake timers or a custom external store outside RTL's utilities, where `act()` is needed.

### REACT-TEST-010 · Register RTL `cleanup` when the runner has no global `afterEach`  `warn`

**Why:** RTL unmounts rendered trees after each test only when the runner injects a global `afterEach` (Jest, Mocha, Jasmine). Vitest doesn't unless `globals: true` is set. Without it, every `render` stays mounted: later tests see earlier trees ("Found multiple elements…"), pass or fail depending on order, and leak memory. Before writing tests, check `vitest.config.*` for `globals: true` and the setup files for `cleanup`. If neither is there, add `afterEach(() => cleanup())` to the existing setup file (a single top-level hook covers every test file). Don't switch on `globals` just for this: it changes the project's test config and its TS types.
**Source:** https://testing-library.com/docs/react-testing-library/setup#auto-cleanup-in-vitest · https://testing-library.com/docs/react-testing-library/api#cleanup

```tsx
// ❌ vitest.config.ts has no `globals: true`, and the setup never cleans up
// src/test/setup.ts
import '@testing-library/jest-dom/vitest'
import { afterAll, afterEach, beforeAll } from 'vitest'
beforeAll(() => server.listen({ onUnhandledFrame: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

// ✅
import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterAll, afterEach, beforeAll } from 'vitest'
beforeAll(() => server.listen({ onUnhandledFrame: 'error' }))
afterEach(() => {
  cleanup()
  server.resetHandlers()
})
afterAll(() => server.close())
```

**Applies:** Vitest (any version) without `globals: true`, or any runner with no global `afterEach` · **Exceptions:** Jest, or Vitest with `globals: true`, where cleanup is automatic. The same goes for a project that deliberately sets `RTL_SKIP_AUTO_CLEANUP` and manages cleanup itself.
