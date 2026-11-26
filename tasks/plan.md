# Implementation Plan: react-power-up

> Source of truth: `SPEC.md` (approved v1, with the D6 React Router v8 correction). Task details: `tasks/todo.md`.
> No commits at any point (D16). All work stays in the working tree.

## Overview

Build the `react-power-up` Claude Code plugin:
- **Main skill** `skills/react-power-up`, triggered automatically. It helps Claude write React 19 + TS code across Next.js App Router, React Router, TanStack Router and the D7 libraries, with guardrails and security.
- **Review skill** `skills/review`, invoked only by the user as `/react-power-up:review [commit]`.
- **One shared rule catalog** that both skills use.
- **A `claude plugin eval` suite.**
- **`README.md` and `docs/RATIONALE.md`.**

The work goes in **vertical slices**, the same approach that worked for vue-power-up. Each rule domain lands complete:
- the reference file
- its rule-catalog entries
- its RATIONALE entries
- at least one write eval and one review fixture
- a passing `check_catalog.py`.

So the plugin is usable, and can be tested, after every task.

## Architecture Decisions

Decisions A1–A11 are carried over from vue-power-up, where they were proven. A12–A16 are new for React.

| # | Decision | Rationale (expanded in `docs/RATIONALE.md`) |
|---|---|---|
| A1 | Two skills: `react-power-up` (automatic) and `review` (user-only, `disable-model-invocation: true`). | `skills/` is the recommended layout. User-only invocation stops the review procedure from firing during write tasks. Plain-language "review this" requests go through the main skill. |
| A2 | One rule catalog in `skills/react-power-up/references/`. The review skill reads it through `${CLAUDE_PLUGIN_ROOT}`. | One source of truth, so writing and review can't drift apart. |
| A3 | Progressive disclosure: SKILL.md ≤ ~300 lines, one reference per domain, references loaded only when the task needs them. | Context cost stays proportional to the task. This matters more here than in vue-power-up: 15 domains and 17 reference files against Vue's 10/12. |
| A4 | Rule ids are `REACT-<DOMAIN>-NNN`. Every rule has a severity, an official source and a version range. | Findings are traceable and can be graded by regex. Version gating stops Claude suggesting APIs the project doesn't have. |
| A5 | No `!`-injection of git output that includes user arguments. Claude validates the argument, then runs git itself. | Pre-executed commands run before validation, which is an injection risk, and a failing command aborts the skill. |
| A6 | `allowed-tools` pre-approves only exact read-only git forms. The skill text forbids write flags (`--output`, `-o`). | `allowed-tools` only pre-approves tools; it doesn't restrict them. |
| A7 | Evals are native `claude plugin eval` cases. Produced files are graded with `regex` graders; short final answers with `llm` graders. | Deterministic signals where possible. |
| A8 | Generated code is type-checked in **scratch harnesses** in the scratchpad, never in this repo or inside eval runs. | Eval workspaces start empty, and scaffolds can't `npm install` in time. |
| A9 | The README links to `rule-catalog.md` instead of copying the rule list. | Domain tasks don't have to edit the README, and it still stays accurate. |
| A10 | The git precondition lives in `scripts/precheck.sh`, **ported from vue-power** with only the command name changed, together with its shell tests. It is pre-executed and pre-approved. | Already proven: deterministic, takes no user input, always exits 0. |
| A11 | Review output is a standard code review (D11) with numbered `diff` proposals. Nothing is applied. | Same as vue-power-up D14. |
| A12 | **The project type is detected first, and the result chooses which references load.** The signals:<br>• Next.js App Router: `next` dependency + `app/`<br>• Next.js Pages Router: `next` dependency + `pages/` only, noted only<br>• React Router framework mode: `react-router.config.*` or `@react-router/dev`, noted only<br>• TanStack Router: `@tanstack/react-router` dependency, `routeTree.gen.ts`, or a router plugin in the Vite config<br>• React Router library mode: `react-router` dependency<br>• plain Vite SPA: none of the above. | React projects differ far more than Vue/Nuxt ones. Loading the Next.js server rules into a Vite SPA task wastes context and invites wrong advice. |
| A13 | **The Next.js content is split across two references:** `nextjs.md` (rendering, data, caching) and `nextjs-server.md` (Server Actions, route handlers, proxy, env). | vue-power-up's `nuxt.md` reached 416 lines. A client-component task needs the boundary rules, not the route-handler security rules. |
| A14 | **React Compiler detection decides the memoization advice.**<br>• Compiler on: manual `useMemo`/`useCallback`/`memo` is `info` ("redundant").<br>• Compiler off: memoize only for measured cost or for referential identity.<br>Detection signals: `babel-plugin-react-compiler` in the dependencies, `reactCompiler` in the Next config, or the compiler set up in the Vite or Babel config. | The memoization advice flips depending on the compiler, so a static rule would be wrong for half of all projects. |
| A15 | **Generated route trees and build output are excluded** (`routeTree.gen.ts`, `.react-router/`, `.next/`), both from editing (a rule) and from review (a filter). | They are generated. Findings in them are noise, and edits to them get overwritten. |
| A16 | **The two plugins must coexist.** The main skill's description names React and excludes Vue, and a trigger eval runs with vue-power-up also installed. | The user owns both plugins. Firing both on one prompt would load two conflicting rule sets. |

## Dependency Graph

```
T1 Manifests + layout + LICENSE + README/RATIONALE skeletons
 └─ T2 SKILL.md core (workflow, project-type + version detection) + rule format + catalog + check scripts
     └─ T3 Slice: TypeScript & components
         ├─ T4 Review skill: precheck port + scope resolution          ← highest risk, early
         │   └─ T5 Review procedure + output + first review evals
         ├─ T6 Slice: hooks & effects
         ├─ T7 Slice: JSX & accessibility
         ├─ T8 Slice: React 19 Actions + first version eval (18 vs 19)  ← version gating proven early
         │   └─ T13 Slice: forms (RHF + Zod)
         │       └─ T15 Slice: Next.js server (Actions, route handlers, proxy, env)
         ├─ T9  Slice: state (Zustand + RTK)
         ├─ T10 Slice: TanStack Query
         │   ├─ T12 Slice: TanStack Router (Query integration)
         │   └─ T14 Slice: Next.js rendering, data, caching (Query SSR hydration)
         ├─ T11 Slice: React Router v8
         ├─ T16 Slice: security (cross-cutting; needs the T11–T15 rules to reference) + trap evals
         ├─ T17 Slice: performance (React Compiler-aware)
         └─ T18 Slice: testing (Vitest 5, RTL, user-event, MSW 3)
                └─ T19 Trigger evals + coexistence with vue-power-up + description tuning
                    └─ T20 Type-check harnesses (Vite+TSR+Query, Vite+RR, Next 16) over write outputs
                        └─ T21 Single-run pass over all cases, gap fixes, README/RATIONALE finalization
```

T6, T7, T9, T10, T11, T17 and T18 depend only on T3–T5 and could run in parallel. They run **sequentially** because each one edits `rule-catalog.md`, `RATIONALE.md` and SKILL.md's red-flag list, and parallel edits would conflict (the same reasoning as vue-power-up).

## Task List

### Phase 1: Foundation and riskiest path
- [x] T1: Manifests, layout, LICENSE, doc skeletons
- [x] T2: Main SKILL.md core, rule format, catalog and check scripts
- [x] T3: Slice: TypeScript and components
- [x] T4: Review skill: precheck port and scope resolution
- [x] T5: Review procedure, standard-review output, first review evals

### Checkpoint A (after T1–T5)
- [x] `claude plugin validate . --strict` passes
- [x] The plugin loads via `--plugin-dir`, and both skills appear
- [x] The `precheck.sh` shell tests pass
- [x] `/react-power-up:review` is verified in a scratch repo:
  - it stops correctly without git and outside a repo
  - it reviews uncommitted changes and a commit hash
  - git state is unchanged afterwards
- [x] `check_catalog.py` and `check_links.py` pass
- [x] Human review before continuing *(waived: the user asked on 2026-11-24 to continue through the tasks without asking unless there's a concern; none arose at A)*

### Phase 2: Core React
- [x] T6: Hooks and effects
- [x] T7: JSX and accessibility
- [x] T8: React 19 Actions and the first version eval

### Checkpoint B (after T6–T8)
- [x] All eval cases so far pass with `--runs 1 --ablation none` *(9/9, after the data-fetching fix in workflow step 4; see todo.md)*
- [x] The version eval passes (no React 19 API in the React 18 fixture)
- [x] SKILL.md ≤ ~300 lines (170)
- [x] Human review *(waived per the user's 2026-11-24 instruction; no open concerns)*

### Phase 3: Ecosystem libraries and routing
- [x] T9: State: Zustand and Redux Toolkit
- [x] T10: TanStack Query
- [x] T11: React Router v8
- [x] T12: TanStack Router
- [x] T13: Forms: React Hook Form and Zod

### Checkpoint C (after T9–T13)
- [x] All eval cases pass at `--runs 1` *(21/21 non-Bash cases at 1.00, 2026-11-24; the run was split in two by a usage-limit interruption, and only the interrupted cases were re-run)*
- [x] Every D7 library has its reference section, at least one `error`/`warn` rule, and at least one eval *(TanStack Query, Zustand, Redux Toolkit, React Hook Form + Zod; the testing libraries land in T18)*
- [x] Human review *(waived per the user's 2026-11-24 instruction; no open concerns)*

### Phase 4: Next.js and cross-cutting concerns
- [x] T14: Next.js rendering, data and caching
- [x] T15: Next.js server: Server Actions, route handlers, proxy, env
- [x] T16: Security and trap evals
- [x] T17: Performance
- [x] T18: Testing

### Checkpoint D (after T14–T18)
- [x] All eval cases pass at `--runs 1`
- [x] Every rule has an id, severity, source, example, applies-range, a catalog entry and a RATIONALE entry
- [x] All 15 domains have at least one `error` or `warn` rule
- [x] Human review (user approved continuing to T19, 2026-11-25)

### Phase 5: Verification and polish
- [x] T19: Trigger evals, coexistence with vue-power-up, description tuning
- [x] T20: Type-check harnesses over generated code
- [x] T21: Single-run pass over all cases, gap fixes, docs finalization (the full run is the user's, D12)

### Checkpoint: Complete
- [x] Every Success Criterion in SPEC.md is checked off with evidence *(2 deferred to your environment: local-marketplace install, formal command evals)*
- [x] `claude plugin validate . --strict` passes
- [x] Nothing is committed (`git log` shows no commits)
- [x] Human sign-off (2026-11-26)

## Risks and Mitigations

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| R1 | **The eval sandbox can't grant Bash.** This happened in vue-power-up: all 6 review-command evals failed only because of it. | Med: the formal command evals can't pass during development | Same as vue-power-up: verify each command scenario by hand with headless runs in scratch repos and record the evidence in `todo.md`. The user's full run with `--allow-tools Bash` is authoritative. Confirm in T4 whether this has changed. |
| R2 | `allowed-tools` grants also pre-approve write-capable flags. | Med | Grant only the narrowest patterns. The skill forbids `--output`/`-o`. An eval asserts no file is created and git state is unchanged. |
| R3 | **Several dependencies released new majors recently:**<br>• React Router 8<br>• MSW 3 (2026-09)<br>• TypeScript 7 (2026-07)<br>• Vitest 5<br>• Next 16.x Cache Components<br>Rules could teach stale or wrong APIs. | **High** | Every `error`/`warn` rule cites an official doc URL **checked during its task**. Tasks T11, T14, T15 and T18 start with a docs-verification step and record what they confirmed. Version ranges go on every rule. Anything unconfirmed is written as a note, not a rule. |
| R4 | **The rule set is bigger than vue-power-up's** (15 domains, about 100–130 rules). This risks a bloated SKILL.md, slower triggering, and false positives. | Med | Keep SKILL.md to the red flags plus pointers only, and check the line count at each checkpoint. Use 3 clean controls with 0 `error` findings required. Opinions are capped at `info`. |
| R5 | **Mis-triggering:**<br>• on Vue prompts, while vue-power-up is installed<br>• on React Native<br>• never firing for "JS + JSX" projects that don't mention React | Med | A16. Trigger evals include Vue, React Native and "add a component to this `.tsx` file" prompts. Description tuning happens in T19. |
| R6 | **Wrong project-type detection** in hybrid repos, e.g. a monorepo with both Next and Vite apps, or TanStack Router added to an RR app mid-migration. | Med | Detection is scoped to the nearest `package.json` above the target file, and the result is stated in the plan step. In a genuinely ambiguous case Claude asks. One eval uses a monorepo fixture. |
| R7 | **The Next.js 16 harness is heavy** (install size, Turbopack) and may not install in the scratchpad. | Low | One-time setup in T20. Fallback: `tsc --noEmit` with `next` types only, or a static review of the outputs, and report which one was used. |
| R8 | **Eval cost**: about 45 cases × 3 runs × 2 arms. | Low | During development, only targeted cases with `--runs 1 --ablation none`. The full run is the user's (D12). |
| R9 | **TypeScript 7 behaviour changes** (strict by default, `types: []` by default) could make harness type-checks differ from the user's TS 5 projects. | Low | The harnesses pin TS 7 (current) and one TS 5.x harness runs as a control in T20. Rules don't depend on TS-version-specific features unless gated. |
| R10 | The precheck needs a POSIX shell (Git Bash on Windows). | Low | Documented in the README, as in vue-power-up. |

## Open Questions

None blocking. Each docs-verification item is assigned to the task that writes the rules:
- TanStack Router plugin vs CLI (T12)
- Next 15→16 per-API deltas (T14/T15)
- MSW 3 entrypoints and Vitest 5 config (T18)
