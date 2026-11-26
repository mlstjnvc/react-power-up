#!/usr/bin/env bash
# React 18 + Vite SPA, TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p src/components
cat > package.json <<'JSON'
{
  "name": "newsletter", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react": "^18.3.1", "react-dom": "^18.3.1" },
  "devDependencies": { "@types/react": "^18.3.3", "@types/react-dom": "^18.3.3", "@vitejs/plugin-react": "^4.3.0", "typescript": "~5.6.0", "vite": "^5.4.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2022", "lib": ["ES2022", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/api.ts <<'TS'
export async function subscribe(email: string): Promise<void> {
  const res = await fetch('/api/newsletter', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email }) })
  if (!res.ok) throw new Error('Subscription failed')
}
TS
cat > src/App.tsx <<'TSX'
export function App() {
  return <main><h1>Newsletter</h1></main>
}
TSX
