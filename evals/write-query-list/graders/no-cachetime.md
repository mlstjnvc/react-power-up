---
type: regex
pattern: '\bcacheTime\b'
match: not_contains
target: { source: file, path: src/api/orderQueries.ts }
---
