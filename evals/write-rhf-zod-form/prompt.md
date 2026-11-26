---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Build a conference registration form in `src/components/RegistrationForm.tsx` with React Hook Form and Zod. Fields: full name (required), email (valid email), number of tickets (1–10), and a list of attendee names (one per ticket, add/remove rows). Put the schema in `src/schemas/registration.ts` so the backend team can reuse it. On submit call `register` from `src/api.ts`, show a success message with the returned id, and show validation errors next to the fields. Render the form in `src/App.tsx`.
