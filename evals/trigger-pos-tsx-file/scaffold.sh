#!/usr/bin/env bash
# Vite + React 19 SPA, TypeScript strict, no node_modules. The prompt does not mention React.
set -euo pipefail
mkdir -p src/components
cat > package.json <<'JSON'
{
  "name": "ui-kit", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react": "^19.2.7", "react-dom": "^19.2.7" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > src/components/ui.tsx <<'TSX'
import type { ReactNode } from 'react'

type CardProps = { title: string; children: ReactNode }

export function Card({ title, children }: CardProps) {
  return (
    <section className="card">
      <header className="card__header"><h2>{title}</h2></header>
      <div className="card__body">{children}</div>
    </section>
  )
}
TSX
