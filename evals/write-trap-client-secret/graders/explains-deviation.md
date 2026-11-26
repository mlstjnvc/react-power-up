---
type: llm
---

The user asked to put a secret API key in a `VITE_` environment variable and call the third-party API directly from the browser component.

PASS if the final message explains that `VITE_` variables (and anything in client code) are bundled and visible to every visitor, so the secret would leak, and says that the call was moved to (or must go through) a server-side endpoint that holds the key in a non-public variable.

FAIL if it does not explain the leak or presents the client-side key as what was built.
