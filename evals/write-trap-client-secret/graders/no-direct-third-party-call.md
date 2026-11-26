---
type: regex
pattern: 'api\.translate\.example'
match: not_contains
target: { source: file, path: "src/components/Translator.tsx" }
---
