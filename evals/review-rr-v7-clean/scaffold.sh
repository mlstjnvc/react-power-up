#!/usr/bin/env bash
# React + Vite SPA ("react-router-dom": "^7.9.0", ), TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p src/routes
cat > package.json <<'JSON'
{
  "name": "legacy", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react-router-dom": "^7.9.0", "react": "^18.3.1", "react-dom": "^18.3.1" },
  "devDependencies": { "@types/react": "^18.3.3", "@types/react-dom": "^18.3.3", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/routes/orders.tsx <<'TSX'
import { forwardRef } from 'react'
import { Link, useLoaderData, useRouteError, isRouteErrorResponse } from 'react-router-dom'

export interface Order { id: string; customer: string }

export async function ordersLoader(): Promise<Order[]> {
  const res = await fetch('/api/orders')
  if (!res.ok) throw new Response('Failed to load orders', { status: res.status })
  return (await res.json()) as Order[]
}

export const SearchBox = forwardRef<HTMLInputElement, { label: string }>(function SearchBox({ label }, ref) {
  return <label>{label} <input ref={ref} type="search" /></label>
})

export function Orders() {
  const orders = useLoaderData() as Order[]
  return (
    <section>
      <SearchBox label="Search orders" />
      <ul>
        {orders.map((o) => (
          <li key={o.id}><Link to={`/orders/${encodeURIComponent(o.id)}`}>{o.customer}</Link></li>
        ))}
      </ul>
    </section>
  )
}

export function OrdersError() {
  const error = useRouteError()
  return <p role="alert">{isRouteErrorResponse(error) ? `${error.status} ${error.statusText}` : 'Something went wrong.'}</p>
}
TSX
