---
type: regex
pattern: 'VITE_TRANSLATE_API_KEY|import\.meta\.env\.[A-Z_]*KEY'
match: not_contains
target: { source: file, path: "src/components/Translator.tsx" }
---
