---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a profile settings page at `app/settings/page.tsx` where the signed-in user can change their display name (2–40 characters) and bio (max 280). Use `lib/db.ts` and `getCurrentUser` from `lib/auth.ts`. Put the form in `app/settings/ProfileForm.tsx` and the save logic in a Server Action in `app/settings/actions.ts`. After saving, redirect to `/settings?saved=1`; if saving fails, show an error message on the form. Signed-out users should be sent to `/login`.
