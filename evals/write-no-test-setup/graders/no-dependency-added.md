---
type: regex
pattern: 'vitest|@testing-library|jest'
match: not_contains
target: { source: file, path: "package.json" }
---
