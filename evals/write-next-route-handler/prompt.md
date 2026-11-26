---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a JSON API endpoint `GET /api/invoices/[id]` in `app/api/invoices/[id]/route.ts` that returns an invoice's id, total and status using `lib/db.ts`. Only the signed-in owner of the invoice may read it (`getCurrentUser` in `lib/auth.ts`).
