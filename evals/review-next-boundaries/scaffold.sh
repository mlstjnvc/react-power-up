#!/usr/bin/env bash
# Next.js 16 App Router, TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p 'app/account/[tab]' lib
cat > package.json <<'JSON'
{
  "name": "shop", "private": true,
  "scripts": { "dev": "next dev", "build": "next build", "typecheck": "tsc --noEmit" },
  "dependencies": { "next": "^16.0.0", "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/node": "^22.0.0", "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "typescript": "~5.9.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2022", "lib": ["dom", "dom.iterable", "esnext"], "module": "esnext", "moduleResolution": "bundler", "jsx": "preserve", "strict": true, "noEmit": true, "skipLibCheck": true, "isolatedModules": true, "incremental": true, "plugins": [{ "name": "next" }], "paths": { "@/*": ["./*"] } }, "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"], "exclude": ["node_modules"] }
JSON
cat > next.config.ts <<'TS'
import type { NextConfig } from 'next'
const nextConfig: NextConfig = {}
export default nextConfig
TS
cat > app/layout.tsx <<'TSX'
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body>{children}</body></html>
}
TSX
# REACT-NEXT-006 (per-request user in module scope)
cat > lib/session.ts <<'TS'
import { cookies } from 'next/headers'
export interface User { id: string; name: string }
declare function verifySession(token: string): Promise<User | null>

let currentUser: User | null = null

export async function loadUser(): Promise<User | null> {
  const token = (await cookies()).get('session')?.value
  currentUser = token ? await verifySession(token) : null
  return currentUser
}

export function getCurrentUser(): User | null {
  return currentUser
}
TS
# REACT-NEXT-004 (params not awaited on Next 16)
cat > 'app/account/[tab]/page.tsx' <<'TSX'
import { loadUser } from '@/lib/session'
import { AccountTabs } from '../AccountTabs'

export default async function AccountPage({ params }: { params: { tab: string } }) {
  const user = await loadUser()
  return <AccountTabs initialTab={params.tab} userName={user?.name ?? 'guest'} />
}
TSX
# REACT-NEXT-001 ('use client' on a layout) + REACT-NEXT-005 (localStorage during render)
cat > app/account/layout.tsx <<'TSX'
'use client'
export default function AccountLayout({ children }: { children: React.ReactNode }) {
  const compact = localStorage.getItem('compact') === '1'
  return <section className={compact ? 'compact' : undefined}><h1>Account</h1>{children}</section>
}
TSX
cat > app/account/AccountTabs.tsx <<'TSX'
'use client'
import { useState } from 'react'
export function AccountTabs({ initialTab, userName }: { initialTab: string; userName: string }) {
  const [tab, setTab] = useState(initialTab)
  return <div><p>Hello {userName}</p><button type="button" onClick={() => setTab('profile')}>Profile</button><span>{tab}</span></div>
}
TSX
