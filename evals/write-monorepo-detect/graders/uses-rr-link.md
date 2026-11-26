---
type: regex
pattern: 'from\s+["'']react-router["'']'
target: { source: file, path: apps/admin/src/routes/users.tsx }
---
Uses react-router (Link, loader data) - the admin app's router.
