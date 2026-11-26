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
# REACT-QUERY-003: QueryClient created during render
cat > src/Providers.tsx <<'TSX'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
export function Providers({ children }: { children: React.ReactNode }) {
  const queryClient = new QueryClient()
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
}
TSX
# REACT-QUERY-001 (key misses page/status), REACT-QUERY-005 (onSuccess on useQuery), REACT-QUERY-006 (mutation without invalidation)
cat > src/components/OrdersTable.tsx <<'TSX'
import { useState } from 'react'
import { useMutation, useQuery } from '@tanstack/react-query'
import { cancelOrder, fetchOrders, type OrderStatus } from '../api/orders'

export function OrdersTable() {
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState<OrderStatus | 'all'>('all')
  const [lastLoaded, setLastLoaded] = useState<number | null>(null)

  const { data, isPending } = useQuery({
    queryKey: ['orders'],
    queryFn: () => fetchOrders({ page, status }),
    onSuccess: () => setLastLoaded(Date.now()),
  })

  const cancel = useMutation({ mutationFn: cancelOrder })

  if (isPending) return <p>Loading…</p>
  return (
    <section>
      <select aria-label="Status" value={status} onChange={(e) => setStatus(e.currentTarget.value as OrderStatus | 'all')}>
        <option value="all">All</option><option value="open">Open</option><option value="shipped">Shipped</option>
      </select>
      <ul>
        {data?.orders.map((o) => (
          <li key={o.id}>{o.customer} {o.total} {o.status}
            {o.status === 'open' && <button type="button" onClick={() => cancel.mutate(o.id)}>Cancel</button>}
          </li>
        ))}
      </ul>
      <button type="button" onClick={() => setPage((p) => p + 1)}>Next</button>
      {lastLoaded && <small>Loaded {new Date(lastLoaded).toLocaleTimeString()}</small>}
    </section>
  )
}
TSX
