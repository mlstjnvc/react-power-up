# Spec: react-power-up

> Status: **APPROVED v1 (2026-11-24).** Open questions resolved (D14–D16). Next: Plan phase.
> Sister plugin to **vue-power-up** (`~/projects/vue-power`). It has the same shape, workflow and quality bar, applied to React + TypeScript.
> Nothing in this repo gets committed: the user handles git. All changes stay in the working tree.

## Decisions log

| # | Decision | Source |
|---|---|---|
| D1 | The plugin, its main skill and the repo are all named **`react-power-up`** (`~/projects/react-power-up`). | User, 2026-11-24 |
| D2 | **Separate repo with its own marketplace** for now. vue-power is not touched. Listing both plugins in a single `ml2stjnvc` marketplace is a later publishing step. | User, 2026-11-24 |
| D3 | **Primary use is writing code.** The user describes what's needed, and Claude delivers it following best practices, guardrails and security. Review is secondary. *(Carried over from vue-power-up D3.)* | User, 2026-11-24 |
| D4 | **React 19 is primary.** React 18 differences are noted per rule and gated on the detected version. | User, 2026-11-24 |
| D5 | **Full-stack framework: Next.js App Router.** It is the Nuxt equivalent: server components, client boundaries, Server Actions, route handlers, caching and middleware/proxy. The Pages Router is detected and noted, but not covered in depth. TanStack Start is out of scope. | User, 2026-11-24 (accepted recommendation) |
| D6 | **Routing: React Router and TanStack Router v1.** React Router is covered in library mode (data mode with `createBrowserRouter`, loaders and actions, plus declarative mode). Framework mode (formerly Remix) is detected and noted only. *Plan-phase correction:* the current major is **v8** (it requires React ≥ 19.2.7, is ESM-only, removes `react-router-dom`, and makes the v7 future flags the default), so **v8 is primary and v7 is noted** for React 18 projects. TanStack Router is covered fully: file-based and code-based routes, typed params, search-param validation, loaders, and integration with TanStack Query. | User, 2026-11-24 (accepted recommendation) |
| D7 | **Library coverage:**<br>• data fetching: **TanStack Query v5**<br>• state: **Zustand** and **Redux Toolkit**, including RTK Query basics<br>• forms: **React Hook Form** with **Zod**<br>• testing: **Vitest** (Jest noted), **React Testing Library**, **user-event** and **MSW**.<br>Libraries mentioned only, with no rules of their own: SWR, Jotai, Playwright, TanStack Table, Tailwind, shadcn/ui. | User, 2026-11-24 (accepted recommendation) |
| D8 | **No hooks and no audit mode** in this version. Enforcement comes from skill guidance plus a mandatory self-check. *(Carried over from vue-power-up D2/D7.)* | Same scope as vue-power-up |
| D9 | Writing triggers automatically through the skill (no command). Review gets **one slash command: `/react-power-up:review [commit]`**. It is implemented as a user-invoked plugin skill (`disable-model-invocation: true`). *(Same as vue-power-up D8/D10.)* | Same as vue-power-up |
| D10 | The review skill loads the shared catalog through `${CLAUDE_PLUGIN_ROOT}/skills/react-power-up/references/…`, so the rules exist in one place only. *(Same as vue-power-up D11.)* | Same as vue-power-up |
| D11 | **Review precondition and output are identical to vue-power-up D13/D14:**<br>• a git check runs first<br>• everything is read-only git<br>• the output is a standard code review with numbered `diff` proposals<br>• nothing is applied until the user asks.<br>`precheck.sh` and its shell tests are reused from vue-power, adapted to the new command name. | Same as vue-power-up |
| D12 | Evals use the native `claude plugin eval` format. **The user runs the full eval (3 runs, with and without the plugin as baseline).** During development only targeted single-run cases are run. *(Same as vue-power-up D12/D15.)* | Same as vue-power-up |
| D13 | **README.md and docs/RATIONALE.md are deliverables.** They are created with the plugin and updated in the same task as any change to behaviour, commands, install steps or rules. RATIONALE explains every decision and every rule. | Same as vue-power-up D9 + project rule |
| D14 | The marketplace is named **`mlsstjnvc`**, owner **Milos Stojanovic**, so the install id is **`react-power-up@mlsstjnvc`**. | User, 2026-11-24 |
| D15 | `plugin.json` `author` is **Milos Stojanovic** and `license` is **MIT**, with a matching `LICENSE` file. `repository`/`homepage` stay unset until the GitHub repo exists. (Confirms A7.) | User, 2026-11-24 |
| D16 | Claude ran `git init` (branch `main`) for this repo. **Claude still never commits, pushes or tags**; the user handles all git writes. | User, 2026-11-24 |

## Assumptions

Correct any of these during review.

1. **One writing skill plus one review skill**, sharing one rule catalog that is the single source of truth.
2. **Target versions** (checked against npm on 2026-11-24; per-API details are verified against official docs in each task):

   | Package | Primary (npm latest) | Also handled |
   |---|---|---|
   | React | 19.x (19.3) | 18.x differences noted |
   | React Compiler | 1.x (`babel-plugin-react-compiler` 1.0) | not enabled |
   | TypeScript | 5.x–7.x (7.0 latest), `strict` | |
   | Next.js | 16 (16.4), App Router | 15 differences noted |
   | React Router | 8.x (8.5) | 7.x noted (React 18 projects) |
   | TanStack Router | 1.x (1.170) | |
   | TanStack Query | 5.x (5.108) | |
   | Zustand | 5.x (5.1) | |
   | Redux Toolkit | 2.x (2.15) | |
   | React Hook Form | 7.x (7.92) | |
   | Zod | 4.x (4.6) | 3.x noted |
   | Vitest | 5.x (5.1) | 3.x/4.x noted; Jest noted |
   | React Testing Library | 16.x, user-event 14.x | |
   | MSW | 3.x (3.0) | 2.x noted |

   Older versions are detected and handled, not rejected.
3. **New code is always function components and hooks, in `.tsx`.** Class components are left alone unless the task touches them. React Native is out of scope; it counts as a negative trigger.
4. **React Compiler is version-gated.** If the project has the compiler enabled, Claude doesn't add manual `useMemo`/`useCallback`/`memo`. Without it, Claude memoizes only for a measured or obvious cost, or where referential identity matters.
5. **Rules are grounded in official sources.** These are react.dev (including "You Might Not Need an Effect" and the Rules of React), the Next.js docs, the React Router docs, the TanStack docs, the Redux/RTK and Zustand docs, React Hook Form, Zod, the Testing Library docs, the eslint-plugin-react-hooks and jsx-a11y rule docs, the TypeScript handbook, and OWASP for security. Opinions that no official source backs are `info` at most.
6. **Project type is detected, not assumed.** The workflow decides between Next.js App Router, Next.js Pages Router (noted only), a Vite SPA with React Router, a Vite SPA with TanStack Router, and React Router framework mode (noted only).
7. **Publishing metadata:** `author` Milos Stojanovic and `license` MIT, the same as vue-power-up D17, with a matching `LICENSE`. `repository`/`homepage` stay unset until the GitHub repo exists. *(Please confirm; see Open Questions.)*
8. **vue-power-up is the structural reference** for layout, rule format, workflow, review procedure and eval design. It is the user's own work, so reusing its structure and `precheck.sh` is fine. Its Vue-specific text doesn't carry over.

## Objective

Build a Claude Code plugin, **react-power-up**, with one writing skill and one review command. The user describes a feature in plain language, for example:
- "add a paginated orders table with filters backed by TanStack Query"
- "create a sign-up form with React Hook Form and a Next.js Server Action"
- "add a typed `/projects/$id` route with TanStack Router".

Claude then delivers production-quality React + TypeScript code that:

- follows current best practices for React 19, TypeScript, Next.js App Router, React Router or TanStack Router, and the D7 libraries
- avoids known anti-patterns (guardrails), above all effect misuse, Rules of Hooks violations and server/client boundary mistakes
- is **secure by default**: no XSS sinks, no secrets in client bundles, validated and authorized Server Actions and route handlers, safe redirects
- fits the project it's in: detected versions, project type, existing conventions and libraries
- comes with tests when the project has a test setup.

Secondary: **`/react-power-up:review`** reviews the current changes, or a given commit, against the same catalog.

**Users:** React developers using Claude Code, locally and through the marketplace. Defaults must be neutral and well sourced.

### User stories

- *As a developer* in a Next.js app, I say "add a profile settings form". Claude builds the following without my asking:
  - a server component page that fetches the data
  - a small `'use client'` form using React Hook Form with a Zod schema
  - a Server Action that validates with the **same** schema and checks the session
  - `useActionState` (React 19) for pending and error state
  - a behaviour test.
- *As a developer* in a Vite SPA, I ask for a list page with search. Claude:
  - stores the search state in validated, typed search params (TanStack Router) or `useSearchParams` (React Router)
  - fetches with TanStack Query using a structured query key
  - doesn't use `useEffect` to fetch or to derive state.
- *As a developer*, I ask for something insecure if taken literally ("render the user's bio HTML", "put the API key in an env var the client reads"). Claude flags the risk, implements the safe variant and explains why.
- *As a developer* on React 18, I ask for a component that forwards a ref. Claude uses `forwardRef` (in 19 it would pass `ref` as a prop) and mentions the upgrade path in one line.
- *As a developer*, I run `/react-power-up:review` before committing. I get a standard code review with rule ids, `file:line`, why each finding matters, and numbered `diff` proposals.
- *As a reviewer*, I run `/react-power-up:review a1b2c3d` to review exactly that commit.

## Tech Stack (of the plugin itself)

- Markdown skill files (`SKILL.md` + `references/*.md`), a user-invoked review skill, JSON manifests and one POSIX shell precheck script. No other runtime code and no hooks.
- Eval material: prompts plus small `.tsx`/`.ts` fixtures and scaffold scripts.

## Commands

```bash
# Validate plugin + marketplace manifests (--strict: warnings fail)
claude plugin validate .
claude plugin validate . --strict

# Show the plugin's component inventory (load from disk: --plugin-dir goes before the subcommand)
claude --plugin-dir . plugin details react-power-up

# Use locally without installing (dev loop)
claude --plugin-dir ~/projects/react-power-up

# Review current uncommitted changes / a specific commit (inside a Claude Code session)
/react-power-up:review
/react-power-up:review <commit-hash>

# Plugin-internal checks (no model involved)
sh tests/precheck.test.sh
python3 tests/check_catalog.py      # every rule id in references ⇄ rule-catalog.md
python3 tests/check_links.py        # every Source link resolves

# Run the eval suite from the repo root (--scaffold is needed for git-repo fixtures)
claude plugin eval . --scaffold --runs 1 --ablation none   # fast iteration
claude plugin eval . --scaffold                            # full run: 3 runs, with/without baseline (the user runs this, D12)

# Install through the local marketplace (D14)
/plugin marketplace add ~/projects/react-power-up
/plugin install react-power-up@mlsstjnvc
```

## Project Structure

```
.claude-plugin/
  plugin.json             → name react-power-up, version, description, author, license MIT (A7); repository/homepage unset
  marketplace.json        → own marketplace listing this plugin (source "./") (D2)
skills/
  review/
    SKILL.md              → /react-power-up:review [commit] (user-invoked only): precheck, scope via read-only git, then references/review.md
    scripts/precheck.sh   → git precondition check, prints one PRECHECK= status line (reused from vue-power, D11)
  react-power-up/
    SKILL.md              → triggers, write workflow, project-type and version detection, top guardrails, security checklist, self-check
    references/
      typescript.md       → strict TS, typing props/children/events/refs/context, generic components, discriminated-union props, no React.FC requirement
      hooks.md            → Rules of Hooks, dependency arrays, useState/useReducer, useRef, custom hooks, use(), useId, useSyncExternalStore
      effects.md          → "You Might Not Need an Effect": derived state, event logic, fetching, cleanup, race conditions, StrictMode double-invoke
      components.md       → composition over props explosion, children/slots, controlled vs uncontrolled, context (split, memoized value), ref as prop (19) vs forwardRef (18), error boundaries, Suspense
      jsx.md              → keys, conditional rendering pitfalls (`0 &&`), lists, fragments, event handlers, accessibility basics (semantic elements, labels, jsx-a11y)
      actions.md          → React 19 Actions: useActionState, useOptimistic, useFormStatus, form `action`, transitions; React 18 fallbacks
      state.md            → where state lives (local → lifted → context → store → URL → server cache), Zustand (selectors, slices, no store-in-render), Redux Toolkit (createSlice, typed hooks, RTK Query basics)
      tanstack-query.md   → query keys/factories, queryOptions, staleTime, invalidation, mutations + optimistic updates, enabled/dependent queries, Suspense, SSR prefetch + HydrationBoundary
      react-router.md     → v8 data mode (v7 noted) (createBrowserRouter, loaders/actions, errorElement, lazy routes), declarative mode, typed params, useSearchParams, redirects, framework mode noted
      tanstack-router.md  → file vs code routes, route tree gen, typed Link/navigate, validateSearch with Zod, loaders + Query integration, beforeLoad auth, pending/error components
      nextjs.md           → rendering: server vs client components, 'use client' boundaries, data fetching in RSC, caching & revalidation (Cache Components / "use cache"), Suspense/streaming, metadata, next/link, next/image, Next 15 vs 16 notes, Pages Router noted
      nextjs-server.md    → server side: Server Actions, route handlers, proxy.ts (middleware.ts on 15), env vars & runtime config, server-only, cookies/headers APIs
      forms.md            → React Hook Form (register vs Controller, resolver, field arrays, errors + a11y), Zod schemas shared client/server, z.infer types
      security.md         → dangerouslySetInnerHTML, URL/href (`javascript:`) and redirect safety, secrets & NEXT_PUBLIC_, Server Action/route-handler authz + validation, server-only, data leaking from RSC to client props, cookies, SSRF, CSRF notes
      performance.md      → React Compiler awareness, when memo/useMemo/useCallback help, list virtualization, code splitting (lazy, dynamic), transitions/useDeferredValue, context re-render scope, bundle hygiene
      testing.md          → Vitest + RTL + user-event, queries by role, findBy over waits, MSW for network, testing with QueryClient/router/store providers, testing Server Actions & RSC limits
      review.md           → review procedure, severity model, finding format (used by the command and plain-language review requests)
      rule-catalog.md     → index: id, severity, summary, applies-range, source, reference file
evals/                    → `claude plugin eval` suite; results/ is gitignored
  write-<topic>/          → prompt.md + graders/ (regex over produced files, LLM rubric, Skill tool used)
  review-<topic>/         → case.yaml scaffold builds a git repo seeded with anti-patterns; graders check rule ids
  trigger-<topic>/        → should / shouldn't fire the skill
tests/
  precheck.test.sh        → plain-shell tests for precheck.sh
  check_catalog.py        → catalog ⇄ references consistency
  check_links.py          → source-link check
docs/
  RATIONALE.md            → reasoning for EVERY decision and rule (project rule)
LICENSE                   → MIT (A7)
README.md                 → what it does, install, write examples, review usage, rule overview, evals, limitations
SPEC.md                   → this file
tasks/plan.md, tasks/todo.md
```

## Behaviour

### Write workflow (primary)
SKILL.md makes Claude follow these steps in order. The shape matches vue-power-up; the React specifics are listed under each step.

1. **Understand the request.** Restate the deliverable in one line. Ask only when the answer changes the architecture, for example server vs client component, URL state vs local state vs store, a new route vs a modal, or a Server Action vs a route handler. Otherwise pick the default and say which one.
2. **Detect the context:**
   - versions from `node_modules`, then the lockfile, then `package.json`: `react`, `react-dom`, `next`, `react-router`, `@tanstack/react-router`, `@tanstack/react-query`, `zustand`, `@reduxjs/toolkit`, `react-hook-form`, `zod`, the test libraries and `typescript`
   - `tsconfig` strictness
   - whether React Compiler is enabled (`babel-plugin-react-compiler` or `reactCompiler` in the Next config)
   - the project type (A6), from the `app/` vs `pages/` dir, `next.config.*`, `react-router.config.*`, `routeTree.gen.ts` or `vite.config.*`
   - existing conventions: folder layout, state library, validation library, UI library, test setup.

   Load only the references the task needs.
3. **Plan the files.** List the components, hooks, routes, stores, actions or handlers, schemas and tests to create or change, and say why each lives where it does. In Next.js, mark which files are server and which are client.
4. **Implement with the guardrails**, version-gated.
5. **Security pass.** Trace every new data flow to its sink: `dangerouslySetInnerHTML`, `href`/`src`, redirects and navigation, Server Actions and route handlers (validation plus authorization), props crossing from server to client, env vars, cookies, and server-side `fetch(userUrl)`.
6. **Tests.** If a test setup exists, write behaviour tests with RTL, user-event and MSW. If not, say so and offer to set one up. Never add dependencies without asking.
7. **Self-check.** Check the produced code against the red-flag list. Then run the project's **existing** `tsc --noEmit` (or `next typegen`/build typecheck where that's the project's mechanism), its lint (including `react-hooks` rules if configured) and its tests.
8. **Report.** What was built, the defaults chosen, the checks run, and any place where a guardrail meant the request was not followed literally.

### When a request conflicts with a guardrail
Same as vue-power-up: Claude builds the safe version and explains the deviation. If the user explicitly insists after that, Claude complies and leaves a code comment naming the rule id.

### Version awareness
Every rule has an **Applies** range. Claude never emits an API the installed version lacks. Examples by version:

- **React 19 only:**
  - `ref` as a prop
  - `use()`
  - `useActionState`, `useOptimistic`, `useFormStatus`
  - `<form action={fn}>`
  - `<Context>` used as the provider
  - ref cleanup functions
  - document metadata tags
- **React 18 equivalents:** `forwardRef`, `<Context.Provider>`, manual pending state.
- **Next.js 15 vs 16:** `proxy.ts` (16) vs `middleware.ts` (15), Cache Components / `"use cache"` (16, opt-in via `cacheComponents`), async request APIs. Exact per-API details are verified in the Next.js tasks.
- **React Router 7 vs 8:** v8 imports everything from `react-router` (DOM APIs from `react-router/dom`); v7 projects may still use `react-router-dom`. Middleware is on by default in v8.
- **Zod 3 vs 4:** API differences.

When a version blocks a better API, Claude mentions the upgrade path in one line.

### Review: `/react-power-up:review [commit]` (secondary)
Same contract as vue-power-up's review: the same scope table, the same `precheck.sh` statuses and messages (with the command name substituted), the same hash validation (`^[0-9a-fA-F]{4,40}$`), merge commits reviewed against the first parent, the root commit reviewed against the empty tree, the same read-only guarantee, and the same output format:

1. scope and detected versions
2. summary
3. verdict
4. findings by severity
5. numbered `diff` proposals
6. what's done well (optional)
7. "To apply any of these, tell me which."

React-specific differences:

- **Files reviewed:**
  - `.tsx`, `.ts`, `.jsx`, `.js`, `.mjs`
  - `next.config.*`, `middleware.*`/`proxy.*`
  - `app/**`, `pages/**`, `routes/**`
  - `package.json` (for version context)
  - `tsconfig*.json`
  - `.env.example`
- **Skipped:**
  - lockfiles
  - `.next/`, `dist/`, `build/`, `coverage/`
  - generated `routeTree.gen.ts`, `.react-router/`
  - binaries
- **Detected versions** are read from the reviewed state's `package.json` (for a commit, `git show <hash>:package.json`).

### Content coverage (anti-patterns the skill must prevent; not exhaustive)

- **TS (`TS`):**
  - `any` and unsafe `as` casts
  - untyped props or `children`
  - event handlers typed as `any`
  - `useRef` without a type or initial value (19 types require an argument)
  - context created with an `undefined` default and no guard hook
  - non-null `!` used to silence errors
  - boolean-soup props where a discriminated union fits.
- **Hooks (`HOOK`):**
  - hooks called conditionally, in loops, or outside components and hooks
  - missing or suppressed dependencies (`eslint-disable react-hooks/exhaustive-deps`)
  - object or function dependencies recreated on every render
  - stale closures
  - `useState` initializers doing expensive work without the lazy form
  - state updates that depend on previous state without the updater form
  - mutating state directly
  - custom hooks not named `use*`.
- **Effects (`EFF`):**
  - deriving state in an effect instead of during render
  - effects for event logic
  - fetching in `useEffect` without cleanup or race handling, when the project has Query, a router loader or RSC available
  - syncing props into state
  - missing cleanup for subscriptions, timers or listeners
  - effect chains
  - resetting state with an effect instead of `key`.
- **Components (`COMP`):**
  - components defined inside components
  - prop drilling where composition or context fits
  - one giant context value that re-renders everything
  - an unmemoized context value object
  - mixing controlled and uncontrolled inputs
  - missing error boundaries or Suspense fallbacks around async UI
  - `forwardRef` on React 19 (`warn`), and ref-as-prop on 18 (`error`).
- **JSX (`JSX`):**
  - missing keys, or an index used as the key on reorderable lists
  - `{count && …}` rendering `0`
  - `onClick` on a non-interactive element without a role and keyboard support
  - inputs without labels
  - images without `alt`
  - heavy logic inline in JSX.
- **Actions (`ACT`, React 19):**
  - manual `isPending` state where `useActionState` or `useTransition` fits
  - `useFormStatus` used outside a `<form>` child
  - optimistic UI without a rollback path.
- **State (`STATE`):**
  - server data copied into a global store instead of a server cache
  - URL-worthy state (filters, pagination) kept in local state
  - Zustand: subscribing to the whole store without selectors, or a selector returning a new object without `useShallow`
  - Redux: hand-written reducers or actions instead of `createSlice`, untyped `useSelector`/`useDispatch`, non-serializable state.
- **TanStack Query (`QUERY`):**
  - unstable or ad-hoc query keys that are missing their params
  - a `QueryClient` created inside render
  - copying query data into `useState`
  - `onSuccess` on queries (removed in v5)
  - mutations that don't invalidate or update the cache
  - `refetch()` in an effect instead of putting the param in the key
  - SSR without prefetch plus `HydrationBoundary`, or with a shared server `QueryClient` (cross-request leak).
- **React Router (`RR`):**
  - fetching in an effect where a loader fits
  - unvalidated `params`
  - `<a href>` for internal navigation
  - `navigate()` during render
  - open redirects from a `?redirect=` param
  - routes with no `errorElement` / `ErrorBoundary`.
- **TanStack Router (`TSR`):**
  - untyped `useParams`/`useSearch` (`strict: false` used without reason)
  - unvalidated search params (no `validateSearch`)
  - auth checks in components instead of `beforeLoad`
  - hand-editing `routeTree.gen.ts`
  - string URLs instead of typed `to`/`params`
  - loaders that duplicate Query caching instead of using `ensureQueryData`.
- **Next.js (`NEXT`):**
  - `'use client'` at the top of whole trees, or on pages, without need
  - server-only code or secrets imported into client components (no `server-only`)
  - passing whole DB records or secrets as props to client components
  - fetching in client effects what an RSC can fetch
  - Server Actions without input validation or an auth check (they are public endpoints)
  - route handlers without validation or auth
  - `NEXT_PUBLIC_` on secrets
  - `<a>` and `<img>` instead of `next/link`/`next/image`
  - browser APIs used during server render
  - module-scope mutable state on the server
  - misuse of caching or revalidation
  - `redirect()` inside try/catch.
- **Forms (`FORM`):**
  - client-only validation with no server re-validation
  - duplicated schema and type (instead of `z.infer`)
  - `Controller` where `register` works, or the reverse for controlled UI libraries
  - errors not linked to inputs (`aria-invalid`, `aria-describedby`)
  - `watch()` over the whole form causing re-renders.
- **Security (`SEC`):**
  - `dangerouslySetInnerHTML` with untrusted data, with no sanitizer
  - `href`/`src` from user input (`javascript:` URLs)
  - open redirects
  - secrets in client bundles
  - unvalidated or unauthorized server mutations
  - SSRF through server `fetch(userUrl)`
  - insecure cookie flags
  - sensitive data serialized into RSC payloads or the hydrated Query cache
  - `eval`/`new Function` on user input.
- **Performance (`PERF`):**
  - blanket `useMemo`/`useCallback`/`memo`, or manual memoization when React Compiler is on (`info`)
  - un-virtualized huge lists
  - no code splitting for heavy routes or widgets
  - expensive work during render
  - frequently changing context high in the tree
  - barrel imports that defeat tree-shaking (`info`).
- **Testing (`TEST`):**
  - testing implementation details (state or instance internals)
  - `getByTestId` where a role or label query works
  - `fireEvent` where `userEvent` fits
  - arbitrary `setTimeout` waits instead of `findBy`/`waitFor`
  - mocking `fetch` by hand where MSW is set up
  - a `QueryClient` or store shared across tests (no isolation, retries left on)
  - missing router or provider wrappers.

## Code Style (of the skill content)

- **SKILL.md stays lean** (target ≤ ~300 lines). Detail lives in references that are loaded on demand.
- **Every rule has the same shape:** id · title · severity, **Why**, **Source** (official link), ❌/✅ minimal TSX example, **Applies** (version range), **Exceptions**.

```markdown
### REACT-EFF-001 · Derive values during render, not in an effect  `error`
**Why:** Storing derived data in state and syncing it with an effect causes an extra render with stale values, and the two can drift apart.
**Source:** https://react.dev/learn/you-might-not-need-an-effect#updating-state-based-on-props-or-state
​```tsx
// ❌
const [fullName, setFullName] = useState('')
useEffect(() => { setFullName(`${first} ${last}`) }, [first, last])
// ✅
const fullName = `${first} ${last}`
​```
**Applies:** React 18, 19 · **Exceptions:** the derivation is expensive and measured; use `useMemo`, or nothing if React Compiler is on.
```

- Rule ids follow `REACT-<DOMAIN>-NNN`. The domains are `TS`, `HOOK`, `EFF`, `COMP`, `JSX`, `ACT`, `STATE`, `QUERY`, `RR`, `TSR`, `NEXT`, `FORM`, `SEC`, `PERF`, `TEST`. Ids are stable and never renumbered.
- Severities are the same as vue-power-up: `error` (a bug, data leak or security issue), `warn` (fragile, legacy or unidiomatic), `info` (style or opinion).

## Testing Strategy (for the skill itself)

Skills are prompts, so verification is behavioural evals, weighted toward write mode (D3).

1. **Write evals (primary), about 12 prompts** covering:
   - a Next.js App Router form with a Server Action
   - a Next.js data page (RSC plus a client island)
   - a Next.js route handler
   - a Vite SPA list using TanStack Router, Query and search params
   - a React Router data-mode page with a loader and an action
   - a Zustand store
   - a Redux Toolkit slice
   - a React Hook Form + Zod form
   - extracting a custom hook
   - a component with context.

   Plus at least **3 traps**:
   - render user HTML
   - a secret in client env
   - "fetch this in a useEffect and store it in state".

   Each prompt has graders: forbidden rule ids, required behaviours, and "explains the deviation" for traps. The generated code must pass `tsc --noEmit` in scratch Vite and Next harnesses in the scratchpad directory, never in this repo.
2. **Version evals.** The same prompt runs against a React 18 `package.json` and a React 19 one (ref forwarding, form pending state). A Next 15 vs 16 case is added if the Plan phase confirms API deltas worth gating.
3. **Review evals (secondary):** about 12 fixtures, each seeded with 1–3 anti-patterns across the domains, plus **3 clean controls** (vue-power-up had only 2). Graders check the D11 output structure, the rule ids found, and that nothing was written.
4. **Review command evals:**
   - uncommitted changes (staged, unstaged and untracked)
   - a commit hash
   - a root commit
   - an invalid argument and an option-like argument
   - a clean tree
   - not a repo.

   Git state must be unchanged afterwards. `precheck.sh` also gets plain shell tests.
5. **Trigger evals.**
   - Positive: "build a React component…", "add a TanStack Query hook", "create a Next.js Server Action", "add a TanStack Router route".
   - Negative: Vue, Svelte, Angular, React Native, plain Node/Python.
   - The Vue negatives make sure the two plugins don't both fire when installed together.
6. **Manifest validation:** `claude plugin validate .` and `--strict`.

## Boundaries

- **Always:**
  - Cite an official source for every `error`/`warn` rule, and record the reasoning in `docs/RATIONALE.md`.
  - Version-gate rules.
  - Keep examples valid TSX.
  - Keep SKILL.md lean.
  - Update README in the same task as any change to behaviour, commands, install steps or rules.
- **Ask first:**
  - Adding hooks, commands, agents or MCP servers.
  - Adding any dependency.
  - Changing names.
  - Filling in `repository`/`homepage`.
  - Making any non-official rule stricter than `info`.
  - Touching the vue-power repo, including its marketplace.
- **Never:**
  - `git commit`, push or tag in this repo. The review command must never run a git write operation in the user's repo either.
  - Have the skill install packages without consent.
  - Copy third-party skill text verbatim.

## Success Criteria

- [x] `claude plugin validate .` and `--strict` pass. *(T21: both pass with no warnings.)*
- [ ] The plugin loads through `--plugin-dir` and through the local marketplace. `react-power-up:react-power-up` and `/react-power-up:review` both appear. *(`--plugin-dir`: verified. `plugin details` lists Skills (2): react-power-up, review, and both show in headless sessions. **Local marketplace install: needs your environment.** It changes user settings, so it wasn't run here.)*
- [x] Trigger evals: the skill fires on every positive prompt and on none of the negatives, including the Vue prompts. *(T19/T21: 12/12. Coexistence with vue-power-up loaded: `tests/coexistence.sh` 9/9.)*
- [x] Write evals: 0 `error`-rule violations, all output passes `tsc --noEmit` in its harness, and every trap produces the safe variant plus an explanation. *(T21: 19/19 at 1.00 after the JSX-011 fix. T20: 19/19 type-check under TS 7 and TS 5.9, with a coverage check and a negative control.)*
- [x] Version evals: no API above the detected React or Next version is used. *(`write-version-react18`/`-react19` 1.00, and both type-check against their own version's types. Next 15/16 gating is covered by the NEXT cases.)*
- [x] Review evals: ≥ 90% recall on seeded `error` rules and 0 `error` false positives on the 3 clean controls (single runs during development; the user's full run is authoritative). *(T21: all 15 plain-language review cases at 1.00, so every seeded rule-id grader matched (100% recall on this pass). The 3 clean controls Approve with no `[error]`.)*
- [ ] `precheck.sh` passes its shell tests. The command evals pass and leave git state unchanged. *(`precheck.test.sh`: all pass. The 6 command scenarios were verified by hand with headless runs, git state hashed before and after (T4/T5). **The formal eval cases need your environment:** the dev sandbox refuses any Bash grant.)*
- [x] SKILL.md is ≤ ~300 lines. Every rule has an id, severity, why, source, example and applies-range, and is listed in `rule-catalog.md`. `check_catalog.py` and `check_links.py` pass. *(194 lines. 156 rules, all with source and example. Both scripts pass, 152 pages.)*
- [x] Every domain in Content coverage has at least one `error` or `warn` rule, and every D7 library has its own reference section. *(All 15 domains. Zustand and Redux Toolkit share `state.md` as separate prefixed rule groups, accepted at Checkpoint B.)*
- [x] `docs/RATIONALE.md` explains every decision (D1–D13, A1–A8) and every rule, linked by id. *(D1–D16 and A1–A16, plus all 156 rules (`check_catalog.py`), eval design and known limitations.)*
- [x] README covers what the plugin does, install, write examples, review usage, the rule overview, evals and limitations, and matches the final behaviour. *(T21, including a real review excerpt and the full-run command.)*
- [x] Nothing is committed. *(`git log`: no commits yet.)*

## Open Questions

1. ~~Marketplace name~~ → `mlsstjnvc` (D14).
2. ~~Author and license~~ → Milos Stojanovic, MIT (D15).
3. ~~git~~ → initialized by Claude, no commits (D16).
4. ~~Current majors~~ → checked on npm 2026-11-24 (A2); React Router is v8, not v7 (D6). Per-API details (Next 15→16, TanStack Router plugin vs CLI, MSW 3, Vitest 5) are verified inside the task that writes those rules.
