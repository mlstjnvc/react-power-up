# Next.js App Router: rendering, data and caching (`REACT-NEXT-*`, part 1)

Rules for Next.js 16 App Router pages, layouts and components: server vs client components, data fetching, streaming, caching, navigation, images and metadata. Next.js 15 differences are noted.

The server side (Server Actions, route handlers, `proxy.ts`, env vars, `server-only`, what may cross to the client) is in [`nextjs-server.md`](nextjs-server.md). It shares the `NEXT` domain; ids there start at 101.

**Pages Router** (`pages/` only): detected and noted, not covered. Apply the core React rules, and don't apply these.

**Quick model:**
- Everything in `app/` is a **Server Component** unless a file starts with `'use client'`.
- Server Components can be `async` and fetch data directly. They can't use state, effects or browser APIs.
- Client Components can't be `async`. They receive only serializable props, and they're rendered on the server too, for the first HTML.

---

### REACT-NEXT-001 · Keep pages and layouts on the server; put `'use client'` on the smallest interactive leaf  `warn`

**Why:** `'use client'` marks a boundary: that file, *and everything it imports*, ships to the browser. Putting it on a page or layout sends the whole subtree as JavaScript and gives up server-side data fetching. Keep the page a Server Component, and extract only the interactive part (a button, a form, a filter) into a client component. Server content can still be passed to it as `children`.
**Source:** https://nextjs.org/docs/app/getting-started/server-and-client-components#reducing-js-bundle-size · https://nextjs.org/docs/app/getting-started/server-and-client-components#interleaving-server-and-client-components

```tsx
// ❌ app/products/page.tsx
'use client'
export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([])
  useEffect(() => { void fetch('/api/products').then((r) => r.json()).then(setProducts) }, [])
  return <><h1>Products</h1><ProductGrid products={products} /><AddToCartButton /></>
}

// ✅ app/products/page.tsx (Server Component)
export default async function ProductsPage() {
  const products = await getProducts()
  return <><h1>Products</h1><ProductGrid products={products} /></>
}
// app/products/AddToCartButton.tsx
'use client'
export function AddToCartButton({ productId }: { productId: string }) { /* useState, onClick… */ }
```

**Applies:** Next.js ≥ 13.4 App Router · **Exceptions:** context providers. They must be client components, so put them in a small `'use client'` `providers.tsx` and render it from the layout (*Context providers*).

### REACT-NEXT-002 · Props from server to client components must be serializable  `error`

**Why:** Props crossing into a `'use client'` component are serialized into the RSC payload. Functions (other than Server Actions), class instances, `Map`/`Set` and similar values can't cross, and fail at build or render time. Pass plain data (strings, numbers, arrays, plain objects, `Date`, promises for `use()`), and let the client component define its own handlers.
**Source:** https://nextjs.org/docs/app/getting-started/server-and-client-components#passing-data-from-server-to-client-components

```tsx
// ❌ (Server Component)
<ProductCard product={product} onSelect={(id) => console.log(id)} formatPrice={(n) => n.toFixed(2)} />

// ✅
<ProductCard product={{ id: product.id, name: product.name, price: product.price }} />
// ProductCard ('use client') owns its onClick and formatting
```

**Applies:** Next.js ≥ 13.4 App Router · **Exceptions:** Server Actions (functions marked `'use server'`) may be passed as props.

### REACT-NEXT-003 · Fetch in Server Components, not in client effects  `warn`

**Why:** In the App Router, a Server Component can `await` the database or API directly. The data arrives with the HTML, with no client waterfall, loading flash or exposed API endpoint. Fetching the same data in a client component's `useEffect` adds a round trip and a spinner, and needs a public route.
**Source:** https://nextjs.org/docs/app/getting-started/fetching-data#server-components

```tsx
// ❌ ('use client' component)
useEffect(() => { void fetch(`/api/orders/${id}`).then((r) => r.json()).then(setOrder) }, [id])

// ✅ (Server Component)
export default async function OrderPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const order = await getOrder(id)
  if (!order) notFound()
  return <OrderView order={order} />
}
```

**Applies:** Next.js ≥ 13.4 App Router · **Exceptions:** client-only, user-driven data (search-as-you-type, polling). Use TanStack Query in a client component (see `tanstack-query.md`, REACT-QUERY-011 for prefetching).

### REACT-NEXT-004 · Await `params`, `searchParams`, `cookies()` and `headers()`  `error`

**Why:**
- In Next.js 15+, these request-time APIs are **async**: `params` and `searchParams` are Promises, and `cookies()`, `headers()` and `draftMode()` return Promises.
- Next.js 16 **removed** the synchronous compatibility that 15 still allowed, so reading `params.id` without `await` gives `undefined`, or a type error.
**Source:** https://nextjs.org/docs/app/guides/upgrading/version-16#async-request-apis-breaking-change

```tsx
// ❌ (Next 16)
export default function Page({ params }: { params: { slug: string } }) {
  const theme = cookies().get('theme')
  return <Post slug={params.slug} theme={theme?.value} />
}

// ✅
export default async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params
  const theme = (await cookies()).get('theme')
  return <Post slug={slug} theme={theme?.value} />
}
// (or type props with the generated PageProps<'/blog/[slug]'> helper from `next typegen`)
```

**Applies:** Next.js ≥ 15 (async). Sync access was removed in 16; on 14 these are synchronous · **Exceptions:** client components, which read params with `useParams()`, or receive a Promise and unwrap it with `use()`.

### REACT-NEXT-005 · No browser-only values during render; they cause hydration mismatches  `error`

**Why:** Client components also render on the server. Reading `window`, `localStorage`, `navigator`, `Date.now()`/`Math.random()` or locale-dependent formatting during render produces different HTML on the server and the client. React then reports a hydration error, and may re-render the whole tree on the client. Read browser-only values in an effect or with `useSyncExternalStore` (with a server snapshot), or render that part client-only.
**Source:** https://nextjs.org/docs/messages/react-hydration-error#common-causes · https://nextjs.org/docs/messages/react-hydration-error#solution-1-using-useeffect-to-run-on-the-client-only

```tsx
// ❌ ('use client')
export function Greeting() {
  const name = localStorage.getItem('name') ?? 'there'      // throws on the server; mismatches on the client
  return <p>Hi {name}, it's {new Date().toLocaleTimeString()}</p>
}

// ✅
export function Greeting() {
  const [name, setName] = useState<string | null>(null)
  useEffect(() => { setName(localStorage.getItem('name')) }, [])
  return <p>Hi {name ?? 'there'}</p>
}
```

**Applies:** any SSR (Next.js App and Pages Router) · **Exceptions:** `suppressHydrationWarning` on one element whose text is expected to differ (a timestamp). Documented, but use it sparingly.

### REACT-NEXT-006 · Never keep per-request data in module scope on the server  `error`

**Why:** Server modules are loaded once and shared by **every** request. A module-level `let currentUser`, a cache `Map` keyed by nothing user-specific, or a singleton store leaks one user's data into another user's response. Per-request memoization uses `React.cache()`, which is scoped to one request. Per-request state is passed explicitly, or read from `cookies()`/`headers()`.
**Source:** https://nextjs.org/docs/app/getting-started/fetching-data#reusing-data-with-reactcache · https://nextjs.org/docs/app/guides/data-security#data-access-layer

```ts
// ❌ lib/session.ts
let currentUser: User | null = null
export async function loadUser() { currentUser = await getUserFromCookie(); return currentUser }
export function getCurrentUser() { return currentUser }       // another request's user

// ✅
import { cache } from 'react'
export const getCurrentUser = cache(async () => {
  const token = (await cookies()).get('session')?.value
  return token ? verifySession(token) : null
})
```

**Applies:** Next.js App Router (and any Node SSR) · **Exceptions:** truly global, user-independent values (config, a DB connection pool, a cache keyed by public content).

### REACT-NEXT-007 · Start independent fetches in parallel; stream slow parts with `<Suspense>`  `warn`

**Why:** Sequential `await`s in one component (`const user = await getUser(); const posts = await getPosts()`) add their latencies together, even when the second doesn't need the first. Start them together with `Promise.all`. Wrap slow, independent parts in `<Suspense>` (or add `loading.tsx` for the segment), so the rest of the page streams immediately instead of waiting for the slowest query.
**Source:** https://nextjs.org/docs/app/getting-started/fetching-data#parallel-data-fetching · https://nextjs.org/docs/app/getting-started/fetching-data#streaming

```tsx
// ❌
const artist = await getArtist(id)
const albums = await getAlbums(id)                           // waits for getArtist needlessly
const reviews = await getReviews(id)                         // slow; blocks the whole page

// ✅
const [artist, albums] = await Promise.all([getArtist(id), getAlbums(id)])
return (
  <>
    <ArtistHeader artist={artist} />
    <AlbumList albums={albums} />
    <Suspense fallback={<ReviewsSkeleton />}>
      <Reviews artistId={id} />                               {/* async Server Component */}
    </Suspense>
  </>
)
```

**Applies:** Next.js ≥ 13.4 App Router · **Exceptions:** fetches that really depend on each other.

### REACT-NEXT-008 · Next 16 caching: opt in with `cacheComponents`, cache with `"use cache"`, and keep request-time APIs out of cached scopes  `warn`

**Why:**
- In Next.js 16, caching is explicit. Enable `cacheComponents: true` (it replaces `experimental.dynamicIO`/`useCache` and PPR), then mark cached functions or components with `"use cache"`, control them with `cacheLife`/`cacheTag`, and stream everything uncached inside `<Suspense>`.
- Cache keys come from the arguments. Calling `cookies()`, `headers()` or `searchParams` *inside* a `"use cache"` scope is an error: read them outside, and pass the values in as arguments.
- On Next 15, the model is different: `fetch` cache options, `export const revalidate` and `unstable_cache`. Follow the project's version.
**Source:** https://nextjs.org/docs/app/getting-started/caching-and-revalidating#enabling-cache-components · https://nextjs.org/docs/app/api-reference/directives/use-cache#constraints · https://nextjs.org/docs/app/guides/upgrading/version-16#experimentaldynamicio-and-experimentalusecache

```tsx
// ❌ (Next 16, cacheComponents on)
async function ProductList() {
  'use cache'
  const currency = (await cookies()).get('currency')?.value  // request-time API inside a cached scope
  return <Grid products={await getProducts(currency)} />
}

// ✅
export default async function Page() {
  const currency = (await cookies()).get('currency')?.value ?? 'EUR'
  return <Suspense fallback={<GridSkeleton />}><ProductList currency={currency} /></Suspense>
}
async function ProductList({ currency }: { currency: string }) {
  'use cache'
  cacheLife('hours')
  cacheTag('products')
  return <Grid products={await getProducts(currency)} />
}
```

**Applies:** Next.js ≥ 16 with `cacheComponents: true`; Next 15 uses the older caching model · **Exceptions:** projects that haven't enabled Cache Components: don't add `"use cache"` there, and don't turn the flag on without asking, because enabling it can surface build errors across the app.

### REACT-NEXT-009 · Use `next/link` for internal navigation  `warn`

**Why:** `<a href="/dashboard">` does a full page load. It refetches the layout and its JavaScript, and loses client state and prefetching. `<Link>` does client-side transitions, prefetches visible routes, and preserves shared layouts.
**Source:** https://nextjs.org/docs/app/api-reference/components/link · https://nextjs.org/docs/app/getting-started/linking-and-navigating#client-side-transitions

```tsx
// ❌
<a href={`/orders/${order.id}`}>Open order</a>

// ✅
import Link from 'next/link'
<Link href={`/orders/${encodeURIComponent(order.id)}`}>Open order</Link>
```

**Applies:** Next.js ≥ 13 · **Exceptions:** external URLs; downloads; links that deliberately force a full reload.

### REACT-NEXT-010 · Use `next/image` with dimensions (or `fill`) and `alt`  `warn`

**Why:** A plain `<img>` ships the full-size file to every device, loads eagerly, and causes layout shift when it arrives. `next/image` serves resized, modern formats, lazy-loads below the fold, and reserves space when given `width`/`height` (or `fill` with a sized parent). Remote hosts must be allowed in `images.remotePatterns`.
**Source:** https://nextjs.org/docs/app/api-reference/components/image#alt · https://nextjs.org/docs/app/api-reference/components/image#remotepatterns

```tsx
// ❌
<img src={product.imageUrl} />

// ✅
import Image from 'next/image'
<Image src={product.imageUrl} alt={product.name} width={640} height={480} sizes="(max-width: 768px) 100vw, 640px" />
```

**Applies:** Next.js ≥ 13 · **Exceptions:** SVG icons and images whose host can't be allow-listed. Use `<img>` with `alt`, and an explicit size.

### REACT-NEXT-011 · Set titles and meta tags with `metadata` or `generateMetadata`  `warn`

**Why:** In the App Router, `<head>` content comes from the `metadata` export (static) or `generateMetadata` (dynamic, with the same `params`). They merge across layouts and are emitted in the initial HTML for crawlers. Hand-written `<head>` tags in pages, or `next/head`, don't work in `app/`.
**Source:** https://nextjs.org/docs/app/getting-started/metadata-and-og-images#generated-metadata · https://nextjs.org/docs/app/api-reference/functions/generate-metadata

```tsx
// ❌ app/blog/[slug]/page.tsx
import Head from 'next/head'
<Head><title>{post.title}</title></Head>

// ✅
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params
  const post = await getPost(slug)
  return { title: post?.title ?? 'Post not found', description: post?.excerpt }
}
```

**Applies:** Next.js ≥ 13.2 App Router · **Exceptions:** React 19's in-component `<title>` is fine for client-only state (an unread count). Prefer `metadata` for SEO-relevant tags.

### REACT-NEXT-012 · Give segments `error.tsx` (a client component) and `not-found`/`loading` where needed  `warn`

**Why:** Without an `error.tsx`, an error thrown in a segment shows the generic error page and loses the surrounding layout. `error.tsx` must start with `'use client'`, and receives `error` and `reset`. Call `notFound()` for missing data, so the nearest `not-found.tsx` renders with a 404 status. `loading.tsx` wraps the segment in `<Suspense>` for instant loading UI.
**Source:** https://nextjs.org/docs/app/api-reference/file-conventions/error · https://nextjs.org/docs/app/api-reference/file-conventions/loading

```tsx
// ❌ app/orders/[id]/page.tsx
const order = await getOrder(id)
return <OrderView order={order!} />                          // crashes on a missing order

// ✅
const order = await getOrder(id)
if (!order) notFound()
return <OrderView order={order} />
// app/orders/error.tsx
'use client'
export default function OrdersError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return <div role="alert"><p>Couldn't load orders.</p><button type="button" onClick={reset}>Try again</button></div>
}
```

**Applies:** Next.js ≥ 13.4 App Router · **Exceptions:** a root-level `error.tsx`/`global-error.tsx` that already covers simple apps.
