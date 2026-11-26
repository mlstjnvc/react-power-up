---
type: regex
pattern: 'to=\{?`/products/\$\{'
match: not_contains
target: { source: file, path: src/routes/products.tsx }
---
