---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a project detail page at `/projects/:projectId` in `src/routes/project.tsx`: it shows the project's name and status using `getProject` from `src/api.ts` (show a proper not-found page when it returns null), has a small rename form that calls `renameProject`, and a link back to `/`. Register the route in `src/main.tsx`. Also make sure errors on any page show a friendly message instead of a crash screen.
