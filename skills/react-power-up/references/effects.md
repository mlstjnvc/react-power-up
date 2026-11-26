# Effects (`REACT-EFF-*`)

Effects are for **synchronizing with systems outside React**: network connections, subscriptions, timers, non-React widgets, browser APIs. Most other uses are anti-patterns. These rules follow react.dev's *You Might Not Need an Effect*. Dependency rules are in [`hooks.md`](hooks.md).

**Before writing `useEffect`, ask:** is this caused by *rendering*, or by a specific *user event*?
- If it's caused by an event, put it in the handler.
- If it can be computed from props and state, compute it during render.
- If it's data fetching and the project has TanStack Query, a router loader or React Server Components, use those (see `tanstack-query.md`, `react-router.md`, `tanstack-router.md`, `nextjs.md`).

---

### REACT-EFF-001 · Derive values during render, not in an effect  `error`

**Why:** Storing derived data in state and syncing it with an effect causes an extra render with stale values, and the two can drift apart.
**Source:** https://react.dev/learn/you-might-not-need-an-effect#updating-state-based-on-props-or-state

```tsx
// ❌
const [fullName, setFullName] = useState('')
useEffect(() => { setFullName(`${first} ${last}`) }, [first, last])

// ✅
const fullName = `${first} ${last}`
```

**Applies:** React ≥ 18 · **Exceptions:** an expensive derivation that has been measured: use `useMemo`, or nothing if React Compiler is on.

### REACT-EFF-002 · Put event-specific logic in the event handler  `error`

**Why:** An effect runs because the component *rendered*, not because the user did something. Logic triggered by a state flag (a POST after `setSubmitted(true)`, a toast after adding to the cart) re-fires on remount, on StrictMode's double-mount, or when restoring a page. The result is duplicate requests and notifications.
**Source:** https://react.dev/learn/you-might-not-need-an-effect#sharing-logic-between-event-handlers · https://react.dev/learn/you-might-not-need-an-effect#sending-a-post-request

```tsx
// ❌
const [submitted, setSubmitted] = useState(false)
useEffect(() => {
  if (submitted) void post('/api/register', { email })
}, [submitted, email])

// ✅
async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
  e.preventDefault()
  await post('/api/register', { email })
}
```

**Applies:** React ≥ 18 · **Exceptions:** work that *must* happen because the component is displayed (analytics for a page view, a connection), which is a valid effect.

### REACT-EFF-003 · Reset state with `key`, not by syncing props into state  `warn`

**Why:** Copying a prop into state and then "fixing" it in an effect when the prop changes renders once with the old value, and leaks state between items (a comment draft carried over to another user's profile). Giving the component a `key` makes React start fresh for each item.
**Source:** https://react.dev/learn/you-might-not-need-an-effect#resetting-all-state-when-a-prop-changes · https://react.dev/learn/you-might-not-need-an-effect#adjusting-some-state-when-a-prop-changes

```tsx
// ❌
function Profile({ userId }: { userId: string }) {
  const [comment, setComment] = useState('')
  useEffect(() => { setComment('') }, [userId])
  return <CommentBox value={comment} onChange={setComment} />
}

// ✅
function ProfilePage({ userId }: { userId: string }) {
  return <Profile key={userId} userId={userId} />
}
function Profile({ userId }: { userId: string }) {
  const [comment, setComment] = useState('')      // fresh for each userId
  return <CommentBox value={comment} onChange={setComment} />
}
```

**Applies:** React ≥ 18 · **Exceptions:** adjusting only *part* of the state. Prefer deriving it during render, for example by storing an id instead of the selected object.

### REACT-EFF-004 · Don't chain effects that set state to trigger each other  `warn`

**Why:** A chain of effects (A sets `x` → an effect on `x` sets `y` → an effect on `y` sets `z`) renders once per link and is hard to follow. It also breaks when one link's state is set from elsewhere. Compute what you can during render, and do the rest in the event handler that started it.
**Source:** https://react.dev/learn/you-might-not-need-an-effect#chains-of-computations

```tsx
// ❌
useEffect(() => { if (card?.gold) setGoldCount((c) => c + 1) }, [card])
useEffect(() => { if (goldCount > 3) { setRound((r) => r + 1); setGoldCount(0) } }, [goldCount])

// ✅
function placeCard(next: Card) {
  setCard(next)
  if (next.gold) {
    if (goldCount < 3) setGoldCount(goldCount + 1)
    else { setGoldCount(0); setRound(round + 1) }
  }
}
```

**Applies:** React ≥ 18 · **Exceptions:** a cascade of *network* requests where each depends on the previous response. That's a valid effect sequence, though usually better served by dependent queries (`tanstack-query.md`).

### REACT-EFF-005 · Fetching in an effect needs race handling; prefer the project's data layer  `error`

**Why:**
- A fetch effect without cleanup lets responses arrive out of order. Typing "ab" quickly can show the results for "a". Without an abort, the request also keeps running after unmount.
- Effects also give no caching, no deduplication and no SSR, and they create request waterfalls.
- When the project has TanStack Query, a router loader or Server Components, use those. Otherwise, an effect is acceptable only with an ignore flag or an `AbortController`.
**Source:** https://react.dev/learn/you-might-not-need-an-effect#fetching-data · https://react.dev/reference/react/useEffect#fetching-data-with-effects

```tsx
// ❌
useEffect(() => {
  fetch(`/api/search?q=${query}`).then((r) => r.json()).then(setResults)
}, [query])

// ✅ (no data library in the project)
useEffect(() => {
  const controller = new AbortController()
  fetch(`/api/search?q=${encodeURIComponent(query)}`, { signal: controller.signal })
    .then((r) => r.json() as Promise<unknown>)
    .then((data) => setResults(parseResults(data)))
    .catch((err: unknown) => { if (!controller.signal.aborted) setError(err) })
  return () => controller.abort()
}, [query])

// ✅ (TanStack Query in the project)
const { data: results } = useQuery({ queryKey: ['search', query], queryFn: () => searchProducts(query) })
```

**Applies:** React ≥ 18 · **Exceptions:** none for the race handling. The preference for the data layer applies only when one is installed. Never add one without asking.

### REACT-EFF-006 · Clean up every subscription, listener, timer and connection  `error`

**Why:** An effect that subscribes without returning a cleanup function leaks: the listener or interval keeps firing after unmount, calls `setState` on a gone component, and duplicates on every re-run. StrictMode's development double-mount exists to expose exactly this.
**Source:** https://react.dev/learn/synchronizing-with-effects#step-3-add-cleanup-if-needed · https://react.dev/reference/react/useEffect#connecting-to-an-external-system

```tsx
// ❌
useEffect(() => {
  setInterval(() => setNow(Date.now()), 1000)
  window.addEventListener('resize', onResize)
}, [onResize])

// ✅
useEffect(() => {
  const id = setInterval(() => setNow(Date.now()), 1000)
  return () => clearInterval(id)
}, [])
useEffect(() => {
  window.addEventListener('resize', onResize)
  return () => window.removeEventListener('resize', onResize)
}, [onResize])
```

**Applies:** React ≥ 18 · **Exceptions:** effects that start nothing long-lived (setting `document.title`, focusing an element).

### REACT-EFF-007 · Fix the cleanup instead of blocking StrictMode's second run  `warn`

**Why:** In development, StrictMode mounts, unmounts and remounts each component to prove its effects clean up. A `useRef(false)` "already ran" guard hides a missing cleanup, and the bug then appears in production on real remounts (navigation, Suspense, Activity).
**Source:** https://react.dev/learn/synchronizing-with-effects#dont-use-refs-to-prevent-effects-from-firing · https://react.dev/learn/synchronizing-with-effects#how-to-handle-the-effect-firing-twice-in-development

```tsx
// ❌
const connected = useRef(false)
useEffect(() => {
  if (connected.current) return
  connected.current = true
  createConnection(roomId).connect()
}, [roomId])

// ✅
useEffect(() => {
  const conn = createConnection(roomId)
  conn.connect()
  return () => conn.disconnect()
}, [roomId])
```

**Applies:** React ≥ 18 · **Exceptions:** one-time app initialization belongs at module scope or behind a module-level flag (react.dev: *Initializing the application*), not in a component effect.

### REACT-EFF-008 · Notify parents in the event handler, not in an effect  `warn`

**Why:** Calling `onChange(value)` from an effect after local state changes runs one render late. The parent then updates its own state, which causes a second pass, and the two can disagree in between. Call the parent's callback in the same handler that changes the state, or lift the state up.
**Source:** https://react.dev/learn/you-might-not-need-an-effect#notifying-parent-components-about-state-changes

```tsx
// ❌
const [isOn, setIsOn] = useState(false)
useEffect(() => { onChange(isOn) }, [isOn, onChange])

// ✅
function toggle() {
  const next = !isOn
  setIsOn(next)
  onChange(next)
}
// or, fully controlled: function Toggle({ isOn, onChange }: { isOn: boolean; onChange: (v: boolean) => void })
```

**Applies:** React ≥ 18 · **Exceptions:** none.
