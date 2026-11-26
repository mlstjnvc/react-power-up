#!/usr/bin/env bash
# React + Vite SPA ("@tanstack/react-query": "^5.90.0", ), TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p src/components
cat > package.json <<'JSON'
{
  "name": "todos", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit", "test": "vitest run" },
  "dependencies": { "@tanstack/react-query": "^5.90.0", "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@testing-library/jest-dom": "^6.6.0", "@testing-library/react": "^16.3.0", "@testing-library/user-event": "^14.6.0", "jsdom": "^26.0.0", "msw": "^3.0.0", "vitest": "^5.1.0", "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/api.ts <<'TS'
export interface Todo { id: string; title: string; done: boolean }
export async function fetchTodos(): Promise<Todo[]> {
  const res = await fetch('/api/todos')
  if (!res.ok) throw new Error(`Failed to load todos (${res.status})`)
  return (await res.json()) as Todo[]
}
export async function toggleTodo(id: string): Promise<Todo> {
  const res = await fetch(`/api/todos/${encodeURIComponent(id)}/toggle`, { method: 'POST' })
  if (!res.ok) throw new Error(`Failed to update todo (${res.status})`)
  return (await res.json()) as Todo
}
TS
cat > src/components/TodoList.tsx <<'TSX'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { fetchTodos, toggleTodo } from '../api'

export function TodoList() {
  const queryClient = useQueryClient()
  const { data: todos, isPending, isError, error } = useQuery({ queryKey: ['todos'], queryFn: fetchTodos })
  const toggle = useMutation({
    mutationFn: toggleTodo,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
  })

  if (isPending) return <p>Loading…</p>
  if (isError) return <p role="alert">{error.message}</p>
  if (todos.length === 0) return <p>Nothing to do.</p>
  return (
    <ul>
      {todos.map((t) => (
        <li key={t.id}>
          <label>
            <input type="checkbox" checked={t.done} onChange={() => toggle.mutate(t.id)} /> {t.title}
          </label>
        </li>
      ))}
    </ul>
  )
}
TSX
cat > vitest.config.ts <<'TS'
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
export default defineConfig({ plugins: [react()], test: { environment: 'jsdom', setupFiles: ['./src/test/setup.ts'] } })
TS
mkdir -p src/test
cat > src/test/server.ts <<'TS'
import { setupServer } from 'msw/node'
export const server = setupServer()
TS
cat > src/test/setup.ts <<'TS'
import '@testing-library/jest-dom/vitest'
import { afterAll, afterEach, beforeAll } from 'vitest'
import { server } from './server'
beforeAll(() => server.listen({ onUnhandledFrame: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
TS
