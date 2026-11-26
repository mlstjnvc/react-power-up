#!/usr/bin/env bash
# Clean control: idiomatic React 19 components with no catalog violations (no node_modules, no git).
set -euo pipefail
mkdir -p src/components src/theme
cat > package.json <<'JSON'
{
  "name": "catalog", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@vitejs/plugin-react": "^5.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > src/theme/ThemeContext.tsx <<'TSX'
import { createContext, useContext, useMemo, useState, type ReactNode } from 'react'

type Theme = 'light' | 'dark'
interface ThemeValue { theme: Theme; toggle: () => void }

const ThemeContext = createContext<ThemeValue | null>(null)

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('light')
  const value = useMemo<ThemeValue>(
    () => ({ theme, toggle: () => setTheme((t) => (t === 'light' ? 'dark' : 'light')) }),
    [theme],
  )
  return <ThemeContext value={value}>{children}</ThemeContext>
}

export function useTheme(): ThemeValue {
  const value = useContext(ThemeContext)
  if (value === null) throw new Error('useTheme must be used inside <ThemeProvider>')
  return value
}
TSX
cat > src/components/SearchField.tsx <<'TSX'
import { useId } from 'react'

interface SearchFieldProps {
  label: string
  value: string
  onChange: (value: string) => void
  ref?: React.Ref<HTMLInputElement>
}

export function SearchField({ label, value, onChange, ref }: SearchFieldProps) {
  const id = useId()
  return (
    <div>
      <label htmlFor={id}>{label}</label>
      <input id={id} ref={ref} type="search" value={value} onChange={(e) => onChange(e.currentTarget.value)} />
    </div>
  )
}
TSX
cat > src/components/ProductList.tsx <<'TSX'
import { useState } from 'react'
import { SearchField } from './SearchField'

export interface Product { id: string; name: string; price: number }

export function ProductList({ products }: { products: Product[] }) {
  const [query, setQuery] = useState('')
  const visible = products
    .filter((p) => p.name.toLowerCase().includes(query.trim().toLowerCase()))
    .toSorted((a, b) => a.name.localeCompare(b.name))

  return (
    <section>
      <SearchField label="Search products" value={query} onChange={setQuery} />
      {visible.length === 0 ? (
        <p>No products match “{query}”.</p>
      ) : (
        <ul>
          {visible.map((p) => (
            <li key={p.id}>{p.name}: {p.price.toFixed(2)}</li>
          ))}
        </ul>
      )}
    </section>
  )
}
TSX
