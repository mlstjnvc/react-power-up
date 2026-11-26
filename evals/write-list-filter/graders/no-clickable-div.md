---
type: regex
pattern: '<(div|span|li)\b[^>]*\sonClick='
match: not_contains
target: { source: file, path: src/components/TaskList.tsx }
---
