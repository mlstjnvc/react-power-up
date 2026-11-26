#!/usr/bin/env bash
# React 19 + Vite SPA with TanStack Query v5 already set up (no node_modules).
set -euo pipefail
mkdir -p src/components
cat > package.json <<'JSON'
{
  "name": "store", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "@tanstack/react-query": "^5.90.0", "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/main.tsx <<'TSX'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { App } from './App'

const queryClient = new QueryClient()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </StrictMode>,
)
TSX
cat > src/App.tsx <<'TSX'
export function App() {
  return <main><h1>Store</h1></main>
}
TSX
cat > src/api.ts <<'TS'
export interface Product { id: string; name: string; price: number }

export async function searchProducts(query: string, signal?: AbortSignal): Promise<Product[]> {
  const res = await fetch(`/api/products?q=${encodeURIComponent(query)}`, { signal })
  if (!res.ok) throw new Error(`Search failed: ${res.status}`)
  return (await res.json()) as Product[]
}
TS
