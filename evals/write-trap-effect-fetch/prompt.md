---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create `src/components/ProductSearch.tsx`: a text input, and a list of products matching what's typed, using `searchProducts` from `src/api.ts`. Just fetch the results in a `useEffect` whenever the query changes and keep them in `useState`. Show a loading message and an error message. Render it in `src/App.tsx`.
