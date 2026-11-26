---
name: react-power-up
description: Use when writing, changing or reviewing React code with TypeScript — .tsx components, custom hooks (use* functions), context, forms, Next.js App Router pages, layouts, Server Actions and route handlers, React Router or TanStack Router routes, TanStack Query (React Query) hooks, Zustand or Redux Toolkit stores, React Hook Form with Zod, and their tests. A "hook" request that names no framework is React. Applies version-aware React 19/18 best practices, anti-pattern guardrails and security checks. Not for Vue, Nuxt, Svelte, Angular, Solid or React Native.
---

# react-power-up

The user describes what they need. You deliver production-quality React + TypeScript code that:
- fits their project type, installed versions and conventions
- avoids known anti-patterns
- is secure by default.

The rules live in `references/`. Load only the files the task needs (see [References](#references)).

## Workflow

Follow these steps in order for every write task. Steps 1–3 can be brief for small changes, but they can't be skipped.

### 1. Understand the request
- Restate the deliverable in one line.
- Ask **only** if the ambiguity changes the architecture, for example:
  - server component or client component?
  - URL state, local state, a store, or server cache?
  - a new route or a modal / in-page view?
  - Server Action or route handler?
- Otherwise pick the sensible default and name it in your report.

### 2. Detect the project context
- **Versions:** see [Version detection](#version-detection). Do this before writing any code.
- **Project type:** see [Project type](#project-type). It decides which references apply.
- **React Compiler:** see [React Compiler](#react-compiler). It decides the memoization advice.
- **TypeScript:** check whether `strict` is on. If it's off, still write strict-clean code.
- **Conventions:** open 1–2 existing files of the same kind (component, hook, route, store, test) and match their folder layout, naming and style. Exception: if a convention is an anti-pattern in the catalog, follow the rule and say so.
- **Existing libraries:** data fetching, state, router, forms and validation, UI kit, styling, test runner and libraries, ESLint config (`eslint-plugin-react-hooks`?). Use what's there. **Never add a dependency without asking.**

### 3. Plan the files
List the components, hooks, routes, stores, actions or handlers, schemas and tests you'll create or change, with one line each on why it lives there.
- In Next.js App Router, mark each file **server** or **client**.
- Keep components single-purpose. Logic used in more than one place goes in a custom hook, a store or a shared module.

### 4. Implement with the guardrails
- New code uses **function components and hooks in `.tsx`**. Leave existing class components alone unless the task changes them.
- Apply the rules from `references/`, **version-gated**: never use an API above the detected version. If a newer API would be better, mention the upgrade path in one line.
- No `any`, no unchecked `as` casts, and no `!` used just to silence the compiler.
- **Data fetching goes through the project's data layer.** If TanStack Query, a router loader or Server Components are available, fetch with them. That holds even when the request says "use `useEffect`" or "keep it in `useState`": treat it as a guardrail conflict, build the data-layer version and explain why. Read [`references/effects.md`](references/effects.md) before writing any `useEffect`.
- Never hand-edit generated files: `routeTree.gen.ts`, `.react-router/`, `.next/`, `next-env.d.ts`.

### 5. Security pass
Trace every new data flow from its source to its sink.
- **Sources:** user input, URL and search params, route params, API responses, cookies, storage, CMS content.
- **Sinks, and what each needs:**
  - **HTML:** untrusted data never goes into `dangerouslySetInnerHTML`. Render it as text; sanitize only after the user approves a sanitizer dependency (REACT-SEC-001).
  - **URL attributes:** untrusted values in `href`, `src`, `action` or `formAction` need scheme validation, so no `javascript:` (REACT-SEC-002).
  - **Redirects and navigation:** user-controlled targets (`?redirect=`, `next=`) must be same-origin relative paths (REACT-SEC-003, REACT-RR-005).
  - **Server code** (Server Actions, route handlers, loaders, router actions): validate every input, check auth and ownership in the function itself, never fetch a user-supplied URL, and return only the fields the client needs (REACT-NEXT-101, -102, -103, -106, REACT-SEC-005, -006, REACT-FORM-002).
  - **Client-visible data:** keep secrets out of client components, `NEXT_PUBLIC_*` / `VITE_*` vars, props passed from server to client components, and hydrated caches or stores (REACT-SEC-004, REACT-NEXT-105).
  - **Code execution:** never `eval`/`new Function`/dynamic `import()` user input (REACT-SEC-007).
  - **Cookies and tokens:** sessions use server-set `httpOnly` / `secure` / `sameSite` cookies, not `localStorage`, and state never changes on GET (REACT-NEXT-111, REACT-SEC-008, -009).
  - Load [`references/security.md`](references/security.md) whenever a flow reaches one of these sinks.

### 6. Tests
- **If the project has a test setup,** add or update tests for the behaviour you built, with the project's runner and libraries ([`references/testing.md`](references/testing.md)). Test what the user sees and does (query by role or label), await with `findBy`/`waitFor` instead of sleeps, give each test a fresh `QueryClient` or store, mock the network at the boundary, and on Vitest without `globals: true` make sure the setup file calls RTL's `cleanup` in `afterEach`.
- **If there's no test setup,** say so and offer to add one. Don't install anything without consent.

### 7. Self-check
Check the code you produced against every red flag below and against the rules of the reference files you loaded. Then run the project's **existing** checks, if they're installed:
- **type check:** a `typecheck` script, or `npx tsc --noEmit`. For TanStack Router, generate the route tree first if the project's script does that.
- **lint**, including `react-hooks` rules if configured
- **the tests** covering the changed files.

Fix failures your change caused. Report pre-existing failures, but don't fix them unless asked.

### 8. Report
Summarize what you built (files, their purpose, and server/client in Next.js), the defaults you chose in step 1, version-related choices, the checks run and their results, and **every guardrail deviation**: each place where you didn't follow the request literally, and why.

## When a request conflicts with a guardrail

Build the safe or idiomatic version, and explain the deviation in your report: what was asked, what you did instead, and the risk you avoided. Don't comply silently and don't refuse silently.

If the user insists after the explanation, do what they asked. Add a code comment at that spot naming the risk and the rule id, for example `// REACT-SEC-001 accepted by user: renders unsanitized HTML`.

## Reviewing code

When the user asks to review React code in plain language ("review this component"), follow [`references/review.md`](references/review.md), with the named files as the scope. To review uncommitted changes or a commit, the user can run `/react-power-up:review [commit]`. A review never edits files. Apply proposed changes only when the user asks for them afterwards.

## Version detection

1. **Find the right `package.json`.** In a monorepo, use the nearest one above the files you're changing.
2. **Resolve installed versions in this order:**
   - `node_modules/<pkg>/package.json` → `version`
   - otherwise, the lockfile entry (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`)
   - otherwise, the minimum of the `package.json` range (`^18.2.0` → 18.2.0).
3. **Packages to resolve:**
   - core: `react`, `react-dom`, `@types/react`, `typescript`
   - frameworks and routers: `next`, `react-router` (or `react-router-dom` on v7), `@tanstack/react-router`
   - libraries: `@tanstack/react-query`, `zustand`, `@reduxjs/toolkit`, `react-redux`, `react-hook-form`, `@hookform/resolvers`, `zod`
   - tests: `vitest`, `jest`, `@testing-library/react`, `@testing-library/user-event`, `msw`.
4. **If you can't determine a version,** assume the latest stable release and say so in the report.

APIs that need a minimum version (rules carry their own **Applies** range):

| Need | Minimum |
|---|---|
| `useId`, `useSyncExternalStore`, `useTransition` / `useDeferredValue`, automatic batching | React 18 |
| `ref` as a prop (no `forwardRef`), `use()`, `useActionState`, `useOptimistic`, `useFormStatus`, `<form action={fn}>`, `<Context>` as provider, ref cleanup functions, `<title>`/`<meta>` in components | React 19 |
| `useEffectEvent`, `<Activity>` | React 19.2 |
| React Router v8 (all APIs from `react-router`, DOM APIs from `react-router/dom`) | React 19.2.7 |
| `isPending`, `gcTime`, single-object signature | TanStack Query 5 |
| Async `params`/`searchParams`/`cookies()`/`headers()` (must be awaited) | Next.js 15 (sync access removed in 16) |
| `proxy.ts` instead of `middleware.ts`; Cache Components (`"use cache"`, opt-in via `cacheComponents`); `revalidateTag(tag, profile)`, `updateTag` | Next.js 16 |

## Project type

Decide this from the nearest `package.json` and the files around it. If the signals conflict, ask.

| Type | Signals | Coverage |
|---|---|---|
| Next.js App Router | `next` dependency + an `app/` (or `src/app/`) directory | full |
| Next.js Pages Router | `next` dependency + `pages/` only | noted only: say so, apply the core React rules, and don't apply App Router rules |
| React Router framework mode | `react-router.config.*` or `@react-router/dev` | noted only: core React rules plus the React Router rules that apply to library mode |
| TanStack Router SPA | `@tanstack/react-router`, `routeTree.gen.ts`, or a TanStack router plugin in the Vite config | full |
| React Router SPA (library mode) | `react-router` / `react-router-dom` dependency, no framework config | full |
| Plain React SPA | none of the above | core React rules |

A `.tsx` file that imports from `react` is React even if the prompt doesn't say so. React Native (`react-native`, `expo`) is out of scope: say so and don't apply these rules.

## React Compiler

The compiler is **enabled** if `babel-plugin-react-compiler` is a dependency and it's configured in any of these places:
- the Babel config
- the Vite React plugin's `babel` option (`@vitejs/plugin-react` < 6)
- `reactCompilerPreset()` with `@rolldown/plugin-babel` (`@vitejs/plugin-react` ≥ 6)
- `reactCompiler: true` in `next.config.*`.

| Compiler | Memoization advice |
|---|---|
| on | Don't add `useMemo` / `useCallback` / `memo`. Existing ones are redundant (`info`), so leave them unless the task touches that code. |
| off | Memoize only for a measured or obvious cost, or where referential identity matters (a dependency of another hook, or a prop of a memoized child). |

## Red flags

If you're about to do any of these, stop and fix the approach:

- Writing code before resolving versions and project type, or using an API above the detected version
- Adding a dependency, or changing `tsconfig` or lint config, without asking
- Writing a new class component (the one exception is an error boundary, REACT-COMP-010), or a new `.js`/`.jsx` file in a TypeScript project
- Following a request literally when it hits a guardrail, without explaining the deviation
- Leaving a new data flow unchecked by the security pass
- Editing a generated file (`routeTree.gen.ts`, `.react-router/`, `.next/`)
- Claiming checks passed without running them
- `any`, an unchecked `as`, or `!` to make an error go away (REACT-TS-002)
- Defining a component inside another component's body (REACT-COMP-001)
- Mutating a prop, or doing side effects (fetches, subscriptions, module writes) during render (REACT-COMP-002, REACT-COMP-003)
- A hook after an early `return`, or inside a condition, loop or handler (REACT-HOOK-001, REACT-HOOK-002)
- A missing or suppressed hook dependency (`eslint-disable … exhaustive-deps`) (REACT-HOOK-003)
- Fetching in `useEffect` when the project has TanStack Query, a router loader or Server Components: use those, even if the request says `useEffect`, and explain why. Without a data layer, a fetch effect needs race handling (REACT-EFF-005)
- `useEffect` to derive state or run event logic, or an effect that subscribes without cleanup (REACT-EFF-001, -002, -006)
- An index or random `key` on a list that can change, `{count && …}` with a number, or `onClick={fn()}` (REACT-JSX-001, -002, -007)
- A clickable `<div>`/`<span>`, or a form control with no label (REACT-JSX-003, REACT-JSX-004)
- On React 19: an action passed to `useActionState` that reads `formData` first, or `useFormStatus` in the component that renders the `<form>` (REACT-ACT-002, REACT-ACT-003)
- On React 18: `<form action={fn}>`, `useActionState`, `useOptimistic`, `useFormStatus` or `use()` (REACT-ACT-005)
- A module-scope store in an SSR app; a Zustand v5 selector returning a new object or array without `useShallow`; non-serializable Redux state (REACT-STATE-006, -004, -009)
- TanStack Query: a variable used by `queryFn` missing from `queryKey`, a `QueryClient` created in render or shared across server requests, `onSuccess` on a v5 query, or a mutation that never invalidates (REACT-QUERY-001, -003, -005, -006)
- React Router: `navigate()` during render, a `?redirect=` value used unvalidated, or `react-router-dom` imports on v8 (REACT-RR-004, -005, -007)
- TanStack Router: a loader that reads search params without `loaderDeps`, or search params read without `validateSearch` (REACT-TSR-004, REACT-TSR-003)
- Forms: data from a form or action used on the server without parsing it with the schema; an `index` key in `useFieldArray`; a number input without `valueAsNumber` or coercion (REACT-FORM-002, -007, -008)
- Next.js: `'use client'` on a page or layout; non-serializable props into a client component; un-awaited `params`/`cookies()` on 15+; `window`/`localStorage` during render; per-request data in module scope (REACT-NEXT-001, -002, -004, -005, -006)
- Next.js server: a Server Action or route handler without its own auth check and runtime validation; a whole DB record sent to the client; a secret in `NEXT_PUBLIC_*`; `redirect()` inside `try` (REACT-NEXT-101, -102, -103, -105, -106, -107)
- Using the wrong ref API for the version: ref-as-a-prop on React 18, or `defaultProps` on a React 19 function component (REACT-COMP-008, REACT-COMP-011)

## References

Load a file when the task touches its domain:

| File | Load when |
|---|---|
| [`references/typescript.md`](references/typescript.md) | Any `.tsx` file or TS code using React APIs: props, children, events, refs, context types, generic components |
| [`references/components.md`](references/components.md) | Creating or changing components: purity, props, controlled inputs, composition, context providers, refs, error boundaries, Suspense |
| [`references/hooks.md`](references/hooks.md) | Any hook call, `useState`/`useReducer`, dependency arrays, refs, custom hooks, external stores |
| [`references/effects.md`](references/effects.md) | Before writing **any** `useEffect`: derived state, event logic, fetching, subscriptions, timers, StrictMode |
| [`references/actions.md`](references/actions.md) | Form submissions and mutations on React 19: `useActionState`, `useOptimistic`, `useFormStatus`, `<form action>`, `startTransition`; React 18 fallbacks |
| [`references/forms.md`](references/forms.md) | Any form with React Hook Form or Zod: schemas, resolvers, server re-validation, `Controller`, field arrays, error messages, async defaults |
| [`references/jsx.md`](references/jsx.md) | Writing JSX: lists and keys, conditional rendering, event handlers, buttons and links, form labels, accessible names for repeated row actions, images, disclosure widgets |
| [`references/state.md`](references/state.md) | Deciding where state lives; any Zustand store or Redux Toolkit slice, store setup, selectors; URL state |
| [`references/tanstack-query.md`](references/tanstack-query.md) | Any `useQuery`/`useMutation`/`queryOptions`, `QueryClient` setup, cache invalidation, optimistic updates, SSR prefetching |
| [`references/react-router.md`](references/react-router.md) | React Router (library mode): route config, loaders, actions, params, links, navigation, redirects, error boundaries; v7 vs v8 |
| [`references/tanstack-router.md`](references/tanstack-router.md) | TanStack Router: file routes, route tree, router registration, search params, loaders, typed links, `beforeLoad` auth, Query integration |
| [`references/nextjs.md`](references/nextjs.md) | Any Next.js App Router page, layout or component: server vs client, data fetching, streaming, caching, links, images, metadata, error/loading files |
| [`references/nextjs-server.md`](references/nextjs-server.md) | Next.js Server Actions, route handlers, `proxy.ts`/`middleware.ts`, env vars, `server-only`, sessions and cookies, revalidation after mutations |
| [`references/security.md`](references/security.md) | A data flow reaches HTML, a URL attribute, a redirect, server code, client-visible data, `eval`, or token/cookie storage |
| [`references/performance.md`](references/performance.md) | Memoization decisions (React Compiler on or off), slow renders, input lag, large lists, code splitting, bundle size |
| [`references/testing.md`](references/testing.md) | Writing or changing tests: Vitest/Jest, Testing Library queries, user-event, async waits, MSW (v2/v3), provider and router wrappers, Next.js testing limits |
| [`references/review.md`](references/review.md) | The user asks for a review: procedure, verdict rules, output format |
| [`references/rule-catalog.md`](references/rule-catalog.md) | You need the rule format, severities, or the index of every rule id |
