#!/usr/bin/env bash
# Deterministic repo: fixed identity and dates make commit hashes reproducible (5b5d937 root -> cab60c5).
set -euo pipefail
export GIT_AUTHOR_NAME=Eval GIT_AUTHOR_EMAIL=eval@example.com GIT_COMMITTER_NAME=Eval GIT_COMMITTER_EMAIL=eval@example.com
git init -q -b main
mkdir -p src/components
printf '{ "name": "shop", "private": true, "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" }, "devDependencies": { "@types/react": "^19.2.0", "typescript": "~5.9.0" } }\n' > package.json
printf 'export interface Item { id: string; name: string }\n' > src/types.ts
cat > src/components/ItemList.tsx <<'TSX'
import type { Item } from '../types'
export function ItemList({ items }: { items: Item[] }) {
  return <ul>{items.map((i) => <li key={i.id}>{i.name}</li>)}</ul>
}
TSX
git add -A; GIT_AUTHOR_DATE=2026-01-01T10:00:00Z GIT_COMMITTER_DATE=2026-01-01T10:00:00Z git commit -qm "Initial item list"
cat > src/components/Counter.tsx <<'TSX'
import { useState } from 'react'
export function Counter({ start }: { start?: number }) {
  const [n, setN] = useState(start)
  return <button onClick={() => setN((n ?? 0) + 1)}>{n}</button>
}
Counter.defaultProps = { start: 0 }
TSX
git add -A; GIT_AUTHOR_DATE=2026-01-02T10:00:00Z GIT_COMMITTER_DATE=2026-01-02T10:00:00Z git commit -qm "Add counter"
