#!/usr/bin/env bash
# React + Vite SPA (no extra libraries), TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p src/components server
cat > package.json <<'JSON'
{
  "name": "board", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
# REACT-SEC-001 (raw HTML), REACT-SEC-002 (unchecked href), REACT-SEC-008 (token in localStorage)
cat > src/components/PostView.tsx <<'TSX'
export interface Post { id: string; title: string; bodyHtml: string; authorUrl: string }

export function PostView({ post }: { post: Post }) {
  return (
    <article>
      <h2>{post.title}</h2>
      <div dangerouslySetInnerHTML={{ __html: post.bodyHtml }} />
      <a href={post.authorUrl}>About the author</a>
    </article>
  )
}

export async function signIn(email: string, password: string) {
  const res = await fetch('/api/login', { method: 'POST', body: JSON.stringify({ email, password }) })
  const { token } = (await res.json()) as { token: string }
  localStorage.setItem('authToken', token)
}
TSX
# REACT-SEC-006 (SSRF), REACT-SEC-007 (eval of user input)
cat > server/routes.ts <<'TS'
export async function linkPreview(body: { url: string }) {
  const res = await fetch(body.url)
  const html = await res.text()
  return { title: /<title>(.*?)<\/title>/i.exec(html)?.[1] ?? null }
}

export async function computeScore(body: { formula: string; votes: number; age: number }) {
  const score = new Function('votes', 'age', `return ${body.formula}`)(body.votes, body.age)
  return { score }
}
TS
