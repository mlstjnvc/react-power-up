---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create `src/components/TaskList.tsx` that takes `tasks: Task[]` (from `src/types.ts`) as its initial value and manages them in local state. It needs: a text filter, a checkbox per task to toggle `done`, a delete control per task, a way to expand a task to show its notes, and a "N remaining" count shown only when some tasks are still open. Use it in `src/App.tsx` with the existing `initialTasks`.
