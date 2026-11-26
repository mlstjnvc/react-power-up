# Hooks and state (`REACT-HOOK-*`)

Rules for calling hooks, declaring dependencies, updating state, refs and custom hooks. Effect-specific rules (when *not* to use an effect, cleanup, races) are in [`effects.md`](effects.md).

---

### REACT-HOOK-001 · Call hooks only at the top level  `error`

**Why:** React identifies each hook by its call order. A hook inside a condition, a loop, a nested function, or after an early `return` changes that order between renders. State then attaches to the wrong hook, or React throws "Rendered fewer hooks than expected".
**Source:** https://react.dev/reference/rules/rules-of-hooks#only-call-hooks-at-the-top-level

```tsx
// ❌
function Profile({ userId }: { userId?: string }) {
  if (!userId) return <SignInPrompt />
  const [tab, setTab] = useState('posts')          // skipped on some renders
  return <Tabs value={tab} onChange={setTab} />
}

// ✅
function Profile({ userId }: { userId?: string }) {
  const [tab, setTab] = useState('posts')
  if (!userId) return <SignInPrompt />
  return <Tabs value={tab} onChange={setTab} />
}
```

**Applies:** React ≥ 18 · **Exceptions:** `use()` (React 19) may be called conditionally and in loops.

### REACT-HOOK-002 · Call hooks only from components and custom hooks  `error`

**Why:** Hooks rely on React's render context. Called from a plain function, an event handler, a class, or module scope, they either throw or attach state to whichever component happens to be rendering.
**Source:** https://react.dev/reference/rules/rules-of-hooks#only-call-hooks-from-react-functions

```tsx
// ❌
function handleSave() {
  const user = useContext(UserContext)          // hook inside an event handler
  void save(user)
}

// ✅
function SaveButton() {
  const user = useContext(UserContext)
  return <button type="button" onClick={() => void save(user)}>Save</button>
}
```

**Applies:** React ≥ 18 · **Exceptions:** none.

### REACT-HOOK-003 · Declare every reactive value as a dependency; never suppress the linter  `error`

**Why:** Props, state and anything computed from them during render are reactive. Leaving one out of an effect's, memo's or callback's dependency array makes the hook keep using a stale value. That's a silent bug: wrong data, a missed resubscription, or a stale closure in a timer. `// eslint-disable-next-line react-hooks/exhaustive-deps` hides exactly that bug.
**Source:** https://react.dev/learn/lifecycle-of-reactive-effects#react-verifies-that-you-specified-every-reactive-value-as-a-dependency · https://react.dev/learn/removing-effect-dependencies#why-is-suppressing-the-dependency-linter-so-dangerous

```tsx
// ❌
useEffect(() => {
  const conn = createConnection(roomId)
  conn.connect()
  return () => conn.disconnect()
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, [])                                            // never reconnects when roomId changes

// ✅
useEffect(() => {
  const conn = createConnection(roomId)
  conn.connect()
  return () => conn.disconnect()
}, [roomId])
```

**Applies:** React ≥ 18 · **Exceptions:**
- Values React guarantees are stable may be omitted: `setState` functions, `dispatch`, and refs.
- To read a value *without* reacting to it, use `useEffectEvent` (React ≥ 19.2; see REACT-HOOK-004) instead of removing it from the array.

### REACT-HOOK-004 · Read non-reactive values with `useEffectEvent`, not by dropping dependencies  `warn`

**Why:** Sometimes an effect should re-run for one value (`roomId`) but only *read* another (`theme`, `onMessage`). Leaving the second out of the dependencies leaves it stale (REACT-HOOK-003). Including it re-runs the effect needlessly. `useEffectEvent` separates the two: code inside an Effect Event always sees the latest values without being a dependency.
**Source:** https://react.dev/reference/react/useEffectEvent · https://react.dev/learn/removing-effect-dependencies#do-you-want-to-read-a-value-without-reacting-to-its-changes

```tsx
// ❌
useEffect(() => {
  const conn = createConnection(roomId)
  conn.on('connected', () => showNotification('Connected', theme))
  conn.connect()
  return () => conn.disconnect()
}, [roomId, theme])                               // reconnects when the theme changes

// ✅ (React ≥ 19.2)
const onConnected = useEffectEvent(() => showNotification('Connected', theme))
useEffect(() => {
  const conn = createConnection(roomId)
  conn.on('connected', () => onConnected())
  conn.connect()
  return () => conn.disconnect()
}, [roomId])
```

**Applies:** React ≥ 19.2. Below 19.2, keep the value in the dependencies, or store it in a ref that's updated in an effect · **Exceptions:** Effect Events may only be called from inside effects. Never pass them to children, and never list them as dependencies.

### REACT-HOOK-005 · Keep hook dependencies stable: no objects or functions created during render  `warn`

**Why:** An object, array or function created in the component body is new on every render. As a dependency, it makes the effect or memo re-run after every render, which can mean a reconnect loop or an infinite fetch loop. Move it outside the component, inside the effect, or depend on its primitive fields.
**Source:** https://react.dev/learn/removing-effect-dependencies#does-some-reactive-value-change-unintentionally

```tsx
// ❌
const options = { serverUrl, roomId }             // new object each render
useEffect(() => {
  const conn = createConnection(options)
  conn.connect()
  return () => conn.disconnect()
}, [options])                                      // reconnects on every render

// ✅
useEffect(() => {
  const conn = createConnection({ serverUrl, roomId })
  conn.connect()
  return () => conn.disconnect()
}, [serverUrl, roomId])
```

**Applies:** React ≥ 18 · **Exceptions:** with React Compiler on, values the compiler memoizes are stable. Still prefer primitive dependencies for effects.

### REACT-HOOK-006 · Never mutate state; replace objects and arrays  `error`

**Why:** React compares state by reference. Mutating an object or array and setting the same reference skips the re-render. Mutating without setting corrupts the previous render's snapshot, which breaks memoized children and transitions.
**Source:** https://react.dev/learn/updating-objects-in-state#treat-state-as-read-only · https://react.dev/reference/react/useState#updating-objects-and-arrays-in-state

```tsx
// ❌
function addTodo(text: string) {
  todos.push({ id: crypto.randomUUID(), text })
  setTodos(todos)                                 // same reference: no re-render
}

// ✅
function addTodo(text: string) {
  setTodos((prev) => [...prev, { id: crypto.randomUUID(), text }])
}
```

**Applies:** React ≥ 18 · **Exceptions:** mutating a fresh local copy before setting it ("local mutation is fine"); Immer-style producers (`useImmer`, RTK's `createSlice`), which mutate drafts.

### REACT-HOOK-007 · Use the updater form when the next state depends on the previous one  `warn`

**Why:** `setCount(count + 1)` uses the `count` from *this render*. Several updates in one event, or an update in an async callback or a timer, then work from a stale value and lose increments. `setCount((c) => c + 1)` always applies to the latest state.
**Source:** https://react.dev/reference/react/useState#updating-state-based-on-the-previous-state

```tsx
// ❌
function addThree() {
  setCount(count + 1)
  setCount(count + 1)
  setCount(count + 1)                             // count only goes up by 1
}

// ✅
function addThree() {
  setCount((c) => c + 1)
  setCount((c) => c + 1)
  setCount((c) => c + 1)
}
```

**Applies:** React ≥ 18 · **Exceptions:** a single update in a synchronous event handler, where both forms behave the same. Follow the project's convention there.

### REACT-HOOK-008 · Pass an initializer function for expensive initial state  `warn`

**Why:** `useState(buildIndex(items))` runs `buildIndex` on **every** render and throws the result away after the first. Passing the function (`useState(() => buildIndex(items))`) runs it once.
**Source:** https://react.dev/reference/react/useState#avoiding-recreating-the-initial-state

```tsx
// ❌
const [index, setIndex] = useState(buildSearchIndex(items))
const [draft, setDraft] = useState(JSON.parse(localStorage.getItem('draft') ?? '{}'))

// ✅
const [index, setIndex] = useState(() => buildSearchIndex(items))
const [draft, setDraft] = useState(() => readDraft()) // readDraft parses and validates
```

**Applies:** React ≥ 18 · **Exceptions:** cheap initial values (literals, props). In SSR, never read `localStorage` during render at all; read it in an effect (see `nextjs.md`).

### REACT-HOOK-009 · Name custom hooks `use*`, and only functions that call hooks  `warn`

**Why:** The `use` prefix is how React's linter and React Compiler know a function follows the Rules of Hooks. Without it, hook calls inside go unchecked. With it, but no hooks inside, a plain function gets restrictions it doesn't need: it can't be called conditionally.
**Source:** https://react.dev/learn/reusing-logic-with-custom-hooks#hook-names-always-start-with-use

```tsx
// ❌
function onlineStatus() { return useSyncExternalStore(subscribe, getSnapshot) }   // hook without use*
function useSortedItems(items: Item[]) { return items.toSorted(byName) }           // use* without hooks

// ✅
function useOnlineStatus() { return useSyncExternalStore(subscribe, getSnapshot) }
function sortItems(items: Item[]) { return items.toSorted(byName) }
```

**Applies:** React ≥ 18 · **Exceptions:** none.

### REACT-HOOK-010 · Subscribe to external stores with `useSyncExternalStore`  `warn`

**Why:** Mirroring a browser API or a third-party store into state with `useEffect` + `setState` renders a stale value first, can tear during concurrent rendering, and needs hand-written cleanup. `useSyncExternalStore` reads a consistent snapshot, and takes a server snapshot for SSR.
**Source:** https://react.dev/reference/react/useSyncExternalStore · https://react.dev/learn/you-might-not-need-an-effect#subscribing-to-an-external-store

```tsx
// ❌
const [online, setOnline] = useState(true)
useEffect(() => {
  const update = () => setOnline(navigator.onLine)
  window.addEventListener('online', update)
  window.addEventListener('offline', update)
  return () => { window.removeEventListener('online', update); window.removeEventListener('offline', update) }
}, [])

// ✅
function subscribe(cb: () => void) {
  window.addEventListener('online', cb)
  window.addEventListener('offline', cb)
  return () => { window.removeEventListener('online', cb); window.removeEventListener('offline', cb) }
}
export function useOnlineStatus() {
  return useSyncExternalStore(subscribe, () => navigator.onLine, () => true)
}
```

**Applies:** React ≥ 18 · **Exceptions:** the library ships its own hook (Zustand, Redux, TanStack Query), so use that instead.

### REACT-HOOK-011 · Don't read or write `ref.current` during render  `warn`

**Why:** Refs are an escape hatch for values that don't affect rendering. Reading `ref.current` in JSX shows a value React doesn't know changed, so the screen goes stale. Writing it during render breaks purity under StrictMode and concurrent rendering. Use state for anything shown on screen.
**Source:** https://react.dev/reference/react/useRef#referencing-a-value-with-a-ref

```tsx
// ❌
const clicks = useRef(0)
return <button type="button" onClick={() => { clicks.current++ }}>Clicked {clicks.current} times</button>

// ✅
const [clicks, setClicks] = useState(0)
return <button type="button" onClick={() => setClicks((c) => c + 1)}>Clicked {clicks} times</button>
```

**Applies:** React ≥ 18 · **Exceptions:** lazy one-time initialization (`if (ref.current === null) ref.current = createThing()`); reading or writing refs in event handlers and effects, which is the intended use.
