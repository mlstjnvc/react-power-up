#!/usr/bin/env bash
# React + Vite SPA ("@tanstack/react-query": "^5.90.0", "@tanstack/react-router": "^1.130.0", "zod": "^4.1.0", ), TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p src/routes src/api
cat > package.json <<'JSON'
{
  "name": "catalog", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "@tanstack/react-query": "^5.90.0", "@tanstack/react-router": "^1.130.0", "zod": "^4.1.0", "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@tanstack/router-plugin": "^1.130.0", "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > vite.config.ts <<'TS'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { tanstackRouter } from '@tanstack/router-plugin/vite'
export default defineConfig({ plugins: [tanstackRouter({ target: 'react', autoCodeSplitting: true }), react()] })
TS
cat > src/api/products.ts <<'TS'
export interface Product { id: string; name: string; price: number; category: 'books' | 'games' | 'music' }
export interface ProductPage { items: Product[]; page: number; pageCount: number }
export async function fetchProducts(params: { page: number; category?: Product['category']; q?: string }, signal?: AbortSignal): Promise<ProductPage> {
  const qs = new URLSearchParams({ page: String(params.page) })
  if (params.category) qs.set('category', params.category)
  if (params.q) qs.set('q', params.q)
  const res = await fetch(`/api/products?${qs}`, { signal })
  if (!res.ok) throw new Error(`Failed to load products (${res.status})`)
  return (await res.json()) as ProductPage
}
TS
cat > src/routes/__root.tsx <<'TSX'
import { createRootRouteWithContext, Outlet } from '@tanstack/react-router'
import type { QueryClient } from '@tanstack/react-query'
export interface RouterContext { queryClient: QueryClient }
export const Route = createRootRouteWithContext<RouterContext>()({ component: () => <main><Outlet /></main> })
TSX
cat > src/routes/index.tsx <<'TSX'
import { createFileRoute, Link } from '@tanstack/react-router'
export const Route = createFileRoute('/')({ component: () => <Link to="/">Home</Link> })
TSX
cat > src/main.tsx <<'TSX'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { createRouter, RouterProvider } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'

const queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 30_000 } } })
const router = createRouter({ routeTree, context: { queryClient } })
declare module '@tanstack/react-router' { interface Register { router: typeof router } }

createRoot(document.getElementById('root')!).render(
  <StrictMode><QueryClientProvider client={queryClient}><RouterProvider router={router} /></QueryClientProvider></StrictMode>,
)
TSX
# REACT-TSR-004 (loader reads search without loaderDeps), REACT-TSR-003 (raw search), REACT-TSR-005 (template-string link)
cat > src/routes/products.tsx <<'TSX'
import { createFileRoute, Link, useSearch } from '@tanstack/react-router'
import { fetchProducts } from '../api/products'

export const Route = createFileRoute('/products')({
  loader: () => {
    const page = Number(new URLSearchParams(window.location.search).get('page') ?? 1)
    return fetchProducts({ page })
  },
  component: Products,
})

function Products() {
  const data = Route.useLoaderData()
  const search = useSearch({ strict: false }) as { page?: string }
  const page = Number(search.page)
  return (
    <section>
      <ul>{data.items.map((p) => <li key={p.id}><Link to={`/products/${p.id}`}>{p.name}</Link></li>)}</ul>
      <Link to="/products" search={{ page: page + 1 }}>Next</Link>
    </section>
  )
}
TSX
# REACT-TSR-006 (auth check in the component)
cat > src/routes/account.tsx <<'TSX'
import { createFileRoute, Navigate } from '@tanstack/react-router'
import { useAuth } from '../auth'

export const Route = createFileRoute('/account')({ component: Account })

function Account() {
  const { user } = useAuth()
  if (!user) return <Navigate to="/" />
  return <h1>Account of {user.name}</h1>
}
TSX
cat > src/auth.ts <<'TS'
export declare function useAuth(): { user: { name: string } | null }
TS
