# Component design (`REACT-COMP-*`)

Rules for how components are defined, composed and wired together: purity, props, inputs, context, refs, error boundaries and Suspense. Typing rules are in [`typescript.md`](typescript.md).

---

### REACT-COMP-001 · Never define a component inside another component  `error`

**Why:** A component defined in a parent's body is a new function on every render. React sees a different component type at that position and remounts it, so its state, focus and DOM reset on every parent render. It's also slower.
**Source:** https://react.dev/learn/preserving-and-resetting-state#different-components-at-the-same-position-reset-state

```tsx
// ❌
export function Form() {
  const [name, setName] = useState('')
  function Field() {                    // new type each render: input loses focus
    return <input value={name} onChange={(e) => setName(e.currentTarget.value)} />
  }
  return <Field />
}

// ✅
function Field({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return <input value={value} onChange={(e) => onChange(e.currentTarget.value)} />
}
export function Form() {
  const [name, setName] = useState('')
  return <Field value={name} onChange={setName} />
}
```

**Applies:** React ≥ 18 · **Exceptions:** none. A render helper called as a function (`{renderRow(item)}`) is not a component, and isn't affected.

### REACT-COMP-002 · Treat props as read-only  `error`

**Why:** Props belong to the parent. Mutating a prop object or array changes the parent's data behind React's back: the parent doesn't re-render, memoized values go stale, and the bug shows up far from its cause.
**Source:** https://react.dev/reference/rules/components-and-hooks-must-be-pure#props

```tsx
// ❌
function SortedList({ items }: { items: Item[] }) {
  items.sort(byName)                    // mutates the parent's array
  return <List items={items} />
}

// ✅
function SortedList({ items }: { items: Item[] }) {
  const sorted = items.toSorted(byName) // or [...items].sort(byName)
  return <List items={sorted} />
}
```

**Applies:** React ≥ 18 (`toSorted` needs an ES2023 lib target; otherwise copy and sort) · **Exceptions:** none.

### REACT-COMP-003 · Keep rendering pure: no side effects during render  `error`

**Why:** React may render a component more than once, render it without committing, or (with StrictMode) render it twice on purpose. Work done during render (requests, subscriptions, writes to module variables, `localStorage`, analytics calls) runs an unpredictable number of times and breaks concurrent rendering.
**Source:** https://react.dev/reference/rules/components-and-hooks-must-be-pure#side-effects-must-run-outside-of-render

```tsx
// ❌
let renderCount = 0
function Page({ id }: { id: string }) {
  renderCount++
  fetch(`/api/track?page=${id}`)        // fires on every render
  return <h1>Page {id}</h1>
}

// ✅
function Page({ id }: { id: string }) {
  useEffect(() => {
    void fetch(`/api/track?page=${encodeURIComponent(id)}`)
  }, [id])
  return <h1>Page {id}</h1>
}
```

**Applies:** React ≥ 18 · **Exceptions:** creating local objects and variables during render, which is fine. Lazy one-time initialization of a ref (`if (ref.current === null) ref.current = …`).

### REACT-COMP-004 · An input is either controlled or uncontrolled, never both  `error`

**Why:**
- `value` without `onChange` makes a read-only input that silently ignores typing.
- A `value` that starts as `undefined` and later becomes a string switches the input from uncontrolled to controlled, which React warns about and which loses user input.
- Controlled means `value` + `onChange`, always defined. Uncontrolled means `defaultValue`, read on submit.
**Source:** https://react.dev/reference/react-dom/components/input#controlling-an-input-with-a-state-variable · https://react.dev/reference/react-dom/components/input#im-getting-an-error-a-component-is-changing-an-uncontrolled-input-to-be-controlled

```tsx
// ❌
const [email, setEmail] = useState<string>()          // undefined at first
<input value={email} onChange={(e) => setEmail(e.currentTarget.value)} />
<input value={name} />                                // no onChange: read-only

// ✅
const [email, setEmail] = useState('')
<input value={email} onChange={(e) => setEmail(e.currentTarget.value)} />
<input name="name" defaultValue={user.name} />        // uncontrolled, read on submit
```

**Applies:** React ≥ 18 · **Exceptions:** a deliberately read-only input, which uses `readOnly`.

### REACT-COMP-005 · Prefer composition over deep prop drilling; use context for widely shared data  `warn`

**Why:** Threading a prop through layers that don't use it couples every layer to data it doesn't care about. Passing JSX as `children` (or as named element props) often removes the drilling entirely. Context is for data many components at different depths need (theme, current user, locale). Reaching for context first hides data flow.
**Source:** https://react.dev/learn/passing-data-deeply-with-context#before-you-use-context

```tsx
// ❌
<Layout user={user}><Sidebar user={user}><Nav user={user} /></Sidebar></Layout>

// ✅
<Layout sidebar={<Sidebar nav={<Nav user={user} />} />} />
```

**Applies:** React ≥ 18 · **Exceptions:** one or two levels of explicit props, which is fine and often the clearest option.

### REACT-COMP-006 · Keep context values stable; split contexts that change at different rates  `warn`

**Why:** Every consumer re-renders when the context value changes identity. An object literal (`value={{ user, logout }}`) is new on every provider render, so every consumer re-renders even when nothing changed. Mixing fast-changing and rarely-changing data in one context multiplies this.
**Source:** https://react.dev/reference/react/useContext#optimizing-re-renders-when-passing-objects-and-functions

```tsx
// ❌
<AuthContext value={{ user, logout: () => setUser(null) }}>{children}</AuthContext>

// ✅ (without React Compiler)
const logout = useCallback(() => setUser(null), [])
const value = useMemo(() => ({ user, logout }), [user, logout])
<AuthContext value={value}>{children}</AuthContext>
```

**Applies:** React ≥ 18 (`<Ctx value>` as provider needs 19; use `<Ctx.Provider value>` on 18) · **Exceptions:** React Compiler is on, so it memoizes the value (see SKILL.md); a provider at the root that rarely re-renders.

### REACT-COMP-007 · React 19: pass `ref` as a prop instead of `forwardRef`  `warn`

**Why:** In React 19, function components receive `ref` as a regular prop. `forwardRef` still works, but it's redundant boilerplate that React plans to deprecate.
**Source:** https://react.dev/blog/2024/12/05/react-19#ref-as-a-prop

```tsx
// ❌ (React 19)
const TextInput = forwardRef<HTMLInputElement, { label: string }>(({ label }, ref) => (
  <label>{label}<input ref={ref} /></label>
))

// ✅ (React 19)
function TextInput({ label, ref }: { label: string; ref?: React.Ref<HTMLInputElement> }) {
  return <label>{label}<input ref={ref} /></label>
}
```

**Applies:** React ≥ 19 · **Exceptions:** a shared library that must still support React 18.

### REACT-COMP-008 · React 18: forward refs with `forwardRef`; `ref` is not a prop  `error`

**Why:** On React 18, `ref` is stripped from props, so a function component that reads `props.ref` gets `undefined`, and the parent's ref stays `null`. Ref-as-a-prop code silently doesn't work there.
**Source:** https://react.dev/reference/react/forwardRef

```tsx
// ❌ (React 18)
function TextInput({ label, ref }: { label: string; ref?: React.Ref<HTMLInputElement> }) {
  return <label>{label}<input ref={ref} /></label>   // ref is always undefined
}

// ✅ (React 18)
const TextInput = forwardRef<HTMLInputElement, { label: string }>(function TextInput({ label }, ref) {
  return <label>{label}<input ref={ref} /></label>
})
```

**Applies:** React 18.x only · **Exceptions:** none.

### REACT-COMP-009 · React 19: render `<Context>` directly as the provider  `info`

**Why:** React 19 lets a context object be rendered as its own provider. `<Context.Provider>` still works but is slated for deprecation. Use the shorter form in new code on 19, and leave existing providers alone.
**Source:** https://react.dev/blog/2024/12/05/react-19#context-as-a-provider

```tsx
// ❌ (new code on React 19)
<ThemeContext.Provider value={theme}>{children}</ThemeContext.Provider>

// ✅ (React 19)
<ThemeContext value={theme}>{children}</ThemeContext>
```

**Applies:** React ≥ 19 (on 18, `.Provider` is required) · **Exceptions:** a library that supports React 18.

### REACT-COMP-010 · Give async and failure-prone UI a Suspense fallback and an error boundary  `warn`

**Why:** A component that suspends (lazy code, `use()`, Suspense-enabled data) with no `<Suspense>` above it shows the nearest fallback, which may blank out the whole page. A render error with no error boundary above it unmounts the entire tree. Place boundaries around the parts that can load or fail independently.
**Source:** https://react.dev/reference/react/Suspense · https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary

```tsx
// ❌
<Dashboard>
  <RevenueChart />        {/* suspends and can throw: takes the whole page down */}
</Dashboard>

// ✅
<Dashboard>
  <ErrorBoundary fallback={<p>Couldn't load revenue.</p>}>
    <Suspense fallback={<ChartSkeleton />}>
      <RevenueChart />
    </Suspense>
  </ErrorBoundary>
</Dashboard>
```

**Applies:** React ≥ 18 · **Exceptions:**
- The framework provides boundaries per route: Next.js `error.tsx`/`loading.tsx`, React Router `ErrorBoundary`, TanStack Router `errorComponent`/`pendingComponent`. Use those instead.
- An error boundary is the one place a **class component** is still needed. Write a small one, or use the project's existing error-boundary library. Don't add one without asking.

### REACT-COMP-011 · React 19: use default parameters, not `defaultProps`, on function components  `error`

**Why:** React 19 removed `defaultProps` for function components (and `propTypes` checks). They're silently ignored, so the defaults vanish and the props arrive as `undefined`. ES default parameters work on every version.
**Source:** https://react.dev/blog/2024/04/25/react-19-upgrade-guide#removed-proptypes-and-defaultprops

```tsx
// ❌
function Button({ size }: { size?: 'sm' | 'md' }) { return <button data-size={size} /> }
Button.defaultProps = { size: 'md' }   // ignored on React 19

// ✅
function Button({ size = 'md' }: { size?: 'sm' | 'md' }) { return <button data-size={size} /> }
```

**Applies:** React ≥ 19 for the removal. Default parameters are also preferred on 18 · **Exceptions:** class components, where `defaultProps` is still supported.
