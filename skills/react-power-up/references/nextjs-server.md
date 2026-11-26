# Next.js App Router: server side (`REACT-NEXT-*`, part 2: ids 101+)

Rules for Server Actions (Server Functions), route handlers, `proxy.ts`, environment variables, server-only code, sessions, and what data may leave the server. Rendering rules (001–012) are in [`nextjs.md`](nextjs.md).

**The model to keep in mind:**
- A Server Action is a **public HTTP endpoint**. Anyone can call it with any arguments, even though it looks like a function call.
- A route handler is a public endpoint too.
- Props passed to client components and values returned from actions are **sent to the browser**.

So every server entry point validates its input, checks who's calling, and returns only what the caller needs.

---

### REACT-NEXT-101 · Authenticate and authorize inside every Server Action  `error`

**Why:** Hiding a button doesn't protect the action behind it. The action's endpoint can be called directly, with any arguments, by anyone. Each action must read the session itself (from cookies, never from a parameter), check that the user may do *this* operation on *this* resource, and fail closed.
**Source:** https://nextjs.org/docs/app/api-reference/directives/use-server#security-considerations · https://nextjs.org/docs/app/guides/data-security#authentication-and-authorization

```ts
// ❌ app/projects/actions.ts
'use server'
export async function deleteProject(projectId: string) {
  await db.project.delete({ where: { id: projectId } })   // anyone can delete any project
}

// ✅
'use server'
export async function deleteProject(projectId: unknown) {
  const user = await getCurrentUser()                      // reads the session cookie
  if (!user) throw new Error('Unauthorized')
  const id = z.uuid().parse(projectId)
  const project = await db.project.findUnique({ where: { id } })
  if (!project || project.ownerId !== user.id) throw new Error('Forbidden')
  await db.project.delete({ where: { id } })
  updateTag(`projects:${user.id}`)
}
```

**Applies:** Next.js ≥ 14 (Server Actions), React ≥ 19 · **Exceptions:** genuinely public actions (a newsletter sign-up). They still validate input and should be rate-limited.

### REACT-NEXT-102 · Validate every Server Action and route-handler input at runtime  `error`

**Why:** TypeScript parameter types don't exist at runtime. An action declared `(input: { qty: number })` receives whatever the client sends: strings, negative numbers, extra fields such as `role: 'admin'`. Parse inputs with a schema (`safeParse`), and use only the parsed values. For forms, reuse the client schema (REACT-FORM-002).
**Source:** https://nextjs.org/docs/app/guides/data-security#validating-client-input

```ts
// ❌
'use server'
export async function updateQuantity(input: { itemId: string; qty: number }) {
  await db.cartItem.update({ where: { id: input.itemId }, data: { qty: input.qty } })
}

// ✅
const updateQuantityInput = z.object({ itemId: z.uuid(), qty: z.number().int().min(1).max(99) })
export async function updateQuantity(input: unknown) {
  const user = await requireUser()
  const parsed = updateQuantityInput.safeParse(input)
  if (!parsed.success) return { ok: false as const, error: 'Invalid quantity' }
  await db.cartItem.updateMany({ where: { id: parsed.data.itemId, cart: { userId: user.id } }, data: { qty: parsed.data.qty } })
  return { ok: true as const }
}
```

**Applies:** Next.js ≥ 14 · **Exceptions:** none.

### REACT-NEXT-103 · Send only what the client needs: minimal props and action results (DTOs)  `error`

**Why:** Passing a whole DB record to a client component, or returning it from an action, serializes **every field** into the RSC payload or the response: password hashes, emails, internal costs, other users' data. It's visible in DevTools even if the UI never shows it. Map to a small object (a DTO) with just the fields the client renders.
**Source:** https://nextjs.org/docs/app/guides/data-security#passing-data-from-server-to-client · https://nextjs.org/docs/app/guides/data-security#controlling-return-values

```tsx
// ❌ (Server Component)
const user = await db.user.findUnique({ where: { id } })      // includes passwordHash, email, stripeId…
return <ProfileCard user={user} />                              // 'use client'

// ✅
const user = await db.user.findUnique({ where: { id }, select: { id: true, displayName: true, avatarUrl: true } })
if (!user) notFound()
return <ProfileCard user={{ id: user.id, name: user.displayName, avatarUrl: user.avatarUrl }} />
```

**Applies:** Next.js ≥ 13.4 App Router · **Exceptions:** none. (`experimental_taintObjectReference` can add a safety net, but doesn't replace selecting the fields.)

### REACT-NEXT-104 · Mark server-only modules with `import 'server-only'`  `warn`

**Why:** A module that reads secrets or the database can be imported by accident from a `'use client'` file. Next.js then bundles it for the browser: the import may fail at runtime, or worse, ship code paths and non-public env references. `import 'server-only'` at the top makes any client import a **build error**.
**Source:** https://nextjs.org/docs/app/guides/data-security#preventing-client-side-execution-of-server-only-code · https://nextjs.org/docs/app/getting-started/server-and-client-components#preventing-environment-poisoning

```ts
// ❌ lib/billing.ts
export async function chargeCustomer(id: string) { /* uses process.env.STRIPE_SECRET_KEY */ }

// ✅
import 'server-only'
export async function chargeCustomer(id: string) { /* uses process.env.STRIPE_SECRET_KEY */ }
```

**Applies:** Next.js ≥ 13.4 App Router (the `server-only` package is the documented mechanism; never add it unasked) · **Exceptions:** files that already start with `'use server'`, which are server-only by definition.

### REACT-NEXT-105 · Never put secrets in `NEXT_PUBLIC_` variables  `error`

**Why:** Next.js inlines every `process.env.NEXT_PUBLIC_*` value into the browser bundle **at build time**. A `NEXT_PUBLIC_STRIPE_SECRET`, an `NEXT_PUBLIC_API_TOKEN` or a database URL becomes public to every visitor, and stays in old bundles after rotation. Secrets stay in non-prefixed variables, read only on the server.
**Source:** https://nextjs.org/docs/app/guides/environment-variables#bundling-environment-variables-for-the-browser

```ts
// ❌ .env / client code
NEXT_PUBLIC_OPENAI_API_KEY=sk-…
const res = await fetch('https://api.openai.com/v1/…', { headers: { Authorization: `Bearer ${process.env.NEXT_PUBLIC_OPENAI_API_KEY}` } })

// ✅ server-only (route handler or Server Action), with a non-public variable
import 'server-only'
const res = await fetch('https://api.openai.com/v1/…', { headers: { Authorization: `Bearer ${process.env.OPENAI_API_KEY}` } })
```

**Applies:** Next.js (all versions); the same applies to `VITE_*` in Vite apps · **Exceptions:** values that are public by design: a publishable key, an analytics site id, a public API base URL.

### REACT-NEXT-106 · Route handlers validate input and check auth like any API  `error`

**Why:** `app/**/route.ts` handlers are plain HTTP endpoints. Body, query string and dynamic params are untrusted. Read the session from cookies, validate with a schema, return proper status codes (400/401/403/404), and never echo internal errors.
**Source:** https://nextjs.org/docs/app/guides/authentication#route-handlers · https://nextjs.org/docs/app/api-reference/file-conventions/route#request-body

```ts
// ❌ app/api/invoices/[id]/route.ts
export async function GET(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  return Response.json(await db.invoice.findUnique({ where: { id } }))
}

// ✅
export async function GET(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const user = await getCurrentUser()
  if (!user) return new Response('Unauthorized', { status: 401 })
  const parsed = z.uuid().safeParse((await params).id)
  if (!parsed.success) return new Response('Not found', { status: 404 })
  const invoice = await db.invoice.findFirst({ where: { id: parsed.data, ownerId: user.id }, select: { id: true, total: true, status: true } })
  return invoice ? Response.json(invoice) : new Response('Not found', { status: 404 })
}
```

**Applies:** Next.js ≥ 13.4 App Router (`params` is a Promise in ≥ 15) · **Exceptions:** public, read-only endpoints. They still validate input.

### REACT-NEXT-107 · Call `redirect()` and `notFound()` outside `try`/`catch`  `error`

**Why:** `redirect()` and `notFound()` work by **throwing** a special error that Next.js handles. Inside a `try` block, your `catch` swallows it, so the redirect silently doesn't happen, and the code after it runs. Put the redirect after the `try`/`catch`.
**Source:** https://nextjs.org/docs/app/api-reference/functions/redirect#behavior

```ts
// ❌
'use server'
export async function createPost(formData: FormData) {
  try {
    const post = await savePost(parsePost(formData))
    redirect(`/posts/${post.id}`)
  } catch (err) {
    return { error: 'Could not save' }                        // also catches the redirect
  }
}

// ✅
export async function createPost(formData: FormData) {
  let postId: string
  try {
    postId = (await savePost(parsePost(formData))).id
  } catch {
    return { error: 'Could not save' }
  }
  redirect(`/posts/${postId}`)
}
```

**Applies:** Next.js ≥ 13.4 App Router · **Exceptions:** a `catch` that rethrows anything that isn't its own error (e.g. via `unstable_rethrow`), when the redirect must stay inside.

### REACT-NEXT-108 · Next 16: use `proxy.ts`, and keep it to optimistic checks  `warn`

**Why:**
- Next.js 16 renamed `middleware.ts` to **`proxy.ts`**, with the exported function `proxy`. It runs on the Node.js runtime only; `middleware.ts` (deprecated) remains for the Edge runtime.
- Either way, it runs before routes, on every matched request, and can't fully protect data: matchers can miss paths, and Server Actions post to the page's route.
- Use it for **optimistic** redirects (no session cookie → `/login`), and do the real authorization next to the data (REACT-NEXT-101, -109).
**Source:** https://nextjs.org/docs/app/api-reference/file-conventions/proxy#migration-to-proxy · https://nextjs.org/docs/app/guides/authentication#optimistic-checks-with-proxy-optional

```ts
// ❌ (Next 16) middleware.ts doing the only auth check, with a DB lookup
export async function middleware(req: NextRequest) { const user = await db.session.find(req.cookies.get('sid')?.value); /* … */ }

// ✅ proxy.ts
import { NextResponse, type NextRequest } from 'next/server'
export function proxy(req: NextRequest) {
  if (!req.cookies.has('session') && req.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', req.url))
  }
  return NextResponse.next()
}
export const config = { matcher: ['/dashboard/:path*'] }
```

**Applies:** Next.js ≥ 16 (`proxy.ts`); on 15, the same advice applies to `middleware.ts` · **Exceptions:** Edge-runtime needs, which keep `middleware.ts` on 16.

### REACT-NEXT-109 · Don't rely on layouts for auth; check where the data is read  `error`

**Why:** Layouts don't re-render on client navigation, and a layout that returns "please sign in" doesn't stop its child pages and parallel slots from rendering, or from appearing in the RSC payload. Put auth checks in the page, and in the data-access functions it calls, so protected data is never fetched for the wrong user.
**Source:** https://nextjs.org/docs/app/guides/authentication#layouts-and-auth-checks · https://nextjs.org/docs/app/guides/data-security#data-access-layer

```tsx
// ❌ app/admin/layout.tsx
export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser()
  if (user?.role !== 'admin') return <p>Forbidden</p>          // child pages still render and fetch
  return <>{children}</>
}

// ✅ lib/dal.ts
import 'server-only'
export async function getAllUsers() {
  const user = await getCurrentUser()
  if (user?.role !== 'admin') throw new Error('Forbidden')
  return db.user.findMany({ select: { id: true, displayName: true } })
}
```

**Applies:** Next.js ≥ 13.4 App Router · **Exceptions:** layouts may still *show* user-specific chrome; just don't treat them as the gate.

### REACT-NEXT-110 · After a mutation, revalidate what changed (Next 16: `updateTag` or `revalidateTag(tag, profile)`)  `warn`

**Why:**
- Cached pages and data don't know about your mutation. Without revalidation, the user saves and still sees the old value.
- **Next 16:** in a Server Action, `updateTag(tag)` gives read-your-own-writes, and `revalidateTag(tag, 'max')` marks data stale-while-revalidate. `revalidateTag` now **requires** the profile argument; the one-argument form is deprecated and a type error.
- **Next 15:** `revalidateTag(tag)` or `revalidatePath(path)`.
**Source:** https://nextjs.org/docs/app/api-reference/functions/updateTag#when-to-use-updatetag · https://nextjs.org/docs/app/guides/upgrading/version-16#revalidatetag

```ts
// ❌ (Next 16)
'use server'
export async function renameProject(input: unknown) {
  /* …auth, validate, update… */
  revalidateTag('projects')                                     // deprecated one-arg form
}

// ✅ (Next 16)
'use server'
export async function renameProject(input: unknown) {
  /* …auth, validate, update… */
  updateTag('projects')                                         // the user sees their change immediately
}
```

**Applies:** Next.js ≥ 16 for `updateTag` and the two-argument `revalidateTag`; ≥ 13.4 for `revalidatePath` · **Exceptions:** data that isn't cached (fully dynamic routes), where revalidation is unnecessary.

### REACT-NEXT-111 · Set session cookies server-side with `httpOnly`, `secure` and `sameSite`  `error`

**Why:** A session token readable by JavaScript (no `httpOnly`) can be stolen by any XSS. Without `secure`, it travels over plain HTTP. Without `sameSite`, cross-site requests carry it (CSRF). Set session cookies only on the server, with `(await cookies()).set(…)` in a Server Action or route handler, never from client code or `localStorage`.
**Source:** https://nextjs.org/docs/app/guides/authentication#setting-cookies-recommended-options · https://nextjs.org/docs/app/api-reference/functions/cookies#setting-a-cookie

```ts
// ❌ (client)
document.cookie = `session=${token}`
localStorage.setItem('token', token)

// ✅ (Server Action / route handler)
;(await cookies()).set('session', sessionToken, {
  httpOnly: true, secure: true, sameSite: 'lax', path: '/', expires: expiresAt,
})
```

**Applies:** Next.js ≥ 13.4 App Router (`cookies()` is async in ≥ 15) · **Exceptions:** non-sensitive preference cookies (theme), which may be client-set.
