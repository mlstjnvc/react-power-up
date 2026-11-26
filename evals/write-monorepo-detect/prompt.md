---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

In the admin app, add a users page at `/users` in `apps/admin/src/routes/users.tsx` that lists users from `getUsers` in `apps/admin/src/api.ts`, with a link to each user's `/users/:userId` (the detail page doesn't exist yet). Register the route.
