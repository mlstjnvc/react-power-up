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
