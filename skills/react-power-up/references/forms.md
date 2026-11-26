# Forms: React Hook Form + Zod (`REACT-FORM-*`)

Rules for React Hook Form v7 (RHF) with Zod (v4 primary, v3 noted) through `@hookform/resolvers`. For plain React 19 forms without RHF, see [`actions.md`](actions.md). For where the server-side validation lives, see `nextjs-server.md` (Server Actions and route handlers) and `react-router.md` (actions).

**One schema, two places:** define the Zod schema in a module both sides can import. The client uses it for instant feedback. The server **must** parse with it again, because anything sent from a browser can be forged.

---

### REACT-FORM-001 · Validate with a schema resolver, and infer the form type from the schema  `warn`

**Why:** Inline `register` rules duplicate what a schema already says, and a hand-written `interface FormValues` drifts from the schema: a renamed field still compiles. `zodResolver(schema)` validates the whole form in one place, and `z.infer<typeof schema>` makes the form's type follow the schema.
**Source:** https://react-hook-form.com/get-started#SchemaValidation · https://zod.dev/basics#inferring-types

```tsx
// ❌
interface SignupValues { email: string; password: string }
const { register } = useForm<SignupValues>()
<input {...register('email', { required: true, pattern: /.+@.+/ })} />

// ✅ (src/schemas/signup.ts, importable by client and server)
export const signupSchema = z.object({
  email: z.email({ error: 'Enter a valid email address' }),
  password: z.string().min(12, { error: 'Use at least 12 characters' }),
})
export type SignupValues = z.infer<typeof signupSchema>
// component
const { register, handleSubmit, formState: { errors } } = useForm<SignupValues>({
  resolver: zodResolver(signupSchema),
  defaultValues: { email: '', password: '' },
})
```

**Applies:** React Hook Form ≥ 7, `@hookform/resolvers` ≥ 5 for Zod 4 (≥ 3 for Zod 3) · **Exceptions:** a tiny form in a project with no schema library. Don't add Zod unasked; use RHF rules there.

### REACT-FORM-002 · Re-validate on the server with the same schema  `error`

**Why:** Client-side validation is a convenience. Anyone can submit to the endpoint, Server Action or router action directly, skipping it. The server must `safeParse` the input with the same schema, return field errors on failure, and never trust a client-provided `id`, `role` or `price`.
**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html#implementing-input-validation · https://zod.dev/basics#handling-errors

```ts
// ❌ (Server Action / route handler)
export async function signup(values: SignupValues) {
  await db.user.create({ data: values })              // trusts whatever arrived
}

// ✅
export async function signup(input: unknown) {
  const parsed = signupSchema.safeParse(input)
  if (!parsed.success) return { ok: false as const, errors: z.flattenError(parsed.error).fieldErrors }
  await db.user.create({ data: { email: parsed.data.email, passwordHash: await hash(parsed.data.password) } })
  return { ok: true as const }
}
```

**Applies:** any form that sends data to a server · **Exceptions:** none. (Zod 3: `parsed.error.flatten().fieldErrors`.)

### REACT-FORM-003 · `register` native inputs; use `Controller` for controlled UI components  `warn`

**Why:** `register` wires up native inputs uncontrolled, through `ref`, `onChange` and `onBlur`, which is RHF's fast path. Many UI-library components (date pickers, comboboxes, sliders) don't forward a ref to a native input, or report values in a non-standard `onChange`. Spreading `register` onto them silently fails to update the form. Use `Controller` or `useController` for those, and don't wrap native inputs in `Controller` without a reason.
**Source:** https://react-hook-form.com/get-started#IntegratingControlledInputs · https://react-hook-form.com/docs/usecontroller/controller

```tsx
// ❌
<DatePicker {...register('startsOn')} />                // no ref/onChange(event) contract: value never reaches the form

// ✅
<input type="text" {...register('title')} />
<Controller
  control={control}
  name="startsOn"
  render={({ field }) => <DatePicker value={field.value} onChange={field.onChange} onBlur={field.onBlur} />}
/>
```

**Applies:** React Hook Form ≥ 7 · **Exceptions:** UI-library inputs that forward refs to a native input and emit native change events. `register` works for those, and their docs say so.

### REACT-FORM-004 · Tie each error to its input, accessibly  `warn`

**Why:** A red message under a field isn't announced to screen-reader users, and they can't tell which field it belongs to. Set `aria-invalid` on the invalid input, connect the message with `aria-describedby`, and give the message an `id` (and `role="alert"`, or a live region, when it appears after a submit). This meets WCAG 3.3.1 (Error Identification).
**Source:** https://react-hook-form.com/get-started#Handleerrors · https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html

```tsx
// ❌
<input {...register('email')} />
{errors.email && <span className="error">{errors.email.message}</span>}

// ✅
const emailId = useId()
<label htmlFor={emailId}>Email</label>
<input
  id={emailId}
  type="email"
  aria-invalid={errors.email ? 'true' : 'false'}
  aria-describedby={errors.email ? `${emailId}-error` : undefined}
  {...register('email')}
/>
{errors.email && <p id={`${emailId}-error`} role="alert">{errors.email.message}</p>}
```

**Applies:** React Hook Form ≥ 7 · **Exceptions:** an accessible UI library field component that already wires these attributes.

### REACT-FORM-005 · Watch specific fields with `useWatch`; don't `watch()` the whole form  `warn`

**Why:** `watch()` with no arguments subscribes the form component to **every** keystroke in every field, re-rendering the whole form. That defeats RHF's uncontrolled design and makes large forms lag. Subscribe to just the fields you need, ideally with `useWatch` in a small child component, so only that child re-renders.
**Source:** https://react-hook-form.com/docs/useform/watch#Rules · https://react-hook-form.com/docs/usewatch

```tsx
// ❌
const values = watch()
return <form>{/* 40 fields */}{values.plan === 'team' && <SeatsField />}</form>

// ✅
function SeatsIfTeam({ control }: { control: Control<PlanValues> }) {
  const plan = useWatch({ control, name: 'plan' })
  return plan === 'team' ? <SeatsField /> : null
}
```

**Applies:** React Hook Form ≥ 7 · **Exceptions:** a small form where whole-form re-renders don't matter. Still prefer the named-field form.

### REACT-FORM-006 · Give every field a default value; load async data with `values` or `reset`, not `setValue` in an effect  `warn`

**Why:** Fields without `defaultValues` start `undefined`, which causes uncontrolled-to-controlled warnings in `Controller` fields, and breaks `isDirty` and `reset()`. Data that arrives later (an edit form) should be passed through the `values` prop, or applied once with `reset(data)`. A loop of `setValue` calls in an effect doesn't update the defaults, so "dirty" tracking and reset are wrong.
**Source:** https://react-hook-form.com/docs/useform#defaultValues · https://react-hook-form.com/docs/useform#FieldsstayemptyafterdataloadsfromanAPI

```tsx
// ❌
const form = useForm<ProfileValues>()
useEffect(() => { if (profile) { form.setValue('name', profile.name); form.setValue('bio', profile.bio) } }, [profile, form])

// ✅
const form = useForm<ProfileValues>({
  resolver: zodResolver(profileSchema),
  defaultValues: { name: '', bio: '' },
  values: profile ? { name: profile.name, bio: profile.bio } : undefined,
})
```

**Applies:** React Hook Form ≥ 7.41 (`values`); `reset(data)` on older versions · **Exceptions:** none.

### REACT-FORM-007 · In `useFieldArray`, key rows by `field.id`  `error`

**Why:** `useFieldArray` generates a stable `id` per row for React keys. Keying by index (or by your own data id, which can be missing on new rows) makes removing or reordering rows move input values and errors into the wrong row. It's the same bug as REACT-JSX-001, inside the form state.
**Source:** https://react-hook-form.com/docs/usefieldarray#rules

```tsx
// ❌
{fields.map((field, index) => <input key={index} {...register(`items.${index}.name`)} />)}

// ✅
{fields.map((field, index) => (
  <div key={field.id}>
    <input aria-label={`Item ${index + 1} name`} {...register(`items.${index}.name`)} />
    <button type="button" onClick={() => remove(index)}>Remove</button>
  </div>
))}
```

**Applies:** React Hook Form ≥ 7 · **Exceptions:** none.

### REACT-FORM-008 · Coerce number and date inputs; HTML gives you strings  `error`

**Why:** `<input type="number">` and date inputs submit **strings**. With a `z.number()` schema, every submission fails with "expected number, received string". Without a schema, `"10" + 1` becomes `"101"`. Use `register(name, { valueAsNumber: true })` (or `valueAsDate`), or coerce in the schema (`z.coerce.number()`). On the server, `FormData` values are always strings, so coerce there too.
**Source:** https://react-hook-form.com/docs/useform/register#Anumberinputissubmittedasastring · https://zod.dev/api#coercion

```tsx
// ❌
const schema = z.object({ seats: z.number().int().min(1) })
<input type="number" {...register('seats')} />              // "3" fails z.number()

// ✅
<input type="number" {...register('seats', { valueAsNumber: true })} />
// or, when the same schema also parses FormData on the server:
const seatsSchema = z.object({ seats: z.coerce.number().int().min(1) })
```

**Applies:** React Hook Form ≥ 7, Zod ≥ 3 · **Exceptions:** fields that really are strings (phone numbers, postcodes, ids with leading zeros), which must stay strings.

### REACT-FORM-009 · Zod 4: use the v4 APIs in v4 projects  `info`

**Why:** Zod 4 moved string formats to top-level functions (`z.email()`, `z.url()`, `z.uuid()`), replaced `message` with a unified `error` parameter, and replaced `.flatten()`/`.format()` with `z.flattenError()`/`z.treeifyError()`. The v3 forms are deprecated and produce warnings. In a Zod 3 project, keep the v3 forms: the v4 functions don't exist there.
**Source:** https://zod.dev/v4/changelog#deprecates-email-etc · https://zod.dev/v4/changelog#deprecates-message-parameter · https://zod.dev/v4/changelog#deprecates-flatten

```ts
// ❌ (Zod 4)
z.string().email({ message: 'Invalid email' })
result.error.flatten()

// ✅ (Zod 4)
z.email({ error: 'Invalid email' })
z.flattenError(result.error)
```

**Applies:** Zod ≥ 4. On Zod 3, the left-hand forms are correct · **Exceptions:** none.
