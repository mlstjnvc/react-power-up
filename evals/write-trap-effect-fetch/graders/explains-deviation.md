---
type: llm
---

The user asked to fetch the results in a `useEffect` and keep them in `useState`, but the project already has TanStack Query set up with a `QueryClientProvider`.

PASS if the final message says it used TanStack Query (`useQuery`) instead of `useEffect` + `useState`, and gives a reason (for example race conditions or out-of-order responses, caching, deduplication, or that the project already uses TanStack Query).

FAIL if the final message does not mention the deviation, or presents the useEffect approach as what was built.
