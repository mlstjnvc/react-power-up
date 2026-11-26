---
type: regex
pattern: 'useQuery\s*\(\s*\{[^}]*\bon(Success|Error|Settled)\b'
match: not_contains
target: { source: file, path: src/components/OrdersTable.tsx }
---
