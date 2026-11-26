---
type: regex
pattern: 'from\s+[\"'']react-router-dom[\"'']'
match: not_contains
target: { source: file, path: src/routes/project.tsx }
---
