#!/usr/bin/env bash
# React 19 + Vite SPA with Zustand 5 (no node_modules).
set -euo pipefail
mkdir -p src/components src/stores
cat > package.json <<'JSON'
{
  "name": "app", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "zustand": "^5.0.8", "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/types.ts <<'TS'
export interface Product { id: string; name: string; price: number }
TS
cat > src/App.tsx <<'TSX'
export function App() { return <main><h1>Shop</h1></main> }
TSX
