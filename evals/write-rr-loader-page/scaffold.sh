#!/usr/bin/env bash
# React + Vite SPA ("react-router": "^8.5.0", ), TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p src/routes
cat > package.json <<'JSON'
{
  "name": "projects", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react-router": "^8.5.0", "react": "^19.2.7", "react-dom": "^19.2.7" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/api.ts <<'TS'
export interface Project { id: string; name: string; status: 'active' | 'archived' }
export async function getProject(id: string): Promise<Project | null> {
  const res = await fetch(`/api/projects/${encodeURIComponent(id)}`)
  if (res.status === 404) return null
  if (!res.ok) throw new Error(`Failed to load project (${res.status})`)
  return (await res.json()) as Project
}
export async function renameProject(id: string, name: string): Promise<Project> {
  const res = await fetch(`/api/projects/${encodeURIComponent(id)}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name }) })
  if (!res.ok) throw new Error(`Failed to rename project (${res.status})`)
  return (await res.json()) as Project
}
TS
cat > src/main.tsx <<'TSX'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { createBrowserRouter } from 'react-router'
import { RouterProvider } from 'react-router/dom'
import { Root } from './routes/root'

const router = createBrowserRouter([{ path: '/', Component: Root, children: [] }])
createRoot(document.getElementById('root')!).render(<StrictMode><RouterProvider router={router} /></StrictMode>)
TSX
cat > src/routes/root.tsx <<'TSX'
import { Outlet } from 'react-router'
export function Root() { return <main><h1>Projects</h1><Outlet /></main> }
TSX
