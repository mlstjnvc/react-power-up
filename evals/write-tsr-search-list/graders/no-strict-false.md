---
type: regex
pattern: 'strict\s*:\s*false'
match: not_contains
target: { source: file, path: src/routes/products.tsx }
---
