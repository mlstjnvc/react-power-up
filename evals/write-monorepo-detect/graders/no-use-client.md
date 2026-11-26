---
type: regex
pattern: '["'']use client["'']'
match: not_contains
target: { source: file, path: apps/admin/src/routes/users.tsx }
---
No 'use client' directive: there are no Server Components in the admin app.
