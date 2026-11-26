#!/usr/bin/env bash
# React 19 SPA seeded with hook and effect anti-patterns (no node_modules, no git).
set -euo pipefail
mkdir -p src/components
cat > package.json <<'JSON'
{
  "name": "dash", "private": true, "type": "module",
  "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > src/types.ts <<'TS'
export interface Order { id: string; total: number; status: 'open' | 'paid' }
TS
# REACT-HOOK-001: hook after early return. REACT-EFF-001: derived state synced by an effect.
cat > src/components/OrderSummary.tsx <<'TSX'
import { useEffect, useState } from 'react'
import type { Order } from '../types'

export function OrderSummary({ orders }: { orders: Order[] | null }) {
  if (orders === null) return <p>Loading…</p>

  const [openTotal, setOpenTotal] = useState(0)
  useEffect(() => {
    setOpenTotal(orders.filter((o) => o.status === 'open').reduce((sum, o) => sum + o.total, 0))
  }, [orders])

  return <p>Open orders: {openTotal.toFixed(2)}</p>
}
TSX
# REACT-EFF-006: interval without cleanup. REACT-HOOK-003: suppressed dependency (stale refreshMs).
cat > src/components/LiveClock.tsx <<'TSX'
import { useEffect, useState } from 'react'

export function LiveClock({ refreshMs }: { refreshMs: number }) {
  const [now, setNow] = useState(() => new Date())

  useEffect(() => {
    setInterval(() => setNow(new Date()), refreshMs)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return <time dateTime={now.toISOString()}>{now.toLocaleTimeString()}</time>
}
TSX
