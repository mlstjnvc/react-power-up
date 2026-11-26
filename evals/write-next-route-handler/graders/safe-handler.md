---
type: llm
focus: { source: file, path: "app/api/invoices/[id]/route.ts" }
---

This is a Next.js App Router route handler that returns an invoice.

PASS if all of these hold: (1) it returns 401 when there is no signed-in user; (2) it only returns the invoice if it belongs to the current user (ownerId check in the query or after it), otherwise 404 or 403; (3) the JSON response contains only id, total and status, not `ownerId` or `internalNotes` (no spreading the whole row); (4) the `id` param is checked or at least safely used (no string-building of SQL).

FAIL if any of these is missing.
