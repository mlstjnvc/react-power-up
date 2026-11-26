---
type: regex
pattern: 'from\s+["'']react-router-dom["'']'
match: not_contains
target: { source: file, path: apps/admin/src/routes/users.tsx }
---
React Router v8 imports from react-router (react-router-dom is v7).
