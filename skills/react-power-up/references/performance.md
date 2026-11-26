# Performance (`REACT-PERF-*`)

Rules for render performance and bundle size. Measure before optimizing. Check first whether **React Compiler** is enabled (see SKILL.md → *React Compiler*), because it changes the memoization advice. Next.js data and streaming performance (parallel fetches, `<Suspense>`) is in `nextjs.md`. Query caching is in `tanstack-query.md`.

---

### REACT-PERF-001 · With React Compiler on, don't add manual `useMemo`, `useCallback` or `memo`  `info`

**Why:** The compiler memoizes components, values and callbacks automatically, often more precisely than hand-written memoization. In compiled code, new manual memoization is noise. React's guidance for new code is to rely on the compiler, and to keep `useMemo`/`useCallback` only as an escape hatch where you need control, such as a value used as an effect dependency. Leave existing memoization alone unless the task touches that code.
**Source:** https://react.dev/learn/react-compiler/introduction#what-should-i-do-about-usememo-usecallback-and-reactmemo

```tsx
// ❌ (compiler enabled)
const visible = useMemo(() => items.filter((i) => i.active), [items])
const onSelect = useCallback((id: string) => setSelected(id), [])
export default memo(ItemList)

// ✅ (compiler enabled)
const visible = items.filter((i) => i.active)
const onSelect = (id: string) => setSelected(id)
export default ItemList
```

**Applies:** React Compiler ≥ 1.0 enabled (React ≥ 19, or 17/18 with `react-compiler-runtime`) · **Exceptions:** a memoized value used as an effect dependency, where you need the guarantee; code the compiler bails out on (shown in its ESLint/devtools output).

### REACT-PERF-002 · Without the compiler, memoize only for a measured cost or referential identity  `info`

**Why:** `useMemo`/`useCallback`/`memo` add code and dependency arrays (another place for REACT-HOOK-003 bugs), and buy nothing for cheap calculations or for children that aren't memoized. Use them when a calculation is measurably slow (react.dev suggests timing it, roughly 1 ms or more), when a value is a dependency of another hook, or when it's a prop of a `memo` child.
**Source:** https://react.dev/reference/react/useMemo#should-you-add-usememo-everywhere · https://react.dev/reference/react/memo#should-you-add-memo-everywhere

```tsx
// ❌
const fullName = useMemo(() => `${user.first} ${user.last}`, [user.first, user.last])
const handleClick = useCallback(() => setOpen(true), [])   // passed to a plain <button>

// ✅
const fullName = `${user.first} ${user.last}`
const sorted = useMemo(() => rows.toSorted(compareRows), [rows])  // 20k rows: measured slow
```

**Applies:** React ≥ 18 without React Compiler · **Exceptions:** the project's established convention, which wins for style-level memoization (this rule is `info`).

### REACT-PERF-003 · Don't recompute expensive values on unrelated re-renders  `warn`

**Why:** Sorting, filtering or aggregating thousands of items directly in the component body runs on **every** render, including re-renders caused by unrelated state (a hover, a typing field). Without the compiler, wrap genuinely expensive derivations in `useMemo` keyed on their real inputs, or move the work out of the hot component.
**Source:** https://react.dev/reference/react/useMemo#skipping-expensive-recalculations

```tsx
// ❌ (no compiler; 50k transactions; re-sorts on every keystroke in `note`)
const [note, setNote] = useState('')
const byAmount = transactions.toSorted((a, b) => b.amount - a.amount)

// ✅
const byAmount = useMemo(() => transactions.toSorted((a, b) => b.amount - a.amount), [transactions])
```

**Applies:** React ≥ 18 without React Compiler (with the compiler, this is automatic) · **Exceptions:** cheap calculations (see REACT-PERF-002).

### REACT-PERF-004 · Keep typing responsive: defer expensive renders driven by input  `warn`

**Why:** When each keystroke re-renders a heavy list or chart, typing lags, because React renders the input and the heavy part together. `useDeferredValue` lets the input update immediately and renders the heavy part with the deferred value, in the background and interruptibly. `useTransition` does the same for state updates you start yourself.
**Source:** https://react.dev/reference/react/useDeferredValue#deferring-re-rendering-for-a-part-of-the-ui

```tsx
// ❌
const [query, setQuery] = useState('')
return <><input aria-label="Search" value={query} onChange={(e) => setQuery(e.currentTarget.value)} /><SlowResults query={query} /></>

// ✅
const [query, setQuery] = useState('')
const deferredQuery = useDeferredValue(query)
return <><input aria-label="Search" value={query} onChange={(e) => setQuery(e.currentTarget.value)} /><SlowResults query={deferredQuery} /></>
// SlowResults is wrapped in memo (or compiled), so it re-renders only when deferredQuery changes
```

**Applies:** React ≥ 18 · **Exceptions:** network-bound search, which needs debouncing or the data layer's caching rather than deferral.

### REACT-PERF-005 · Code-split heavy, rarely used parts with `lazy` / `next/dynamic`  `warn`

**Why:** A rich-text editor, a chart library or an admin-only panel imported at the top of a common page ships to every visitor and delays the first interaction. `React.lazy(() => import(…))` inside `<Suspense>` (or `next/dynamic` in Next.js, and route-level `lazy` in the routers) loads it only when it's rendered.
**Source:** https://react.dev/reference/react/lazy#suspense-for-code-splitting · https://nextjs.org/docs/app/guides/lazy-loading#nextdynamic

```tsx
// ❌
import { MarkdownEditor } from './MarkdownEditor'                 // 300 kB, only after "Edit" is clicked

// ✅
const MarkdownEditor = lazy(() => import('./MarkdownEditor').then((m) => ({ default: m.MarkdownEditor })))
{editing && <Suspense fallback={<p>Loading editor…</p>}><MarkdownEditor value={draft} onChange={setDraft} /></Suspense>}
```

**Applies:** React ≥ 18 (`lazy`); Next.js ≥ 13 (`next/dynamic`) · **Exceptions:** small components, and anything on the initial critical path. Define `lazy` at module scope, never inside a component.

### REACT-PERF-006 · Render very long lists with virtualization (when the project has a virtualizer)  `info`

**Why:** Rendering thousands of rows creates thousands of DOM nodes, so the first render is slow and scrolling janks. Virtualization renders only the visible rows. If the project already has a virtualizer (TanStack Virtual, react-window), use it for lists of several hundred rows or more. Otherwise, suggest one, or paginate. Don't add it unasked.
**Source:** https://tanstack.com/virtual/latest/docs/introduction

```tsx
// ❌ 10 000 rows, all mounted
<ul>{logs.map((l) => <LogRow key={l.id} log={l} />)}</ul>

// ✅ (TanStack Virtual already installed)
const parentRef = useRef<HTMLDivElement>(null)
const virtualizer = useVirtualizer({ count: logs.length, getScrollElement: () => parentRef.current, estimateSize: () => 32 })
<div ref={parentRef} style={{ height: 480, overflow: 'auto' }}>
  <div style={{ height: virtualizer.getTotalSize(), position: 'relative' }}>
    {virtualizer.getVirtualItems().map((v) => (
      <div key={logs[v.index].id} style={{ position: 'absolute', top: 0, transform: `translateY(${v.start}px)`, height: v.size }}>
        <LogRow log={logs[v.index]} />
      </div>
    ))}
  </div>
</div>
```

**Applies:** any React version, with a virtualizer present · **Exceptions:** lists of a few hundred simple rows, and lists that are paginated anyway.

### REACT-PERF-007 · Keep props to memoized children stable  `info`

**Why:** `memo(Child)` skips re-rendering only when every prop is unchanged by `Object.is`. Passing a new object, array or function literal on each render (`style={{…}}`, `options={[…]}`, `onChange={() => …}`) breaks it, so the child re-renders every time anyway. Without the compiler, hoist constants, pass primitives, or memoize those props when the child is memoized for a reason.
**Source:** https://react.dev/reference/react/memo#minimizing-props-changes

```tsx
// ❌
const Chart = memo(ChartImpl)
<Chart options={{ stacked: true }} onHover={(p) => setHover(p)} data={data} />

// ✅
const CHART_OPTIONS = { stacked: true } as const
const onHover = useCallback((p: Point) => setHover(p), [])
<Chart options={CHART_OPTIONS} onHover={onHover} data={data} />
```

**Applies:** React ≥ 18 without React Compiler · **Exceptions:** children that aren't memoized, where stabilizing props gains nothing.

### REACT-PERF-008 · Import only what you use from large libraries  `info`

**Why:** `import _ from 'lodash'`, or re-exporting a whole icon set through a barrel file, can pull far more code into the bundle than the few functions used, depending on the bundler's tree-shaking. Import specific modules (`lodash/debounce`, `@mui/icons-material/Delete`). In Next.js, `optimizePackageImports` handles many popular packages automatically.
**Source:** https://nextjs.org/docs/app/api-reference/config/next-config-js/optimizePackageImports

```ts
// ❌
import _ from 'lodash'
const onSearch = _.debounce(search, 300)

// ✅
import debounce from 'lodash/debounce'
const onSearch = debounce(search, 300)
```

**Applies:** any bundler · **Exceptions:** libraries designed for named-import tree-shaking (`lodash-es`, most modern ESM packages).
