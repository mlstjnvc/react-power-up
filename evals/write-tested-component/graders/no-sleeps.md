---
type: regex
pattern: 'setTimeout\s*\('
match: not_contains
target: { source: file, path: "src/components/TodoList.test.tsx" }
---
