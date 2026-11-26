---
type: llm
focus: { source: file, path: src/components/SignInForm.tsx }
---

PASS if every React component in this file is declared at module top level. Helper functions that return JSX and are called as functions (e.g. `{renderError()}`) are fine.

FAIL if a component (a function used as `<Something />` in JSX) is declared inside another component's body.
