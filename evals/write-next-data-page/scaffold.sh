#!/usr/bin/env bash
# Next.js 16 App Router, TypeScript strict, no node_modules.
set -euo pipefail
mkdir -p app lib
cat > package.json <<'JSON'
{
  "name": "shop", "private": true,
  "scripts": { "dev": "next dev", "build": "next build", "typecheck": "tsc --noEmit" },
  "dependencies": { "server-only": "^0.0.1", "next": "^16.0.0", "react": "^19.2.0", "react-dom": "^19.2.0" },
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
cat > lib/products.ts <<'TS'
import 'server-only'
export interface Product { id: string; name: string; price: number; description: string; stock: number; supplierCost: number }
export declare function getProduct(id: string): Promise<Product | null>
export declare function getRelatedProducts(id: string): Promise<Product[]>
export declare function getReviews(id: string): Promise<{ id: string; author: string; text: string }[]>
TS
