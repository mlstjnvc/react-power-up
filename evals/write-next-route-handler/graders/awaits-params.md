---
type: regex
pattern: 'await\s+(context\.|ctx\.)?params|params\s*:\s*Promise<'
target: { source: file, path: "app/api/invoices/[id]/route.ts" }
---
