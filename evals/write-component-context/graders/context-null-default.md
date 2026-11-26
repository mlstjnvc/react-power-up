---
type: regex
pattern: 'createContext\s*<[^>]*\bnull\b[^>]*>\s*\(\s*null\s*\)'
target: { source: file, path: src/auth/AuthContext.tsx }
---
