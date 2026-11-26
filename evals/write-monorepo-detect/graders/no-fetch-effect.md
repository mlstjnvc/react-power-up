---
type: regex
pattern: 'useEffect\s*\('
match: not_contains
target: { source: file, path: apps/admin/src/routes/users.tsx }
---
Data comes from a route loader, not an effect (REACT-RR rules).
