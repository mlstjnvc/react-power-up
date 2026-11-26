# TypeScript in React (`REACT-TS-*`)

Rules for typing components, props, children, events, refs and context. They apply to every `.tsx` file and every `.ts` file that uses React APIs.

---

### REACT-TS-001 · Type every component's props explicitly  `warn`

**Why:** Untyped props become implicit `any` (or an error under `strict`), so callers can pass anything and every use inside the component goes unchecked. An explicit props type documents the component's contract and lets the compiler check every call site.
**Source:** https://react.dev/learn/typescript#typescript-with-react-components

```tsx
// ❌
export function Avatar(props) {
  return <img src={props.url} alt={props.name} />
}

// ✅
interface AvatarProps {
  url: string
  name: string
  size?: number
}
export function Avatar({ url, name, size = 40 }: AvatarProps) {
  return <img src={url} alt={name} width={size} height={size} />
}
```

**Applies:** React ≥ 18, TypeScript ≥ 5 · **Exceptions:** a component with no props.

### REACT-TS-002 · No `any`, no unchecked `as`, no `!` to silence the compiler  `warn`

**Why:** Each one switches off type checking exactly where the compiler found a doubt. `as` on external data (API responses, `JSON.parse`, route or search params, `FormData`) claims a shape nobody checked. Validating that data at trust boundaries is covered at `error` severity by the `SEC`, `NEXT`, `FORM` and router rules.
**Source:** https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#any · https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions · https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#non-null-assertion-operator-postfix-

```tsx
// ❌
const data: any = await res.json()
const user = data as User
inputRef.current!.focus()

// ✅
const data: unknown = await res.json()
const user = userSchema.parse(data) // validates, throws on a bad shape
inputRef.current?.focus()
```

**Applies:** TypeScript ≥ 5 · **Exceptions:** `as const`; narrowing `event.currentTarget` or `event.target` to a known element type; test doubles; a `!` directly after a check the compiler can't follow, with a comment saying why.

### REACT-TS-003 · Type `children` as `React.ReactNode`  `warn`

**Why:** `React.ReactNode` accepts everything JSX can render: strings, numbers, `null`, arrays, fragments and elements. `JSX.Element` or `React.ReactElement` reject plain text and `null`, so callers have to wrap content just to satisfy the type.
**Source:** https://react.dev/learn/typescript#typing-children

```tsx
// ❌
interface CardProps { children: JSX.Element }
<Card>Hello</Card> // type error

// ✅
interface CardProps { title: string; children: React.ReactNode }
export function Card({ title, children }: CardProps) {
  return (
    <section>
      <h2>{title}</h2>
      {children}
    </section>
  )
}
```

**Applies:** React ≥ 18, `@types/react` ≥ 18 · **Exceptions:** a component that really needs a single element (e.g. it clones its child): use `React.ReactElement` and say why.

### REACT-TS-004 · Type event handlers with React's event types  `warn`

**Why:** React passes synthetic events, not DOM events. Writing `(e: any)` or the DOM `Event` type hides `currentTarget` typing and the event's fields. Inline handlers infer the right type automatically. Handlers declared separately need the matching React type.
**Source:** https://react.dev/learn/typescript#typing-dom-events

```tsx
// ❌
function handleChange(e: any) {
  setQuery(e.target.value)
}

// ✅
function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
  setQuery(e.currentTarget.value)
}
<input value={query} onChange={handleChange} />
// or inline: <input onChange={(e) => setQuery(e.currentTarget.value)} />
```

**Applies:** React ≥ 18 · **Exceptions:** none.

### REACT-TS-005 · Give `useRef` a type and an initial value  `warn`

**Why:**
- DOM refs need the element type and `null` (`useRef<HTMLInputElement>(null)`), so `ref.current` is typed as `HTMLInputElement | null`, and the null case is handled.
- Value refs need the value type. React 19's types **require** an argument to `useRef`, so `useRef<T>()` with no argument no longer compiles.
**Source:** https://react.dev/reference/react/useRef · https://react.dev/blog/2024/04/25/react-19-upgrade-guide#useref-requires-argument

```tsx
// ❌
const inputRef = useRef()          // any (18) / type error (19)
const timer = useRef<number>()     // type error on 19

// ✅
const inputRef = useRef<HTMLInputElement>(null)
const timer = useRef<number | null>(null)
```

**Applies:** React ≥ 18. The "argument required" part needs `@types/react` ≥ 19 · **Exceptions:** none.

### REACT-TS-006 · Context without a real default: `null` default plus a guard hook  `warn`

**Why:** Most contexts have no meaningful value outside their provider. A fake default (`{} as AuthValue`) type-checks but crashes at runtime when a component renders outside the provider. A `null` default plus a hook that throws gives a clear error, and consumers get a non-null type.
**Source:** https://react.dev/learn/typescript#typing-usecontext

```tsx
// ❌
const AuthContext = createContext<AuthValue>({} as AuthValue)

// ✅
const AuthContext = createContext<AuthValue | null>(null)

export function useAuth(): AuthValue {
  const value = useContext(AuthContext)
  if (value === null) throw new Error('useAuth must be used inside <AuthProvider>')
  return value
}
```

**Applies:** React ≥ 18 · **Exceptions:** a context with a genuine default (theme, locale), where using it outside a provider is valid.

### REACT-TS-007 · Model mutually exclusive props as a discriminated union  `info`

**Why:** A pile of optional booleans and optional fields (`isLink?`, `href?`, `onClick?`) allows combinations that make no sense, and every use has to check fields defensively. A union with a discriminant lets the compiler reject invalid combinations and narrow inside the component.
**Source:** https://www.typescriptlang.org/docs/handbook/2/narrowing.html#discriminated-unions

```tsx
// ❌
interface ActionProps { isLink?: boolean; href?: string; onClick?: () => void; label: string }

// ✅
type ActionProps =
  | { kind: 'link'; href: string; label: string }
  | { kind: 'button'; onClick: () => void; label: string }

export function Action(props: ActionProps) {
  return props.kind === 'link'
    ? <a href={props.href}>{props.label}</a>
    : <button type="button" onClick={props.onClick}>{props.label}</button>
}
```

**Applies:** TypeScript ≥ 5 · **Exceptions:** independent optional props, which are normal optional fields.

### REACT-TS-008 · Type props on the parameter; `React.FC` is optional  `info`

**Why:** react.dev types components as plain functions with typed props. `React.FC` adds nothing that a typed parameter lacks, and it makes generic components awkward. Projects that already use `React.FC` consistently can keep it.
**Source:** https://react.dev/learn/typescript#typescript-with-react-components

```tsx
// ❌ (in a project that doesn't already use FC)
export const Badge: React.FC<{ label: string }> = ({ label }) => <span>{label}</span>

// ✅
export function Badge({ label }: { label: string }) {
  return <span>{label}</span>
}
```

**Applies:** React ≥ 18 · **Exceptions:** the project's existing convention is `React.FC`.

### REACT-TS-009 · Use a type parameter for components generic over their data  `warn`

**Why:** A list, select or table typed as `items: any[]` and `renderItem: (item: any) => …` loses the link between the data and the callbacks. A type parameter keeps it, so `renderItem` and `onSelect` see the caller's real item type.
**Source:** https://www.typescriptlang.org/docs/handbook/2/generics.html

```tsx
// ❌
interface ListProps { items: any[]; renderItem: (item: any) => React.ReactNode }

// ✅
interface ListProps<T> {
  items: T[]
  getKey: (item: T) => string
  renderItem: (item: T) => React.ReactNode
}
export function List<T>({ items, getKey, renderItem }: ListProps<T>) {
  return <ul>{items.map((item) => <li key={getKey(item)}>{renderItem(item)}</li>)}</ul>
}
```

**Applies:** TypeScript ≥ 5 · **Exceptions:** none.

### REACT-TS-010 · Extend native element props with `React.ComponentProps<'tag'>`  `info`

**Why:** A wrapper around a native element (a styled `<button>` or `<input>`) should accept the element's own attributes (`type`, `disabled`, `aria-*`, handlers). Re-declaring them by hand misses most of them, and blocks accessibility attributes.
**Source:** https://react.dev/learn/typescript#useful-types

```tsx
// ❌
interface ButtonProps { label: string; onClick: () => void }

// ✅
type ButtonProps = React.ComponentProps<'button'> & { variant?: 'primary' | 'secondary' }
export function Button({ variant = 'primary', type = 'button', ...rest }: ButtonProps) {
  return <button type={type} data-variant={variant} {...rest} />
}
```

**Applies:** React ≥ 18 · **Exceptions:** a component that deliberately exposes a narrow API.
