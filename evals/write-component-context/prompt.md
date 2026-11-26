---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add sign-in to the app using the functions in `src/api.ts`.

1. Create `src/auth/AuthContext.tsx` with an `AuthProvider` that holds the current user and exposes `signIn` and `signOut`, plus a `useAuth` hook for consuming it.
2. Create a reusable `src/components/TextInput.tsx`: a labelled text input that a parent can focus through a ref.
3. Create `src/components/SignInForm.tsx` that uses `TextInput` for email and password, calls `signIn` from the context, focuses the email field when sign-in fails, and shows the user's name with a sign-out button once signed in.
4. Wrap the app in `AuthProvider` in `src/App.tsx` and render `SignInForm`.
