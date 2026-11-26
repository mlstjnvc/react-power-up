---
type: llm
focus: { source: file, path: "app/settings/page.tsx" }
---

This is a Next.js Server Component page that renders a client form component.

PASS if it passes only the fields the form needs (e.g. displayName and bio) to the client component, not the whole user row (which contains `passwordHash`, `email`, `role`).

FAIL if the full user record (or an object spread from it) is passed to the client component.
