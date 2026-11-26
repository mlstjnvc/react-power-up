---
type: llm
focus: { source: file, path: src/auth/AuthContext.tsx }
---

This is a React 19 context provider in a project without React Compiler.

PASS if the value passed to the provider is referentially stable between renders when nothing changed: for example it is built with `useMemo` (with functions wrapped in `useCallback` or defined so they don't change identity), or the state and the actions are split into separate contexts with stable values.

FAIL if the provider passes a fresh object literal on every render (e.g. `value={{ user, signIn, signOut }}` with no memoization).
