---
type: regex
pattern: '\bfireEvent\b'
match: not_contains
target: { source: file, path: "src/components/TodoList.test.tsx" }
---
