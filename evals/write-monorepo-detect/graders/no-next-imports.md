---
type: regex
pattern: 'from\s+["'']next[/"'']'
match: not_contains
target: { source: file, path: apps/admin/src/routes/users.tsx }
---
No Next.js APIs (next/link, next/navigation, ...) in the Vite admin app.
