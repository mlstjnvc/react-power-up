#!/usr/bin/env bash
# React + Vite SPA ("react-router": "^8.5.0", ), TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p src/routes
cat > package.json <<'JSON'
{
  "name": "portal", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react-router": "^8.5.0", "react": "^19.2.7", "react-dom": "^19.2.7" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
# REACT-RR-007 (react-router-dom on v8), REACT-RR-005 (open redirect), REACT-RR-003 (<a href> internal)
cat > src/routes/login.tsx <<'TSX'
import { useNavigate, useSearchParams } from 'react-router-dom'

export function Login({ signIn }: { signIn: (email: string) => Promise<void> }) {
  const navigate = useNavigate()
  const [params] = useSearchParams()

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    await signIn(String(new FormData(e.currentTarget).get('email') ?? ''))
    navigate(params.get('redirect') ?? '/')
  }

  return (
    <form onSubmit={handleSubmit}>
      <label>Email <input name="email" type="email" required /></label>
      <button type="submit">Sign in</button>
      <a href="/forgot-password">Forgot password?</a>
    </form>
  )
}
TSX
# REACT-RR-004 (navigate during render)
cat > src/routes/settings.tsx <<'TSX'
import { useNavigate } from 'react-router'

export function Settings({ user }: { user: { name: string } | null }) {
  const navigate = useNavigate()
  if (!user) navigate('/login?redirect=/settings')
  return <h1>Settings for {user?.name}</h1>
}
TSX
