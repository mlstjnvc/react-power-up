#!/usr/bin/env bash
# React 19 + Vite SPA with seeded component anti-patterns (no node_modules, no git needed).
set -euo pipefail
mkdir -p src/components src/settings
cat > package.json <<'JSON'
{
  "name": "admin", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/types.ts <<'TS'
export interface Member { id: string; name: string; role: 'admin' | 'editor' | 'viewer' }
TS
# REACT-COMP-001 (component defined inside a component) + REACT-COMP-002 (sorting the members prop in place)
cat > src/components/MemberTable.tsx <<'TSX'
import { useState } from 'react'
import type { Member } from '../types'

export function MemberTable({ members }: { members: Member[] }) {
  const [filter, setFilter] = useState('')

  members.sort((a, b) => a.name.localeCompare(b.name))

  function FilterInput() {
    return <input value={filter} onChange={(e) => setFilter(e.currentTarget.value)} placeholder="Filter" />
  }

  const visible = members.filter((m) => m.name.toLowerCase().includes(filter.toLowerCase()))

  return (
    <div>
      <FilterInput />
      <table>
        <tbody>
          {visible.map((m) => (
            <tr key={m.id}><td>{m.name}</td><td>{m.role}</td></tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
TSX
# REACT-COMP-011 (defaultProps on a React 19 function component)
cat > src/components/RoleBadge.tsx <<'TSX'
import type { Member } from '../types'

export function RoleBadge({ role }: { role?: Member['role'] }) {
  return <span className={`badge badge-${role}`}>{role}</span>
}

RoleBadge.defaultProps = { role: 'viewer' }
TSX
# REACT-TS-006 (fake context default)
cat > src/settings/SettingsContext.tsx <<'TSX'
import { createContext, useContext, useMemo, useState, type ReactNode } from 'react'

interface Settings { compact: boolean; setCompact: (v: boolean) => void }

const SettingsContext = createContext<Settings>({} as Settings)

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [compact, setCompact] = useState(false)
  const value = useMemo(() => ({ compact, setCompact }), [compact])
  return <SettingsContext value={value}>{children}</SettingsContext>
}

export function useSettings() {
  return useContext(SettingsContext)
}
TSX
