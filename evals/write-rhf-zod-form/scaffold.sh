#!/usr/bin/env bash
# React + Vite SPA ("@hookform/resolvers": "^5.2.0", "react-hook-form": "^7.62.0", "zod": "^4.1.0", ), TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p src/components src/schemas
cat > package.json <<'JSON'
{
  "name": "events", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "@hookform/resolvers": "^5.2.0", "react-hook-form": "^7.62.0", "zod": "^4.1.0", "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/api.ts <<'TS'
export interface RegistrationResult { id: string }
export async function register(input: unknown): Promise<RegistrationResult> {
  const res = await fetch('/api/registrations', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(input) })
  if (!res.ok) throw new Error(`Registration failed (${res.status})`)
  return (await res.json()) as RegistrationResult
}
TS
cat > src/App.tsx <<'TSX'
export function App() { return <main><h1>Conference</h1></main> }
TSX
