# State: where it lives, Zustand, Redux Toolkit (`REACT-STATE-*`)

Rules for choosing where state lives, and for using Zustand and Redux Toolkit correctly. Component-local state rules (`useState`, updaters, no mutation) are in [`hooks.md`](hooks.md). Server data is in [`tanstack-query.md`](tanstack-query.md).

**Where does this state live?** Pick the first level that fits:
1. **Derived:** computed during render, not stored.
2. **Local:** `useState`/`useReducer` in the component that uses it.
3. **Lifted:** in the closest common parent.
4. **URL:** filters, sort, pagination, selected tab, search text. Anything a user would share or bookmark.
5. **Server cache:** data that comes from an API (TanStack Query, RTK Query, router loaders, RSC).
6. **Context:** rarely-changing values many components need (theme, locale, current user).
7. **Client store:** shared, frequently-updated client state (Zustand or Redux Toolkit, whichever the project already uses).

---

### REACT-STATE-001 · Don't store what you can derive  `warn`

**Why:** A stored copy of something computable from other state (a `total` next to `items`, a `selectedItem` object next to `selectedId`) has to be kept in sync by hand, and it drifts. This applies to `useState`, Zustand and Redux alike: store the minimal state, and derive the rest during render or in a selector.
**Source:** https://react.dev/learn/choosing-the-state-structure#avoid-redundant-state · https://redux.js.org/style-guide/#keep-state-minimal-and-derive-additional-values

```tsx
// ❌
const useCart = create<CartState>()((set) => ({
  items: [],
  total: 0,
  add: (item) => set((s) => ({ items: [...s.items, item], total: s.total + item.price })),
}))

// ✅
const useCart = create<CartState>()((set) => ({
  items: [],
  add: (item) => set((s) => ({ items: [...s.items, item] })),
}))
const selectTotal = (s: CartState) => s.items.reduce((sum, i) => sum + i.price, 0)
const total = useCart(selectTotal)
```

**Applies:** React ≥ 18, Zustand ≥ 4, Redux Toolkit ≥ 1.9 · **Exceptions:** a measured-expensive derivation. Memoize it in a selector (`createSelector`, or `useMemo` without React Compiler) rather than storing it.

### REACT-STATE-002 · Keep server data in a server cache, not a client store  `warn`

**Why:** Copying API responses into Zustand or Redux means hand-writing loading flags, error state, refetching, deduplication and invalidation, and the copy goes stale. A server cache (TanStack Query, RTK Query, loaders, RSC) does all of that. Client stores are for client state.
**Source:** https://redux.js.org/style-guide/#use-rtk-query-for-data-fetching · https://tanstack.com/query/latest/docs/framework/react/guides/does-this-replace-client-state

```tsx
// ❌
const useProducts = create<ProductsState>()((set) => ({
  products: [], loading: false,
  load: async () => { set({ loading: true }); set({ products: await fetchProducts(), loading: false }) },
}))

// ✅ (TanStack Query in the project)
const { data: products, isPending } = useQuery({ queryKey: ['products'], queryFn: fetchProducts })
```

**Applies:** any project with a server-cache library installed · **Exceptions:** no data library installed. Then a store with proper loading and error state is acceptable. Mention the option, but never add a dependency unasked.

### REACT-STATE-003 · Zustand: select the slice you use; never subscribe to the whole store  `warn`

**Why:** `const store = useStore()` with no selector re-renders the component on **every** store change, including fields it doesn't use. Selecting just what's needed (`useStore((s) => s.count)`) re-renders only when that value changes.
**Source:** https://zustand.docs.pmnd.rs/learn/guides/beginner-typescript#selectors

```tsx
// ❌
const { count, increment } = useCounterStore()

// ✅
const count = useCounterStore((s) => s.count)
const increment = useCounterStore((s) => s.increment)
```

**Applies:** Zustand ≥ 4 · **Exceptions:** a component that genuinely renders the whole state.

### REACT-STATE-004 · Zustand v5: wrap selectors that return new objects or arrays in `useShallow`  `error`

**Why:** A selector that builds a new object or array (`(s) => ({ a: s.a, b: s.b })`, `(s) => s.items.filter(…)`) returns a new reference on every call. In Zustand v5 that causes "Maximum update depth exceeded" (an infinite render loop). In v4 it causes a re-render on every store change. `useShallow` compares the result shallowly.
**Source:** https://zustand.docs.pmnd.rs/learn/guides/prevent-rerenders-with-use-shallow · https://zustand.docs.pmnd.rs/reference/migrations/migrating-to-v5#requiring-stable-selector-outputs

```tsx
// ❌
const { count, increment } = useCounterStore((s) => ({ count: s.count, increment: s.increment }))

// ✅
import { useShallow } from 'zustand/react/shallow'
const { count, increment } = useCounterStore(useShallow((s) => ({ count: s.count, increment: s.increment })))
```

**Applies:** Zustand ≥ 4.4 (`useShallow`); the infinite loop is v5 behaviour · **Exceptions:** selectors that return a primitive or an existing reference from state.

### REACT-STATE-005 · Zustand: type stores with the curried `create<T>()(…)` form; keep actions in the store  `warn`

**Why:** In TypeScript, `create<T>()(…)` (note the extra `()`) is the documented form that lets middleware types infer correctly. Keeping actions next to the state they update, and updating through `set` (with the updater form when the next state depends on the previous one), keeps every state change in one place.
**Source:** https://zustand.docs.pmnd.rs/learn/guides/beginner-typescript#creating-a-store-with-state--actions · https://zustand.docs.pmnd.rs/learn/guides/flux-inspired-practice#colocate-store-actions

```tsx
// ❌
const useCounterStore = create((set) => ({ count: 0 }))       // untyped
// … in a component:
useCounterStore.setState({ count: useCounterStore.getState().count + 1 })

// ✅
interface CounterState { count: number; increment: () => void; reset: () => void }
export const useCounterStore = create<CounterState>()((set) => ({
  count: 0,
  increment: () => set((s) => ({ count: s.count + 1 })),
  reset: () => set({ count: 0 }),
}))
```

**Applies:** Zustand ≥ 4, TypeScript ≥ 5 · **Exceptions:** the "no store actions" pattern (module-level functions calling `setState`), which Zustand documents as an alternative. Follow it if the project already does.

### REACT-STATE-006 · Next.js (and any SSR): create the store per request, not at module scope  `error`

**Why:** On the server, a module-scope store (`export const useStore = create(…)`, or `export const store = configureStore(…)`) is **shared by every request**. One user's data can be rendered into another user's page. Create the store inside a client provider (once per request on the server, once per tab in the browser) and pass it down through context.
**Source:** https://zustand.docs.pmnd.rs/learn/guides/nextjs#creating-a-store-per-request · https://redux.js.org/usage/nextjs#creating-a-redux-store-per-request

```tsx
// ❌ (Next.js App Router)
export const store = configureStore({ reducer: { cart: cartReducer } })   // module scope: shared across requests

// ✅
'use client'
export const makeStore = () => configureStore({ reducer: { cart: cartReducer } })
export type AppStore = ReturnType<typeof makeStore>
export function StoreProvider({ children }: { children: React.ReactNode }) {
  const storeRef = useRef<AppStore | null>(null)
  if (storeRef.current === null) storeRef.current = makeStore()
  return <Provider store={storeRef.current}>{children}</Provider>
}
```

**Applies:** Next.js App Router, or any SSR setup; Zustand ≥ 4 (`createStore` from `zustand/vanilla` + context), Redux Toolkit ≥ 2 · **Exceptions:** client-only SPAs (Vite), where a module-scope store is fine.

### REACT-STATE-007 · Redux: write reducers with `createSlice`; never hand-write action types and switch reducers  `warn`

**Why:** Redux Toolkit is the official way to write Redux. `createSlice` generates the action creators and types, and lets you write "mutating" updates safely through Immer. Hand-written `switch` reducers and string constants are legacy boilerplate where typos and accidental mutations slip in.
**Source:** https://redux.js.org/style-guide/#use-redux-toolkit-for-writing-redux-logic · https://redux-toolkit.js.org/api/createSlice

```tsx
// ❌
const ADD = 'cart/add'
function cartReducer(state: CartSliceState = { items: [] }, action: { type: string; payload: Item }) {
  switch (action.type) { case ADD: return { items: [...state.items, action.payload] }; default: return state }
}

// ✅
const cartSlice = createSlice({
  name: 'cart',
  initialState: { items: [] } as CartSliceState,
  reducers: {
    added(state, action: PayloadAction<Item>) { state.items.push(action.payload) },   // Immer draft
    removed(state, action: PayloadAction<string>) { state.items = state.items.filter((i) => i.id !== action.payload) },
  },
})
export const { added, removed } = cartSlice.actions
export default cartSlice.reducer
```

**Applies:** Redux Toolkit ≥ 1.9 · **Exceptions:** none for new code. Legacy reducers are migrated only when the task touches them.

### REACT-STATE-008 · Redux: use typed hooks (`useAppSelector`, `useAppDispatch`)  `warn`

**Why:** Plain `useSelector`/`useDispatch` don't know the store's types, so every call needs `(state: RootState)` annotations, and `dispatch` can't accept thunks without a cast. Define pre-typed hooks once with `.withTypes<…>()` and use them everywhere.
**Source:** https://redux.js.org/tutorials/typescript-quick-start#define-typed-hooks

```tsx
// ❌
const items = useSelector((state: any) => state.cart.items)

// ✅ (src/store/hooks.ts)
export const useAppDispatch = useDispatch.withTypes<AppDispatch>()
export const useAppSelector = useSelector.withTypes<RootState>()
// in a component
const items = useAppSelector((s) => s.cart.items)
```

**Applies:** React Redux ≥ 9.1 (`.withTypes`). On older versions, use `TypedUseSelectorHook` · **Exceptions:** none.

### REACT-STATE-009 · Redux: keep state and actions serializable  `error`

**Why:** Class instances, `Date`, `Map`/`Set`, promises and functions in Redux state or actions break the DevTools and time travel, persistence and SSR hydration, and RTK's serializability middleware warns about them. Store plain data: ISO strings, arrays and records.
**Source:** https://redux.js.org/style-guide/#do-not-put-non-serializable-values-in-state-or-actions

```tsx
// ❌
reducers: { loggedIn(state, action: PayloadAction<{ user: User; at: Date }>) { state.session = action.payload } }

// ✅
reducers: { loggedIn(state, action: PayloadAction<{ userId: string; at: string }>) { state.session = action.payload } }
// dispatch(loggedIn({ userId: user.id, at: new Date().toISOString() }))
```

**Applies:** Redux Toolkit ≥ 1.9 · **Exceptions:** none. Values that can't be serialized belong outside the store, in a ref, module or service.

### REACT-STATE-010 · Keep URL-worthy state in the URL  `warn`

**Why:** Filters, sort order, pagination and search text kept in local state are lost on reload, can't be shared or bookmarked, and break the back button. Put them in search params with the project's router (`useSearchParams`, TanStack Router `validateSearch`, Next.js `searchParams`), and validate them when you read them.
**Source:** https://redux.js.org/style-guide/#evaluate-where-each-piece-of-state-should-live · https://react.dev/learn/sharing-state-between-components

```tsx
// ❌
const [page, setPage] = useState(1)
const [status, setStatus] = useState<'all' | 'open'>('all')

// ✅ (React Router; see react-router.md / tanstack-router.md / nextjs.md for the others)
const [params, setParams] = useSearchParams()
const page = Math.max(1, Number(params.get('page')) || 1)
const status = params.get('status') === 'open' ? 'open' : 'all'
```

**Applies:** any project with a router · **Exceptions:** transient UI state (an open dropdown, hover, an unsaved draft).
