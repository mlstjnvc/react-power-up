---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Build a newsletter sign-up.

1. `src/components/EmailInput.tsx`: a labelled email input that a parent component can focus through a ref.
2. `src/components/NewsletterForm.tsx`: a form that uses `EmailInput`, calls `subscribe` from `src/api.ts` on submit, shows a pending state on the submit button while the request runs, shows an error message if it fails (and focuses the email field), and a thank-you message on success.
3. Render `NewsletterForm` in `src/App.tsx`.
