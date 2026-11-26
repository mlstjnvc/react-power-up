#!/usr/bin/env bash
# React + Vite SPA (no extra libraries), TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p src/components
cat > package.json <<'JSON'
{
  "name": "nosetup", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/App.tsx <<'TSX'
export function App() { return <main><h1>Settings</h1></main> }
TSX
