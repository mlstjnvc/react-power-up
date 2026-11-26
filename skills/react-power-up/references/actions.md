# React 19 Actions (`REACT-ACT-*`)

**Actions** are async functions run in a transition. They're passed to `<form action>` or `formAction`, wrapped by `useActionState`, or started with `startTransition`. React tracks their pending state, errors and optimistic updates. These APIs need **React 19**. React 18 fallbacks are given per rule.

Validating and authorizing what an action receives is covered by `forms.md`, `nextjs-server.md` and `security.md`. Server Actions are public endpoints.

---

### REACT-ACT-001 · Use `useActionState` for an action's result, error and pending state  `warn`

**Why:** Hand-rolled `isPending` / `error` state with `try`/`finally` around a submit handler duplicates what React 19 tracks. It also gets ordering wrong when the user submits twice: an earlier response can overwrite a later one. `useActionState` queues submissions, and returns the latest result and `isPending`.
**Source:** https://react.dev/reference/react/useActionState#use-with-a-form

```tsx
// ❌ (React 19)
const [pending, setPending] = useState(false)
const [error, setError] = useState<string | null>(null)
async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
  e.preventDefault()
  setPending(true)
  try { await subscribe(new FormData(e.currentTarget)) } catch { setError('Failed') } finally { setPending(false) }
}

// ✅ (React 19)
type SubscribeState = { error: string | null; done: boolean }
const [state, formAction, isPending] = useActionState<SubscribeState, FormData>(
  async (_prev, formData) => {
    try {
      await subscribe(formData)
      return { error: null, done: true }
    } catch {
      return { error: 'Could not subscribe. Try again.', done: false }
    }
  },
  { error: null, done: false },
)
return (
  <form action={formAction}>
    <input name="email" type="email" aria-label="Email" required />
    <button type="submit" disabled={isPending}>{isPending ? 'Subscribing…' : 'Subscribe'}</button>
    {state.error && <p role="alert">{state.error}</p>}
  </form>
)
```

**Applies:** React ≥ 19 · **Exceptions:**
- Forms managed by React Hook Form use its `handleSubmit` and `formState` (see `forms.md`).
- On React 18, keep the manual state, and guard against stale responses (REACT-ACT-005).

### REACT-ACT-002 · The action passed to `useActionState` receives the previous state first  `error`

**Why:** `useActionState` calls your function as `(previousState, formData)`. An action written as `(formData) => …` receives the *previous state* in its first parameter, so `formData.get` throws or reads `undefined`. This mistake is common when converting a plain form action.
**Source:** https://react.dev/reference/react/useActionState#action-cannot-read-form-data

```tsx
// ❌
const [state, formAction] = useActionState(async (formData: FormData) => {
  return save(String(formData.get('title')))           // formData is actually the previous state
}, null)

// ✅
const [state, formAction] = useActionState(async (_prev: SaveResult | null, formData: FormData) => {
  return save(String(formData.get('title') ?? ''))
}, null)
```

**Applies:** React ≥ 19 · **Exceptions:** none.

### REACT-ACT-003 · Call `useFormStatus` from a component rendered inside the `<form>`  `error`

**Why:** `useFormStatus` reads the status of the **parent** `<form>`. Called in the component that renders the form, it has no parent form, so `pending` is always `false` and the submit button never shows a pending state.
**Source:** https://react.dev/reference/react-dom/hooks/useFormStatus#useformstatus-will-not-return-status-information-for-a-form-rendered-in-the-same-component

```tsx
// ❌
function ContactForm() {
  const { pending } = useFormStatus()                  // not inside a <form>: always false
  return <form action={sendMessage}><button type="submit" disabled={pending}>Send</button></form>
}

// ✅
function SubmitButton() {
  const { pending } = useFormStatus()
  return <button type="submit" disabled={pending}>{pending ? 'Sending…' : 'Send'}</button>
}
function ContactForm() {
  return <form action={sendMessage}><textarea name="message" aria-label="Message" /><SubmitButton /></form>
}
```

**Applies:** React ≥ 19 (`useFormStatus` is imported from `react-dom`) · **Exceptions:** none.

### REACT-ACT-004 · Set optimistic state only inside an action or transition, and keep the real state the source of truth  `error`

**Why:** `useOptimistic` state is *temporary*. It shows while the action is pending, then falls back to the real state, which also gives you automatic rollback on failure. Calling the setter outside an action or `startTransition` triggers React's "optimistic state update occurred outside a transition" error, and the value doesn't revert. Writing the optimistic value into real state up front defeats the rollback.
**Source:** https://react.dev/reference/react/useOptimistic#an-optimistic-state-update-occurred-outside-a-transition-or-action · https://react.dev/reference/react/useOptimistic#optimistic-delete-with-error-recovery

```tsx
// ❌
function Likes({ count, like }: { count: number; like: () => Promise<number> }) {
  const [optimisticCount, setOptimisticCount] = useOptimistic(count)
  return <button type="button" onClick={async () => { setOptimisticCount(count + 1); await like() }}>♥ {optimisticCount}</button>
}

// ✅
function Likes({ count, like }: { count: number; like: () => Promise<void> }) {
  const [optimisticCount, addLike] = useOptimistic(count, (current: number, delta: number) => current + delta)
  const [, startTransition] = useTransition()
  return (
    <button type="button" onClick={() => startTransition(async () => { addLike(1); await like() })}>
      ♥ {optimisticCount}
    </button>
  )
}
```

**Applies:** React ≥ 19 · **Exceptions:** inside a `<form action>` or an action prop, which already runs as an action, so no extra `startTransition` is needed.

### REACT-ACT-005 · React 18: no function `action` props or Action hooks; use `onSubmit` with explicit state  `error`

**Why:** On React 18, `<form action={fn}>` isn't supported: the function is not called and the browser does a normal form submission. `useActionState`, `useOptimistic`, `useFormStatus` and `use()` don't exist there. Code written for 19 silently breaks or doesn't compile on 18.
**Source:** https://react.dev/blog/2024/12/05/react-19#form-actions · https://react.dev/reference/react-dom/components/form

```tsx
// ❌ (React 18)
<form action={saveProfile}>…</form>

// ✅ (React 18)
const [pending, setPending] = useState(false)
const latest = useRef(0)
async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
  e.preventDefault()
  const call = ++latest.current
  setPending(true)
  try { await saveProfile(new FormData(e.currentTarget)) } finally { if (call === latest.current) setPending(false) }
}
<form onSubmit={handleSubmit}>…<button type="submit" disabled={pending}>Save</button></form>
```

**Applies:** React 18.x only · **Exceptions:** none.

### REACT-ACT-006 · After an `await` inside a transition, wrap further state updates in `startTransition` again  `warn`

**Why:** State updates that run after an `await` in an async transition aren't automatically part of that transition. The pending indicator can end early, or the update can block input. React documents wrapping post-`await` updates in another `startTransition`.
**Source:** https://react.dev/reference/react/useTransition#react-doesnt-treat-my-state-update-after-await-as-a-transition

```tsx
// ❌
startTransition(async () => {
  const next = await updateQuantity(id, qty)
  setQuantity(next)                                   // not a transition
})

// ✅
startTransition(async () => {
  const next = await updateQuantity(id, qty)
  startTransition(() => { setQuantity(next) })
})
```

**Applies:** React ≥ 19 (async transitions) · **Exceptions:** updates made through `useActionState`, whose returned state is handled by React.

### REACT-ACT-007 · Preserve the user's input when an action fails  `warn`

**Why:** After a `<form action>` completes, React resets uncontrolled fields. If the action returns a validation error, the user loses everything they typed. Return the submitted values in the action state, and feed them back as `defaultValue`, or keep the fields controlled.
**Source:** https://react.dev/reference/react/useActionState#displaying-validation-errors-and-preserving-form-values

```tsx
// ❌
const [state, formAction] = useActionState(async (_prev: { error?: string }, fd: FormData) => {
  const name = String(fd.get('name') ?? '')
  return name.length < 2 ? { error: 'Name is too short' } : {}
}, {})
<form action={formAction}><input name="name" aria-label="Name" />{state.error}</form>   // field cleared on error

// ✅
type State = { error?: string; values: { name: string } }
const [state, formAction] = useActionState(async (_prev: State, fd: FormData): Promise<State> => {
  const name = String(fd.get('name') ?? '')
  return name.length < 2 ? { error: 'Name is too short', values: { name } } : { values: { name: '' } }
}, { values: { name: '' } })
<form action={formAction}>
  <input name="name" aria-label="Name" defaultValue={state.values.name} key={state.values.name} />
  {state.error && <p role="alert">{state.error}</p>}
</form>
```

**Applies:** React ≥ 19 · **Exceptions:** forms whose fields are fully controlled, or managed by React Hook Form.
