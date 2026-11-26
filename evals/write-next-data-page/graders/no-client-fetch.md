---
type: regex
pattern: 'useEffect\s*\('
match: not_contains
target: { source: file, path: "app/products/[id]/page.tsx" }
---
