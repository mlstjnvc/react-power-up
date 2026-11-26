#!/usr/bin/env bash
# Next.js 16 App Router with Zustand 5 and Redux Toolkit 2, seeded with state anti-patterns (no node_modules, no git).
set -euo pipefail
mkdir -p app lib components
cat > package.json <<'JSON'
{ "name": "crm", "private": true, "dependencies": { "@reduxjs/toolkit": "^2.9.0", "next": "^16.0.0", "react": "^19.2.0", "react-dom": "^19.2.0", "react-redux": "^9.2.0", "zustand": "^5.0.8" }, "devDependencies": { "@types/react": "^19.2.0", "typescript": "~5.9.0" } }
JSON
cat > app/layout.tsx <<'TSX'
import { StoreProvider } from '@/components/StoreProvider'
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body><StoreProvider>{children}</StoreProvider></body></html>
}
TSX
# REACT-STATE-006 (module-scope store in an SSR app) + REACT-STATE-009 (Date in state)
cat > lib/store.ts <<'TS'
import { configureStore, createSlice, type PayloadAction } from '@reduxjs/toolkit'

interface SessionState { userId: string | null; signedInAt: Date | null }

const sessionSlice = createSlice({
  name: 'session',
  initialState: { userId: null, signedInAt: null } as SessionState,
  reducers: {
    signedIn(state, action: PayloadAction<{ userId: string; at: Date }>) {
      state.userId = action.payload.userId
      state.signedInAt = action.payload.at
    },
  },
})

export const { signedIn } = sessionSlice.actions
export const store = configureStore({ reducer: { session: sessionSlice.reducer } })
export type RootState = ReturnType<typeof store.getState>
TS
cat > components/StoreProvider.tsx <<'TSX'
'use client'
import { Provider } from 'react-redux'
import { store } from '@/lib/store'
export function StoreProvider({ children }: { children: React.ReactNode }) {
  return <Provider store={store}>{children}</Provider>
}
TSX
# REACT-STATE-004 (v5 selector returns a new object without useShallow)
cat > lib/filters.ts <<'TS'
import { create } from 'zustand'

interface FilterState { query: string; owner: string; setQuery: (q: string) => void; setOwner: (o: string) => void }

export const useFilters = create<FilterState>()((set) => ({
  query: '',
  owner: 'all',
  setQuery: (query) => set({ query }),
  setOwner: (owner) => set({ owner }),
}))
TS
cat > components/FilterBar.tsx <<'TSX'
'use client'
import { useFilters } from '@/lib/filters'

export function FilterBar() {
  const { query, setQuery } = useFilters((s) => ({ query: s.query, setQuery: s.setQuery }))
  return <input aria-label="Search contacts" value={query} onChange={(e) => setQuery(e.currentTarget.value)} />
}
TSX
