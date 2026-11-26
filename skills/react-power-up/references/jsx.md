# JSX and accessibility (`REACT-JSX-*`)

Rules for lists, conditional rendering, event handlers and the accessibility basics of the markup you produce. Security of what goes *into* the markup (`dangerouslySetInnerHTML`, URLs) is in `security.md`.

---

### REACT-JSX-001 · Key list items by a stable id from the data  `error`

**Why:** React matches list items between renders by `key`. With the array index as the key, removing, inserting, filtering or sorting items reattaches state, focus and input values to the wrong rows. Deleting item 2 can leave its text in item 3's input. `Math.random()` or `crypto.randomUUID()` in render remounts every item on every render. A missing key gives the same bugs as the index, plus a warning.
**Source:** https://react.dev/learn/rendering-lists#keeping-list-items-in-order-with-key · https://react.dev/learn/rendering-lists#rules-of-keys

```tsx
// ❌
{todos.map((todo, index) => <TodoRow key={index} todo={todo} onRemove={remove} />)}
{todos.map((todo) => <TodoRow key={crypto.randomUUID()} todo={todo} onRemove={remove} />)}

// ✅
{todos.map((todo) => <TodoRow key={todo.id} todo={todo} onRemove={remove} />)}

// ✅ several elements per item: key the Fragment
{terms.map((t) => (
  <Fragment key={t.id}>
    <dt>{t.term}</dt>
    <dd>{t.definition}</dd>
  </Fragment>
))}
```

**Applies:** React ≥ 18 · **Exceptions:** a static list that is never reordered, filtered or edited, and whose items have no state, may use the index. If the data has no id, create one when the item is created (not during render).

### REACT-JSX-002 · Don't put a number on the left of `&&`  `error`

**Why:** `{count && <Badge />}` renders the number `0` when `count` is 0, because JSX renders `0` but skips `false`. The same applies to `{items.length && <List />}`, which shows a stray "0" on the empty screen. Compare explicitly, or use a ternary.
**Source:** https://react.dev/learn/conditional-rendering#logical-and-operator-

```tsx
// ❌
{items.length && <ItemList items={items} />}
{unread && <Badge count={unread} />}            // unread: number

// ✅
{items.length > 0 && <ItemList items={items} />}
{unread > 0 ? <Badge count={unread} /> : null}
```

**Applies:** React ≥ 18 · **Exceptions:** the left side is a boolean (or a non-numeric value whose falsy forms are `null`/`undefined`/`false`/`''`, and an empty string is acceptable output).

### REACT-JSX-003 · Use `<button>` for actions; never a clickable `<div>`/`<span>`  `error`

**Why:** A `<div onClick>` can't be reached with Tab, can't be activated with Enter or Space, and isn't announced as a button by screen readers. Keyboard and assistive-technology users can't use it (WCAG 2.1.1 Keyboard, 4.1.2 Name, Role, Value). `<button>` gives you all of that for free.
**Source:** https://www.w3.org/WAI/WCAG22/Understanding/keyboard.html · https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/blob/main/docs/rules/no-static-element-interactions.md · https://www.w3.org/WAI/ARIA/apg/patterns/button/

```tsx
// ❌
<div className="card-remove" onClick={() => onRemove(item.id)}>✕</div>

// ✅
<button type="button" className="card-remove" onClick={() => onRemove(item.id)} aria-label={`Remove ${item.name}`}>
  ✕
</button>
```

**Applies:** React ≥ 18 · **Exceptions:** a non-interactive wrapper that only catches bubbled events from real controls inside it; elements made interactive with the full ARIA pattern (role, `tabIndex`, key handlers), but only when a native element can't be used.

### REACT-JSX-004 · Give every form control an accessible label  `error`

**Why:** An `<input>`, `<select>` or `<textarea>` with no label is announced only as "edit text". A placeholder isn't a label: it disappears on typing, and screen readers handle it inconsistently. Associate a visible `<label>` (with `htmlFor` + `useId`, or by wrapping), or give an `aria-label` when there's no visible text.
**Source:** https://www.w3.org/WAI/WCAG22/Understanding/info-and-relationships.html · https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/blob/main/docs/rules/label-has-associated-control.md

```tsx
// ❌
<input type="email" placeholder="Email" value={email} onChange={(e) => setEmail(e.currentTarget.value)} />

// ✅
const id = useId()
<label htmlFor={id}>Email</label>
<input id={id} type="email" value={email} onChange={(e) => setEmail(e.currentTarget.value)} />

// ✅ no visible label
<input type="search" aria-label="Search products" value={q} onChange={(e) => setQ(e.currentTarget.value)} />
```

**Applies:** React ≥ 18 (`useId`; on older code, any unique id) · **Exceptions:** hidden inputs (`type="hidden"`); buttons, which are labelled by their text content.

### REACT-JSX-005 · Give images an `alt`; use `alt=""` for decorative ones  `warn`

**Why:** Without `alt`, screen readers read the file name. Informative images need a text alternative that conveys their content (WCAG 1.1.1). Purely decorative images need an empty `alt=""`, so they're skipped. An icon-only button is labelled with `aria-label`, and its icon is hidden from assistive technology.
**Source:** https://www.w3.org/WAI/WCAG22/Understanding/non-text-content.html · https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/blob/main/docs/rules/alt-text.md

```tsx
// ❌
<img src={product.imageUrl} />
<button type="button" onClick={close}><img src="/icons/x.svg" /></button>

// ✅
<img src={product.imageUrl} alt={product.name} />
<img src="/decor/wave.svg" alt="" />
<button type="button" onClick={close} aria-label="Close dialog"><img src="/icons/x.svg" alt="" /></button>
```

**Applies:** React ≥ 18 (in Next.js, `next/image` requires `alt` too) · **Exceptions:** none.

### REACT-JSX-006 · Set `type="button"` on buttons that don't submit  `warn`

**Why:** A `<button>` inside a `<form>` defaults to `type="submit"`. A "Show password", "Add row" or "Cancel" button without `type="button"` submits the form, and may navigate or fire the Server Action.
**Source:** https://html.spec.whatwg.org/multipage/form-elements.html#attr-button-type

```tsx
// ❌
<form onSubmit={handleSubmit}>
  <button onClick={() => setShowPassword((s) => !s)}>Show</button>
  <button>Sign in</button>
</form>

// ✅
<form onSubmit={handleSubmit}>
  <button type="button" onClick={() => setShowPassword((s) => !s)}>Show</button>
  <button type="submit">Sign in</button>
</form>
```

**Applies:** React ≥ 18 · **Exceptions:** buttons outside any form behave the same either way. Still prefer an explicit `type` in reusable button components (see REACT-TS-010).

### REACT-JSX-007 · Pass event handlers; don't call them  `error`

**Why:** `onClick={remove(item.id)}` calls `remove` **during render**, which deletes the item as soon as the list renders. It can also set state during render and loop. Pass a function: `onClick={() => remove(item.id)}`, or the handler itself when it takes no arguments.
**Source:** https://react.dev/learn/responding-to-events#adding-event-handlers

```tsx
// ❌
<button type="button" onClick={remove(item.id)}>Remove</button>
<button type="button" onClick={handleSave()}>Save</button>

// ✅
<button type="button" onClick={() => remove(item.id)}>Remove</button>
<button type="button" onClick={handleSave}>Save</button>
```

**Applies:** React ≥ 18 · **Exceptions:** a factory that *returns* a handler (`onClick={makeHandler(id)}`, where `makeHandler` returns a function). Prefer the inline arrow for clarity.

### REACT-JSX-008 · Links navigate, buttons act  `warn`

**Why:** `<a href="#" onClick={…}>` for an action and `<button onClick={() => navigate('/x')}>` for navigation both break expectations. The first can't be activated with Space, adds `#` to the URL and is announced as a link. The second loses middle-click and "open in new tab", and gets no URL preview. Use `<a>`/router `<Link>` to go somewhere and `<button>` to do something.
**Source:** https://www.w3.org/WAI/ARIA/apg/patterns/link/ · https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/blob/main/docs/rules/anchor-is-valid.md

```tsx
// ❌
<a href="#" onClick={(e) => { e.preventDefault(); void archive(id) }}>Archive</a>
<button type="button" onClick={() => navigate(`/orders/${id}`)}>View order</button>

// ✅
<button type="button" onClick={() => void archive(id)}>Archive</button>
<Link to={`/orders/${id}`}>View order</Link>   {/* or next/link's <Link href=…> */}
```

**Applies:** React ≥ 18 · **Exceptions:** navigation that must happen *after* an action (submit, then go to the result) is done in the handler with the router's `navigate`. That's still a button.

### REACT-JSX-009 · Expose the state of custom disclosure and toggle widgets  `warn`

**Why:** A button that shows or hides a panel, or toggles something, looks the same to a screen reader in both states unless it says so. `aria-expanded` (plus `aria-controls`) for disclosures, and `aria-pressed` for toggle buttons, announce the state (WCAG 4.1.2).
**Source:** https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/ · https://www.w3.org/WAI/WCAG22/Understanding/name-role-value.html

```tsx
// ❌
<button type="button" onClick={() => setOpen((o) => !o)}>Details</button>
{open && <div>{details}</div>}

// ✅
const panelId = useId()
<button type="button" aria-expanded={open} aria-controls={panelId} onClick={() => setOpen((o) => !o)}>
  Details
</button>
<div id={panelId} hidden={!open}>{details}</div>
```

**Applies:** React ≥ 18 · **Exceptions:** native `<details>`/`<summary>`, which handle this themselves; components from the project's accessible UI library.

### REACT-JSX-010 · Move heavy logic out of JSX  `info`

**Why:** Nested ternaries and long `filter().map()` chains inside JSX are hard to read and to review. Compute values into well-named variables above the `return`, or extract a component.
**Source:** https://react.dev/learn/conditional-rendering#conditionally-assigning-jsx-to-a-variable

```tsx
// ❌
return <div>{user ? (user.isAdmin ? <AdminPanel /> : user.trial ? <TrialBanner /> : <Dashboard />) : <SignIn />}</div>

// ✅
let content: React.ReactNode
if (!user) content = <SignIn />
else if (user.isAdmin) content = <AdminPanel />
else if (user.trial) content = <TrialBanner />
else content = <Dashboard />
return <div>{content}</div>
```

**Applies:** React ≥ 18 · **Exceptions:** a single simple ternary or `&&`.

### REACT-JSX-011 · Name repeated row actions after their item  `warn`

**Why:** In a list, every row's "Delete", "Edit" or "Show notes" button gets the same accessible name. Screen-reader users who tab through the buttons, or pull up a list of them, hear the same words over and over and can't tell which task each one acts on. Labels must describe their purpose (WCAG 2.4.6). Put the item in the name: as visually hidden text, or as an `aria-label` that **starts with the visible text**, so voice users can still say what they see (WCAG 2.5.3 Label in Name). This applies to icon-only buttons too (REACT-JSX-003).
**Source:** https://www.w3.org/WAI/WCAG22/Understanding/headings-and-labels.html#intent · https://www.w3.org/WAI/WCAG22/Understanding/label-in-name.html#intent

```tsx
// ❌ every row announces just "Show notes, collapsed" / "Delete"
<li>
  <label htmlFor={checkboxId}>{task.title}</label>
  <button type="button" aria-expanded={open} aria-controls={notesId} onClick={toggle}>Show notes</button>
  <button type="button" onClick={() => onDelete(task.id)}>Delete</button>
</li>

// ✅ the name starts with the visible text and names the item
<li>
  <label htmlFor={checkboxId}>{task.title}</label>
  <button type="button" aria-expanded={open} aria-controls={notesId} onClick={toggle} aria-label={`Show notes for ${task.title}`}>
    Show notes
  </button>
  <button type="button" onClick={() => onDelete(task.id)} aria-label={`Delete ${task.title}`}>Delete</button>
</li>
```

**Applies:** React ≥ 18 · **Exceptions:** a single action on the page, or a button whose visible text already names the item ("Delete Buy milk"). Keep a toggling `aria-label` in step with the visible text (e.g. "Hide notes for …" when open).
