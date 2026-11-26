---
type: regex
pattern: ':\s*Date\b|new Date\(\)\s*[,}]'
match: not_contains
target: { source: file, path: lib/notesSlice.ts }
---
