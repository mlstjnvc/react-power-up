---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add Redux Toolkit state for a list of notes to this Next.js app. Put the slice in `lib/notesSlice.ts` (add a note with a title and a created-at time, toggle pinned, delete), set up the store in `lib/store.ts`, typed hooks in `lib/hooks.ts`, and whatever provider is needed so `app/page.tsx` can render a client component `app/NotesBoard.tsx` that lists the notes and adds/pins/deletes them.
