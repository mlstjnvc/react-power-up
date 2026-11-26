# Security (`REACT-SEC-*`)

Cross-cutting security rules for React apps: XSS sinks, URLs, redirects, secrets, authorization, SSRF, token storage and CSRF. Framework-specific forms live in their domains, and this file links to them instead of repeating them:
- **Next.js server:** REACT-NEXT-101 (action auth), -102 (validation), -103 (data exposure), -105 (`NEXT_PUBLIC_`), -106 (route handlers), -109 (layout auth), -111 (session cookies)
- **Forms:** REACT-FORM-002 (server re-validation)
- **Redirects:** REACT-RR-005 (React Router), REACT-TSR-006 (TanStack Router)
- **SSR leaks:** REACT-STATE-006, REACT-QUERY-003, REACT-NEXT-006 (per-request state).

**The security pass:** for every new data flow, name the source (user input, URL, params, API response, storage, CMS) and the sink. Then check the matching rule below.

---

### REACT-SEC-001 · Never pass untrusted content to `dangerouslySetInnerHTML`  `error`

**Why:** React escapes everything rendered as text, which is its main XSS defense. `dangerouslySetInnerHTML` switches that off. User bios, comments, CMS fields, Markdown output and API strings rendered through it can run scripts (`<img src=x onerror=…>`) in your users' sessions. Render untrusted content as text. When HTML is truly required, sanitize it with a vetted sanitizer (the project's, or one the user approves; never add one unasked), and render Markdown with a renderer that doesn't allow raw HTML.
**Source:** https://react.dev/reference/react-dom/components/common#dangerously-setting-the-inner-html · https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#html-sanitization

```tsx
// ❌
<div dangerouslySetInnerHTML={{ __html: user.bio }} />

// ✅ text is enough
<p className="bio">{user.bio}</p>

// ✅ HTML really needed, sanitizer already in the project (e.g. DOMPurify)
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(post.html) }} />
```

**Applies:** React (all versions) · **Exceptions:** HTML your own code produces from trusted, static input (e.g. a build-time-rendered docs page).

### REACT-SEC-002 · Validate the scheme of user-supplied URLs before `href`, `src` or `action`  `error`

**Why:** JSX escapes attribute *text*, but it doesn't make a URL safe. `href="javascript:alert(document.cookie)"` or `data:text/html,…` taken from a profile "website" field runs script when clicked. Parse with `new URL()` and allow only `https:` (and `http:`/`mailto:` if needed). Otherwise render plain text.
**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#output-encoding-for-url-contexts · https://cheatsheetseries.owasp.org/cheatsheets/DOM_based_XSS_Prevention_Cheat_Sheet.html#rule-5-url-escape-then-javascript-escape-before-inserting-untrusted-data-into-url-attribute-subcontext-within-the-execution-context

```tsx
// ❌
<a href={profile.website}>{profile.website}</a>

// ✅
function safeHttpUrl(value: string): string | null {
  try {
    const url = new URL(value)
    return url.protocol === 'https:' || url.protocol === 'http:' ? url.toString() : null
  } catch {
    return null
  }
}
const website = safeHttpUrl(profile.website)
{website ? <a href={website} rel="noopener noreferrer" target="_blank">{website}</a> : <span>{profile.website}</span>}
```

**Applies:** React (all versions) · **Exceptions:** URLs your code builds from constants and encoded parameters (`` `/orders/${encodeURIComponent(id)}` ``).

### REACT-SEC-003 · Only redirect to validated same-site paths, in every router  `error`

**Why:** A `?next=`, `?redirect=` or `returnTo` value passed to `navigate()`, `router.push()`, Next.js `redirect()`, TanStack Router's `redirect()` or `window.location` is an **open redirect**, a ready-made phishing link on your domain. Allow only relative paths that start with a single `/`. React Router's form, with a `safeRedirect` helper, is REACT-RR-005, and the same helper works everywhere.
**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html

```ts
// ❌ (Next.js Server Action)
redirect(String(formData.get('next') ?? '/'))

// ✅
redirect(safeRedirect(formData.get('next')?.toString() ?? null))   // safeRedirect: see REACT-RR-005
```

**Applies:** any router (Next.js, React Router, TanStack Router, plain `window.location`) · **Exceptions:** an explicit allow-list of external hosts, checked by parsing with `new URL()`.

### REACT-SEC-004 · Keep secrets out of client code and client-exposed env vars  `error`

**Why:**
- Everything in the browser bundle is public: hard-coded keys, `VITE_*` and `NEXT_PUBLIC_*` variables (inlined at build time), and values passed to client components.
- A secret API key used from the browser can be copied and abused.
- Call third-party APIs that need a secret from a server endpoint (a route handler, Server Action or backend), and keep the key in a non-public variable.
**Source:** https://vite.dev/guide/env-and-mode#env-variables · https://nextjs.org/docs/app/guides/environment-variables#bundling-environment-variables-for-the-browser

```ts
// ❌ (Vite SPA)
const res = await fetch('https://api.payments.example/charges', {
  headers: { Authorization: `Bearer ${import.meta.env.VITE_PAYMENTS_SECRET_KEY}` },
})

// ✅ (client calls your server; the server holds the key)
const res = await fetch('/api/charges', { method: 'POST', body: JSON.stringify({ orderId }) })
```

**Applies:** any bundler (Vite, Next.js, webpack) · **Exceptions:** keys designed to be public (publishable payment keys, maps keys restricted by referrer, analytics ids).

### REACT-SEC-005 · Client-side guards are UX; the server authorizes every request  `error`

**Why:** Hiding a button, a route guard (`beforeLoad`, a protected-route wrapper), a `proxy.ts` redirect, or `if (user.role === 'admin')` in a component all run in, or can be bypassed from, the browser. Every API endpoint, Server Action, route handler and loader that touches protected data must check the session and the user's permission on the resource, server-side, on every request.
**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html#validate-the-permissions-on-every-request · https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html#verify-that-authorization-checks-are-performed-in-the-right-location

```tsx
// ❌
{user.role === 'admin' && <button type="button" onClick={() => fetch(`/api/users/${id}`, { method: 'DELETE' })}>Delete</button>}
// …and the DELETE /api/users/:id handler doesn't check the role

// ✅ keep the UI check, and enforce on the server
export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const user = await getCurrentUser()
  if (user?.role !== 'admin') return new Response('Forbidden', { status: 403 })
  // …
}
```

**Applies:** any React app with a backend · **Exceptions:** none. (The Next.js forms are REACT-NEXT-101, -106 and -109.)

### REACT-SEC-006 · Don't fetch user-supplied URLs from the server (SSRF)  `error`

**Why:** A server-side `fetch(userUrl)` (link previews, "import from URL", webhooks, image proxies) lets an attacker make your server call internal services, cloud metadata endpoints (`169.254.169.254`) or `localhost` admin panels. Allow-list the hosts you call, or fetch only URLs your own code constructs. Never pass a raw URL from the request.
**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html#case-1-application-can-send-request-only-to-identified-and-trusted-applications

```ts
// ❌ (route handler / Server Action)
const target = new URL(req.url).searchParams.get('url')!
const html = await (await fetch(target)).text()

// ✅
const ALLOWED_HOSTS = new Set(['images.example-cdn.com', 'api.partner.example'])
const target = new URL(new URL(req.url).searchParams.get('url') ?? '', 'https://invalid.invalid')
if (target.protocol !== 'https:' || !ALLOWED_HOSTS.has(target.hostname)) return new Response('Bad request', { status: 400 })
const res = await fetch(target, { redirect: 'error' })
```

**Applies:** any server code (Next.js, React Router actions and loaders on a server, Node backends) · **Exceptions:** none. If arbitrary URLs are a product requirement, the network-level protections in the cheat sheet are needed, which is beyond a code change.

### REACT-SEC-007 · Never evaluate user input as code  `error`

**Why:** `eval`, `new Function`, `setTimeout('string')`, and dynamic `import()` of a user-controlled path execute attacker-chosen code with full access to the page or the server. Parse data (`JSON.parse`, then a schema). Choose behaviour with a lookup table keyed by validated values.
**Source:** https://cheatsheetseries.owasp.org/cheatsheets/DOM_based_XSS_Prevention_Cheat_Sheet.html#rule-3-be-careful-when-inserting-untrusted-data-into-the-event-handler-and-javascript-code-subcontexts-within-an-execution-context

```ts
// ❌
const result = new Function('row', `return ${formula}`)(row)     // formula typed by the user
const widget = await import(`./widgets/${params.get('widget')}`)

// ✅
const formulas = { total: (r: Row) => r.qty * r.price, tax: (r: Row) => r.qty * r.price * 0.2 } as const
const key = formulaKey.parse(params.get('formula'))              // z.enum(['total', 'tax'])
const result = formulas[key](row)
```

**Applies:** any JavaScript · **Exceptions:** none.

### REACT-SEC-008 · Don't keep session tokens in `localStorage`  `warn`

**Why:** Anything in `localStorage` or `sessionStorage` is readable by any script on the page, so a single XSS bug, or a compromised third-party script, exfiltrates the token. Prefer server-set `httpOnly`, `secure`, `sameSite` cookies (REACT-NEXT-111 for Next.js). If the architecture requires bearer tokens in the SPA, keep them in memory with short lifetimes.
**Source:** https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html#local-storage

```ts
// ❌
localStorage.setItem('accessToken', token)

// ✅ the server sets the cookie on login; the client just calls the API with credentials
await fetch('/api/login', { method: 'POST', body: JSON.stringify(credentials), credentials: 'include' })
```

**Applies:** browser apps · **Exceptions:** non-sensitive data (UI preferences, drafts).

### REACT-SEC-009 · Change state only with non-GET requests, and protect cookie-authenticated endpoints from CSRF  `warn`

**Why:** A `GET /api/delete-account` can be triggered by any `<img src>` on any site, using the victim's cookies. Mutations use `POST`/`PUT`/`PATCH`/`DELETE`. Cookie-authenticated endpoints add CSRF defenses: `sameSite` cookies plus an `Origin` check, or a CSRF token. Next.js Server Actions only accept `POST` and compare `Origin` with `Host`. Route handlers and custom backends must do it themselves.
**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#fetch-metadata-headers · https://nextjs.org/docs/app/guides/data-security#built-in-server-actions-security-features

```ts
// ❌
export async function GET(req: Request) { await unsubscribeAll(await requireUser()); return new Response('ok') }

// ✅
export async function POST(req: Request) {
  const origin = req.headers.get('origin')
  if (origin !== new URL(req.url).origin) return new Response('Forbidden', { status: 403 })
  await unsubscribeAll(await requireUser())
  return new Response(null, { status: 204 })
}
```

**Applies:** any cookie-authenticated backend · **Exceptions:** token-in-header APIs (no cookies), which aren't vulnerable to classic CSRF.
