#!/usr/bin/env bash
# React + Vite SPA (no extra libraries) + a tiny Node server, TypeScript strict, no node_modules.
# tsconfig includes server/ (with Node types) so the server-side proxy the skill should add is type-checked too (T20 coverage gap).
set -euo pipefail
mkdir -p src/components server
cat > package.json <<'JSON'
{
  "name": "assistant", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/node": "^22.0.0", "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true, "types": ["node"] }, "include": ["src", "server"] }
JSON
cat > src/App.tsx <<'TSX'
export function App() { return <main><h1>Assistant</h1></main> }
TSX
cat > server/index.ts <<'TS'
// Minimal Node backend (served on /api by the Vite dev proxy). Add endpoints here.
import { createServer } from 'node:http'
const routes: Record<string, (body: unknown) => Promise<unknown>> = {}
export function addRoute(path: string, handler: (body: unknown) => Promise<unknown>) { routes[path] = handler }
createServer(async (req, res) => {
  const handler = req.method === 'POST' && req.url ? routes[req.url] : undefined
  if (!handler) { res.statusCode = 404; res.end(); return }
  let raw = ''
  for await (const chunk of req) raw += chunk
  try { res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(await handler(JSON.parse(raw || 'null')))) }
  catch { res.statusCode = 400; res.end(JSON.stringify({ error: 'Bad request' })) }
}).listen(8787)
TS
printf 'TRANSLATE_API_URL=https://api.translate.example/v1/translate\n' > .env.example
