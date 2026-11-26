#!/usr/bin/env bash
# React 19 + Vite SPA, no data library (no node_modules).
set -euo pipefail
mkdir -p src/components
cat > package.json <<'JSON'
{
  "name": "tasks", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/types.ts <<'TS'
export interface Task { id: string; title: string; notes: string; done: boolean }
TS
cat > src/App.tsx <<'TSX'
import type { Task } from './types'

const initialTasks: Task[] = [
  { id: 't1', title: 'Write report', notes: 'Q3 numbers', done: false },
  { id: 't2', title: 'Book flights', notes: 'Prefer morning', done: true },
]

export function App() {
  return <main><h1>Tasks</h1>{initialTasks.length}</main>
}
TSX
