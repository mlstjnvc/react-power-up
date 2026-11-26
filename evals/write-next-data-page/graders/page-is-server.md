---
type: regex
pattern: '^\s*[\"'']use client[\"'']'
match: not_contains
target: { source: file, path: "app/products/[id]/page.tsx" }
---
