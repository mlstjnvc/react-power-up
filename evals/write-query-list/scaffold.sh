#!/usr/bin/env bash
# React 19 + Vite SPA with TanStack Query 5 provider set up (no node_modules).
set -euo pipefail
mkdir -p src/components src/api
cat > package.json <<'JSON'
{
  "name": "orders", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "@tanstack/react-query": "^5.90.0", "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/api/orders.ts <<'TS'
export type OrderStatus = 'open' | 'shipped' | 'cancelled'
export interface Order { id: string; customer: string; total: number; status: OrderStatus }
export interface OrderPage { orders: Order[]; page: number; pageCount: number }

export async function fetchOrders(params: { page: number; status: OrderStatus | 'all' }, signal?: AbortSignal): Promise<OrderPage> {
  const qs = new URLSearchParams({ page: String(params.page), status: params.status })
  const res = await fetch(`/api/orders?${qs}`, { signal })
  if (!res.ok) throw new Error(`Failed to load orders (${res.status})`)
  return (await res.json()) as OrderPage
}

export async function cancelOrder(id: string): Promise<Order> {
  const res = await fetch(`/api/orders/${encodeURIComponent(id)}/cancel`, { method: 'POST' })
  if (!res.ok) throw new Error(`Failed to cancel order (${res.status})`)
  return (await res.json()) as Order
}
TS
cat > src/main.tsx <<'TSX'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { App } from './App'
const queryClient = new QueryClient()
createRoot(document.getElementById('root')!).render(<StrictMode><QueryClientProvider client={queryClient}><App /></QueryClientProvider></StrictMode>)
TSX
cat > src/App.tsx <<'TSX'
export function App() { return <main><h1>Orders</h1></main> }
TSX
