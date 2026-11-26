---
type: regex
pattern: 'key=\{\s*field\.id\s*\}|key=\{\s*\w+\.id\s*\}'
target: { source: file, path: src/components/RegistrationForm.tsx }
---
