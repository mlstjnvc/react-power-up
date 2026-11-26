#!/usr/bin/env bash
# React + Vite SPA (no extra libraries), TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p src/components
cat > package.json <<'JSON'
{
  "name": "analytics", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "tsc --noEmit" },
  "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" },
  "devDependencies": { "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "@rolldown/plugin-babel": "^0.1.0", "@vitejs/plugin-react": "^6.0.0", "babel-plugin-react-compiler": "^1.0.0", "typescript": "~5.9.0", "vite": "^7.1.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2023", "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "moduleResolution": "Bundler", "jsx": "react-jsx", "strict": true, "noEmit": true, "skipLibCheck": true }, "include": ["src"] }
JSON
cat > vite.config.ts <<'TS'
import { defineConfig } from 'vite'
import react, { reactCompilerPreset } from '@vitejs/plugin-react'
import babel from '@rolldown/plugin-babel'
export default defineConfig({ plugins: [react(), babel({ presets: [reactCompilerPreset()] })] })
TS
cat > src/components/MetricsTable.tsx <<'TSX'
import { memo, useCallback, useMemo, useState } from 'react'

export interface Metric { id: string; name: string; value: number; active: boolean }

const MetricRow = memo(function MetricRow({ metric, onSelect }: { metric: Metric; onSelect: (id: string) => void }) {
  return (
    <tr>
      <td>{metric.name}</td>
      <td>{metric.value.toFixed(1)}</td>
      <td><button type="button" onClick={() => onSelect(metric.id)}>Details</button></td>
    </tr>
  )
})

export function MetricsTable({ metrics, onOpen }: { metrics: Metric[]; onOpen: (id: string) => void }) {
  const [showInactive, setShowInactive] = useState(false)
  const visible = useMemo(() => metrics.filter((m) => showInactive || m.active), [metrics, showInactive])
  const total = useMemo(() => visible.reduce((sum, m) => sum + m.value, 0), [visible])
  const handleSelect = useCallback((id: string) => onOpen(id), [onOpen])

  return (
    <section>
      <label><input type="checkbox" checked={showInactive} onChange={(e) => setShowInactive(e.currentTarget.checked)} /> Show inactive</label>
      <table>
        <tbody>{visible.map((m) => <MetricRow key={m.id} metric={m} onSelect={handleSelect} />)}</tbody>
      </table>
      <p>Total: {total.toFixed(1)}</p>
    </section>
  )
}
TSX
