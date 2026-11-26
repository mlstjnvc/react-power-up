---
type: llm
focus: { source: file, path: "src/components/TodoList.test.tsx" }
---

This is a Vitest + React Testing Library test file for a component that uses TanStack Query.

PASS if each test renders with a fresh `QueryClient` (created per test or per render helper call) with query retries disabled (`retry: false`), and elements are found by role/label/text rather than test ids or CSS selectors.

FAIL if a single QueryClient is shared across tests at module scope, retries are left on, or queries mostly use `getByTestId`/`container.querySelector`.
