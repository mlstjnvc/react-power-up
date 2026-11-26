---
type: regex
pattern: 'import[^\n]*\b(useActionState|useOptimistic|useFormStatus)\b|\b(useActionState|useOptimistic|useFormStatus)\s*(<|\()|\buse\(|action=\{'
match: not_contains
target: { source: file, path: src/components/EmailInput.tsx }
---
