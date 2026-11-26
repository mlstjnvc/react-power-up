#!/usr/bin/env bash
# Next.js 16 App Router + Redux Toolkit 2 + React Redux 9 (no node_modules).
set -euo pipefail
mkdir -p app lib
cat > package.json <<'JSON'
{
  "name": "notes", "private": true,
  "scripts": { "dev": "next dev", "build": "next build", "typecheck": "tsc --noEmit" },
  "dependencies": { "@reduxjs/toolkit": "^2.9.0", "next": "^16.0.0", "react": "^19.2.0", "react-dom": "^19.2.0", "react-redux": "^9.2.0" },
  "devDependencies": { "@types/node": "^22.0.0", "@types/react": "^19.2.0", "@types/react-dom": "^19.2.0", "typescript": "~5.9.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2022", "lib": ["dom", "dom.iterable", "esnext"], "module": "esnext", "moduleResolution": "bundler", "jsx": "preserve", "strict": true, "noEmit": true, "skipLibCheck": true, "isolatedModules": true, "incremental": true, "plugins": [{ "name": "next" }], "paths": { "@/*": ["./*"] } }, "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"], "exclude": ["node_modules"] }
JSON
cat > app/layout.tsx <<'TSX'
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body>{children}</body></html>
}
TSX
cat > app/page.tsx <<'TSX'
export default function Home() {
  return <main><h1>Notes</h1></main>
}
TSX
