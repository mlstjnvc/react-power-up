---
type: regex
pattern: 'import[^\n]*\bforwardRef\b|forwardRef\s*(<|\()'
match: not_contains
target: { source: file, path: src/components/EmailInput.tsx }
---
