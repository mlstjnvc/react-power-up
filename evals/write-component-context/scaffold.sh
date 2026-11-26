#!/usr/bin/env bash
# React 19 + Vite SPA, TypeScript strict, no React Compiler, no node_modules.
set -euo pipefail
mkdir -p src/components src/auth
cat > package.json <<'JSON'
{
  "name": "portal", "private": true, "type": "module",
  "scripts": { "dev": "vite", "build": "tsc -b && vite build", "typecheck": "tsc --noEmit" },
  "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2022", "lib": ["ES2022", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "isolatedModules": true, "verbatimModuleSyntax": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > vite.config.ts <<'TS'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
export default defineConfig({ plugins: [react()] })
TS
cat > src/main.tsx <<'TSX'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './App'
createRoot(document.getElementById('root')!).render(<StrictMode><App /></StrictMode>)
TSX
cat > src/App.tsx <<'TSX'
export function App() {
  return <main><h1>Portal</h1></main>
}
TSX
cat > src/api.ts <<'TS'
export interface User { id: string; name: string; email: string }
export async function signIn(email: string, password: string): Promise<User> {
  const res = await fetch('/api/sign-in', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password }) })
  if (!res.ok) throw new Error('Sign-in failed')
  return (await res.json()) as User
}
export async function signOut(): Promise<void> {
  await fetch('/api/sign-out', { method: 'POST' })
}
TS
