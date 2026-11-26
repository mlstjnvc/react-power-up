---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Write tests for `src/components/TodoList.tsx` in `src/components/TodoList.test.tsx`: it shows the todos from the API, shows an error message when loading fails, shows the empty state, and toggling a todo's checkbox calls the toggle endpoint. Use the existing test setup in `src/test/`.
