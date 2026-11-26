---
type: regex
pattern: 'key=\{\s*(index|idx|i)\s*\}'
match: not_contains
target: { source: file, path: src/components/TaskList.tsx }
---
