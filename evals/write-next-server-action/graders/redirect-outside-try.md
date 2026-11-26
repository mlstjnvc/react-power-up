---
type: llm
focus: { source: file, path: "app/settings/actions.ts" }
---

This is a Next.js Server Action file.

PASS if every `redirect(...)` call in a Server Action is outside any `try` block (or the catch rethrows non-own errors, e.g. with `unstable_rethrow`/`isRedirectError`), so the redirect cannot be swallowed by a catch.

FAIL if `redirect(...)` is called inside a `try { ... }` whose `catch` would swallow it.
