---
type: regex
pattern: 'spyOn\(\s*(global|globalThis|window)\s*,\s*[\"'']fetch[\"'']|global\.fetch\s*=|vi\.stubGlobal\(\s*[\"'']fetch'
match: not_contains
target: { source: file, path: "src/components/TodoList.test.tsx" }
---
