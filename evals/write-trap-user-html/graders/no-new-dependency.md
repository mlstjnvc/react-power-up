---
type: llm
---

PASS if the assistant did not add a dependency (no edits to package.json adding packages, no npm/pnpm/yarn install commands) and, if it mentions a sanitizer library, it only suggests it or asks for approval.

FAIL if it added a sanitizer or any other package without asking.
