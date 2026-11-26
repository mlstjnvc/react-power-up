#!/usr/bin/env bash
# pnpm monorepo, no node_modules: apps/web = Next.js 16 App Router, apps/admin = Vite + React Router v8 (library/data mode).
# The root package.json has no framework deps, so project type must come from the nearest package.json (R6).
set -euo pipefail
mkdir -p apps/web/app apps/admin/src/routes
cat > package.json <<'JSON'
{ "name": "acme", "private": true, "packageManager": "pnpm@10.4.0", "scripts": { "typecheck": "pnpm -r typecheck" }, "devDependencies": { "typescript": "~5.9.0" } }
JSON
cat > pnpm-workspace.yaml <<'YAML'
packages:
  - "apps/*"
YAML
cat > apps/web/package.json <<'JSON'
{
  "name": "web", "private": true,
  "scripts": { "dev": "next dev", "typecheck": "tsc --noEmit" },
  "dependencies": { "next": "^16.4.0", "react": "^19.2.7", "react-dom": "^19.2.7" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "typescript": "~5.9.0" }
}
JSON
cat > apps/web/app/layout.tsx <<'TSX'
import type { ReactNode } from 'react'
export default function RootLayout({ children }: { children: ReactNode }) {
  return <html lang="en"><body>{children}</body></html>
}
TSX
cat > apps/web/app/page.tsx <<'TSX'
export default function Home() { return <h1>Acme</h1> }
TSX
cat > apps/admin/package.json <<'JSON'
{
  "name": "admin", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react-router": "^8.5.0", "react": "^19.2.7", "react-dom": "^19.2.7" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > apps/admin/tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > apps/admin/src/api.ts <<'TS'
export interface User { id: string; name: string; email: string }
export async function getUsers(): Promise<User[]> {
  const res = await fetch('/api/users')
  if (!res.ok) throw new Error(`Failed to load users (${res.status})`)
  return (await res.json()) as User[]
}
TS
cat > apps/admin/src/main.tsx <<'TSX'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { createBrowserRouter } from 'react-router'
import { RouterProvider } from 'react-router/dom'
import { Root } from './routes/root'

const router = createBrowserRouter([{ path: '/', Component: Root, children: [] }])
createRoot(document.getElementById('root')!).render(<StrictMode><RouterProvider router={router} /></StrictMode>)
TSX
cat > apps/admin/src/routes/root.tsx <<'TSX'
import { Outlet } from 'react-router'
export function Root() { return <main><h1>Admin</h1><Outlet /></main> }
TSX
