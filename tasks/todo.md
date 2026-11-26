# Tasks: react-power-up

> Plan: `tasks/plan.md` · Spec: `SPEC.md` · No commits (D16).
>
> **Definition of done for every domain slice (T3, T6–T18):**
> 1. Rules are in the reference file, each with id, severity, Why, Source (checked during the task), ❌/✅ TSX, Applies, Exceptions.
> 2. Each rule has a `rule-catalog.md` row and a `docs/RATIONALE.md` entry.
> 3. SKILL.md has only the red-flag line(s) and the pointer to the reference.
> 4. The slice has ≥ 1 write eval and ≥ 1 review fixture covering its `error` rules.
> 5. `check_catalog.py` and `check_links.py` pass.
> 6. The new cases pass with `claude plugin eval . --scaffold --runs 1 --ablation none`.
> 7. The evidence is noted under the task.

## Phase 1: Foundation and riskiest path

### T1: Manifests, layout, LICENSE, doc skeletons
**Description:** Create the plugin skeleton so it validates and loads:
- `.claude-plugin/plugin.json`: name `react-power-up`, version `0.1.0`, description, author Milos Stojanovic, license MIT, keywords
- `.claude-plugin/marketplace.json`: `mlsstjnvc`, owner Milos Stojanovic, source `./`
- the `LICENSE` file (MIT)
- `.gitignore` (with `evals/results/`)
- empty skill dirs
- README and RATIONALE skeletons with D1–D16 and A1–A16 headings.

**Acceptance:**
- [x] `claude plugin validate .` and `--strict` pass with no warnings.
- [x] `claude --plugin-dir ~/projects/react-power-up` starts, and the plugin is listed.
- [x] RATIONALE has a stub for every D and A id.

**Verify:** `claude plugin validate . --strict`; `claude --plugin-dir . plugin details react-power-up`.
**Dependencies:** none · **Files:** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `LICENSE`, `.gitignore`, `README.md`, `docs/RATIONALE.md` (6 files: all trivial scaffolding, so the size is fine) · **Scope:** S

**Done (2026-11-24).**
- `validate` and `validate --strict`: exit 0, no manifest warnings. The separate plugin-directory check warns `ICON_MISSING` (informational; an icon needs to come from the user).
- `claude --plugin-dir . plugin details react-power-up`: `react-power-up 0.1.0`, 0 components, ~0 always-on tokens.
- RATIONALE: D1–D16 written out, A1–A16 stubbed with their owning tasks.
- Correction: `plugin details` has no `--plugin-dir` option of its own. The global flag goes before the subcommand. Fixed in the SPEC Commands section and the README.
- Skill and eval dirs created; they stay empty and untracked until T2.

### T2: Main SKILL.md core, rule format, catalog and check scripts
**Description:** Write `skills/react-power-up/SKILL.md`:
- frontmatter, with a description that names React and excludes Vue and React Native (A16)
- the 8-step write workflow
- the project-type detection table (A12)
- version detection from `node_modules`, then the lockfile, then `package.json`
- React Compiler detection (A14)
- the guardrail-conflict policy
- the security checklist skeleton
- the self-check
- the reference index.

Create the `rule-catalog.md` skeleton. Port `tests/check_catalog.py` and `tests/check_links.py` from vue-power, changing the id prefix to `REACT-` and using the 15 domains.

**Acceptance:**
- [x] SKILL.md ≤ 150 lines at this stage, which leaves room for the red flags.
- [x] The catalog format matches the rule shape in SPEC Code Style.
- [x] `check_catalog.py` passes on the empty catalog and fails on a deliberately broken fixture row (tested once, then removed).

**Verify:** `wc -l skills/react-power-up/SKILL.md`; `python3 tests/check_catalog.py`; `python3 tests/check_links.py`.
**Dependencies:** T1 · **Files:** `skills/react-power-up/SKILL.md`, `references/rule-catalog.md`, `tests/check_catalog.py`, `tests/check_links.py` · **Scope:** M

**Done (2026-11-24).**
- **SKILL.md: 146 lines.** The first draft was 162; it was tightened without dropping content. Description 464 chars. `plugin details`: ~195 always-on tokens, ~3.5k on invoke.
- **Contents:** the 8-step workflow, version detection (with a cross-cutting minimum-version table), project-type table (A12), React Compiler table (A14), conflict policy, security-pass sinks (no rule ids yet; added in T16), process-level red flags, and a reference index that lists only files that exist (A3).
- **rule-catalog.md:** 15 domains with their reference files, the severity model, the list of what counts as an official source, the rule template (TSX), and the generated-index marker.
- **check_catalog.py:** ported, plus a new unknown-domain check. On the empty catalog: OK (0 rules). On a throwaway fixture it reported 10 problems and exited 1:
  - an unknown domain
  - a missing Source
  - a missing Applies
  - a missing Exceptions
  - a malformed heading
  - rules missing from the index
  - an orphan index row
  - missing RATIONALE entries.

  The fixture and the extra row were removed afterwards.
- **check_links.py:** ported. OK (0 sources).
- **RATIONALE:** A1, A2, A3, A4, A9, A12, A14 and A16 written, and §4 Rule system written. **README:** Rules and Development sections.
- `validate --strict` ✓. No commits.

### T3: Slice: TypeScript and components
**Description:** Write `references/typescript.md` (`TS`) and `references/components.md` (`COMP`). Cover:
- typed props and children
- event types
- `useRef` typing
- context with a guard hook
- discriminated-union props
- components defined inside components
- context value splitting and memoization
- controlled vs uncontrolled inputs
- error boundaries and Suspense
- `forwardRef` (18) vs ref as a prop (19), version-gated.

Add the first write eval (`write-component-context`) and the first review fixture.

**Acceptance:**
- [x] The slice DoD (1–7) is met. *(Item 6: the review case's verdict grader is deferred to T5; see below.)*
- [x] The ref rule shows both versions with the correct Applies ranges.

**Verify:** DoD commands, run on the 2 new cases.
**Dependencies:** T2 · **Files:** `references/typescript.md`, `references/components.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-component-context/`, `evals/review-components/` · **Scope:** M

**Done (2026-11-24).**
- **Rules:** 21 in total.
  - **TS (10):** 7 `warn`, 3 `info`.
  - **COMP (11):** 5 `error`, 4 `warn`, 1 `info`, plus COMP-008, an `error` that applies to React 18 only.
  - The version pair is COMP-007 (19: ref as a prop) and COMP-008 (18: `forwardRef`).
  - COMP-011 covers `defaultProps`, which React 19 silently ignores.
- **Sources:** all 24 cited pages resolve, and every `#anchor` exists (scratch anchor check). Two anchors were wrong in the first draft and were fixed:
  - react.dev/learn/typescript has no `#typing-component-props` (now `#typescript-with-react-components`)
  - and no `#useref` (now the `useRef` reference page).
- **Examples:** every ✅ example compiles in the scratch harness (TS 7.0.2, `strict`):
  - the React 19 examples against React 19 types, exit 0
  - the React 18-only ones (COMP-008, and TS-005 on 18) against React 18 types, exit 0.

  A negative control confirmed TS-005's claim: React 19 types reject `useRef<number>()` with TS2554.
- **SKILL.md:** 151 lines. Added red flags for TS-002, COMP-001/002/003 and COMP-008/011, an error-boundary exception to the class-component red flag (an error boundary still requires a class), and 2 reference rows.
- `check_catalog.py`: OK, 21 rules. `validate --strict` ✓.
- **Evals** (`--runs 1 --ablation none`):
  - `write-component-context`: **1.00**, all 8 graders. The generated code (rebuilt from the trace) also type-checks against React 19 types, exit 0. It uses ref as a prop, `ComponentProps<'input'>`, `useId` labels and a memoized provider value.
  - `review-components`: **0.88**. All 4 seeded ids were found, there were no Write or Edit calls, and the skill fired. ✗ `verdict-request-changes`: the verdict wording comes from `references/review.md`, which T5 adds. The grader is kept, and T5 must make it pass.
- **CLI notes** (recorded in the README):
  - Repeating `--case` keeps only the last one.
  - `plugin eval` publishes the report to claude.ai unless `--no-publish` is given, so every run here uses `--no-publish`.

### T4: Review skill: precheck port and scope resolution
**Description:**
- Port `skills/review/scripts/precheck.sh` and `tests/precheck.test.sh` from vue-power, changing only the command name in the messages.
- Write `skills/review/SKILL.md` with:
  - `disable-model-invocation: true`
  - narrow `allowed-tools`
  - precheck injection and its fallback
  - hash validation `^[0-9a-fA-F]{4,40}$`
  - the scope table (uncommitted changes vs commit, merge commits against the first parent, the root commit against the empty tree)
  - the React file filter, including the generated-file exclusions (A15).
- **First, check R1:** can an eval run with Bash granted in this environment?

**Acceptance:**
- [x] `precheck.test.sh` passes for all 3 statuses.
- [x] Headless runs in scratch repos produce the correct scope, with git state unchanged, for:
  - uncommitted changes (staged, unstaged and untracked)
  - a hash
  - a root commit
  - an invalid argument
  - an option-like argument (`--output=x`)
  - a clean tree
  - a directory that isn't a repo.
- [x] The R1 result is recorded here.

**Verify:** `sh tests/precheck.test.sh`; for each scenario, compare `git status --porcelain` and `git rev-parse HEAD` before and after.
**Dependencies:** T3 · **Files:** `skills/review/SKILL.md`, `skills/review/scripts/precheck.sh`, `tests/precheck.test.sh`, `evals/review-precheck-*`, `evals/review-invalid-arg/` · **Scope:** M

**Done (2026-11-24).**
- **Ported:** `precheck.sh` (header comment only) and `precheck.test.sh` (unchanged): 9/9 assertions ok.
- **Review SKILL.md, adapted from vue-power:**
  - the React file filter: route dirs, `next.config.*`/`proxy.*`/`middleware.*`, `.env.example`
  - generated and build exclusions (A15)
  - **never read real `.env*`**
  - project-type and compiler context read as of the reviewed state
  - server code first in large diffs.

  `plugin details`: 2 skills, `react-power-up` and `review`. `validate --strict` ✓.
- **R1: still applies, for a different reason than in vue-power-up.** `claude plugin eval … --allow-tools Bash` refuses every Bash-granting case before it runs ($0.00): *"a credentials file in this environment … could not be followed (EACCES), so the Bash sandbox cannot exclude the files it points at."* The cases `review-precheck-no-repo` and `review-invalid-arg` are written in the native format, for the user's run.
- **Headless verification instead** (`claude -p "<cmd>" --plugin-dir ~/projects/react-power-up`, scratch repo with deterministic commits `5b5d937` root → `cab60c5`). Git state is a hash of HEAD, `status --porcelain`, the stash list and every file's checksum, taken before and after each run:

  | Scenario | Result | Git state |
  |---|---|---|
  | clean tree | `Nothing to review: the working tree has no uncommitted changes.` | unchanged |
  | `--output=pwned.txt` | `Invalid argument "--output=pwned.txt": …`, and no `pwned.txt` created | unchanged |
  | `main` (branch name) | `Invalid argument "main": …` | unchanged |
  | `deadbeef` (unknown hash) | `Commit "deadbeef" was not found or is ambiguous in this repository.` | unchanged |
  | `cab60c5` | scope `cab60c5` "Add counter"; found REACT-COMP-011 (`defaultProps`) | unchanged |
  | `5b5d937` (root commit) | scope "root commit, so every file is new"; no false positives on the clean list component | unchanged |
  | uncommitted (staged `Tag.tsx` + unstaged `types.ts` + untracked `Note.tsx`) | scope lists all 3, with their kinds; found COMP-001 and COMP-002 | unchanged |
  | not a repo | exact `must run inside a git repository; <cwd> isn't one.` | n/a |

  `NO_GIT_BINARY` is covered by the shell tests only, the same as in vue-power-up. Replacing PATH for a headless `claude` run would also hide the `claude` binary.
- **Expected gap, closed by T5:** each review noted that `references/review.md` doesn't exist yet and used an ad-hoc layout. The catalog's domain table also names reference files that later tasks add, and the model noticed that too. Once all domains have landed (T18), every listed file will exist.

### T5: Review procedure, standard-review output, first review evals
**Description:** Write `references/review.md`:
- the procedure
- the severity model and verdict rules
- the finding format `[severity] REACT-ID file:line — title`
- numbered `diff` proposals
- "what's done well"
- the next-step line
- the rule that pre-existing issues in untouched code are reported only for `error`-level security problems.

Add command eval cases (`review-clean-tree`, `review-commit-hash`, `review-root-commit`, `review-uncommitted`) and the first clean control.

**Acceptance:**
- [x] The T3 fixture review returns *Request changes*, with the seeded rule ids and numbered `diff` blocks.
- [x] The clean control returns no `[error]`.
- [x] The no-edit and no-write graders pass.

**Verify:** `claude plugin eval . --scaffold --runs 1 --ablation none` on the review cases. If R1 still applies, run the command cases headless by hand and record them.
**Dependencies:** T4 · **Files:** `references/review.md`, `evals/review-*` (4–5 case dirs) · **Scope:** M

**Done (2026-11-24).**
- **`references/review.md`:** an 8-step procedure, with a domain → reference map, React-specific calibration (Applies range, compiler) and a `GENERAL` label.
  - verdict table
  - output format with a **Context** line (React, project type, TS, compiler)
  - optional Libraries, Skipped and Pre-existing parts
  - format rules, including "never quote secret values".
- **SKILL.md:** a *Reviewing code* section and a reference row. 156 lines.
- **Command cases** (generated by a scratch script, `scaffold.sh` reproducing `5b5d937` → `cab60c5`): `review-clean-tree`, `review-commit-hash`, `review-root-commit`, `review-uncommitted`.
- **Verification:**
  - **Plain-language cases, via `plugin eval --tag plain --runs 1 --ablation none`:**
    - `review-components`: **1.00** (the T3 verdict gap is closed)
    - `review-clean-control-components`: **1.00** (Approve, no `[error]`; the control type-checks in the React 19 harness).
  - **Command cases, headless** (R1: the eval sandbox can't grant Bash here). Each output was graded with the case's own regex graders, and git state was hashed before and after:

    | Case | Graders | Git state |
    |---|---|---|
    | `review-clean-tree` | 2/2 | unchanged |
    | `review-commit-hash` | 4/4 | unchanged |
    | `review-root-commit` | 3/3 | unchanged |
    | `review-uncommitted` | 6/6 | unchanged |

    The uncommitted review followed the format exactly: Scope listing staged, modified and untracked files; Context; 2 errors + 1 warn + 1 `GENERAL` info; 3 valid `diff` proposals; the apply line.
  - The `tool_used` safety graders can't be checked from text output. They run in the user's `--allow-tools Bash` run.

### ✅ Checkpoint A
See `plan.md`. **Stop for human review.**

## Phase 2: Core React

### T6: Hooks and effects
**Description:** Write `references/hooks.md` (`HOOK`) and `references/effects.md` (`EFF`).
- **Hooks:**
  - the Rules of Hooks
  - exhaustive dependencies, with no suppression
  - unstable dependencies
  - stale closures
  - lazy initializers and the updater form
  - no state mutation
  - `use*` naming
  - `useSyncExternalStore` for external stores.
- **Effects:** everything from react.dev's "You Might Not Need an Effect":
  - derived state
  - event logic
  - prop→state syncing
  - resetting state with `key`
  - effect chains
  - fetch race and cleanup
  - StrictMode double-invoke awareness.

Add a trap write eval ("fetch this in a useEffect and store it in state") and a review fixture seeded with 3 `EFF`/`HOOK` errors.

**Acceptance:**
- [x] The slice DoD is met.
- [x] On the trap, Claude uses the project's data layer (Query, a loader or RSC) when one exists, or else a cleaned-up effect with race handling, and explains the deviation.

**Verify:** DoD commands.
**Dependencies:** T5 · **Files:** `references/hooks.md`, `references/effects.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-trap-effect-fetch/`, `evals/review-hooks-effects/` · **Scope:** M

**Done (2026-11-24).**
- **Rules:** 19 in total.
  - **HOOK (11):** 4 `error` (001, 002, 003, 006), 7 `warn`. Includes `useEffectEvent`, gated to React ≥ 19.2: stable since 19.2 (react.dev blog 2025-10-01), and exported by `@types/react` 19.3.0.
  - **EFF (8):** 4 `error` (001, 002, 005, 006), 4 `warn`. Follows "You Might Not Need an Effect"; the reference file opens with the decision questions.
- **Sources:** every page and anchor resolves (anchor check: 0 misses). `check_links.py`: all pages OK.
- **Examples:** every ✅ example compiles against React 19.3 types (TS 7.0.2, strict), exit 0.
- **SKILL.md:** 162 lines. Added 3 red-flag lines (HOOK-001/002/003, EFF-001/002/005/006), a React 19.2 row (`useEffectEvent`, `<Activity>`) and 2 reference rows.
- `check_catalog.py`: 40 rules OK.
- **Evals** (`--runs 1 --ablation none`):
  - `write-trap-effect-fetch`: **1.00**. It used `useQuery` with the search text in the key, passed the `signal`, and set `enabled` for empty input. It explained the deviation from the literal `useEffect` request. Rebuilt from the trace, the output type-checks against React 19 types + TanStack Query 5, exit 0.
  - `review-hooks-effects`: **1.00**. All 4 seeded ids found (HOOK-001, HOOK-003, EFF-001, EFF-006), Request changes, no Write or Edit.

### T7: JSX and accessibility
**Description:** Write `references/jsx.md` (`JSX`):
- keys, and index keys on reorderable lists
- `0 &&` rendering
- conditional rendering
- event handler naming
- heavy inline logic
- a11y: semantic interactive elements, labels, `alt`, keyboard support. These are sourced from the jsx-a11y rule docs, WAI-ARIA APG and react.dev.

**Acceptance:**
- [x] The slice DoD is met.
- [x] The a11y rules that no official source backs are capped at `info`. *(Every a11y rule here has a WCAG, APG or jsx-a11y source; JSX-010, readability only, is `info`.)*

**Verify:** DoD commands.
**Dependencies:** T5 · **Files:** `references/jsx.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-list-filter/`, `evals/review-jsx-a11y/` · **Scope:** M

**Done (2026-11-24).**
- **Rules: JSX (10).** 5 `error` (001 keys, 002 `0 &&`, 003 clickable div, 004 labels, 007 handler called), 4 `warn`, 1 `info`.
- **Sources:** react.dev, WCAG 2.2 Understanding, the APG and the jsx-a11y docs. The **HTML Living Standard** was added to the official-source list (for `button` `type`). The scratch anchor checker now also accepts unquoted and single-quoted ids, which the WHATWG spec uses. 0 misses.
- **Examples:** the ✅ examples compile against React 19 types, exit 0.
- **SKILL.md:** 165 lines. 2 red-flag lines (JSX-001/002/007, JSX-003/004) and 1 reference row.
- `check_catalog.py`: 50 rules OK. `check_links.py` OK.
- **Evals:**
  - `write-list-filter`: **1.00**. Keys by id, no clickable divs, no `.length &&`, `aria-expanded`, labelled controls; the output type-checks against React 19 types, exit 0.
  - `review-jsx-a11y`: **1.00**. All 5 seeded ids found, Request changes.
- **Grader fix:** the first `write-list-filter` graders were written through shell `printf` and got doubled backslashes; one also failed to parse. They were rewritten from Python, and a scan found no other doubled-backslash patterns in the suite. Grader files are now always written from Python or a quoted heredoc.

### T8: React 19 Actions and the first version eval
**Description:** Write `references/actions.md` (`ACT`):
- `useActionState`
- `useOptimistic` with rollback
- `useFormStatus` (only inside a `<form>` child)
- `<form action>`
- transitions
- React 18 fallbacks.

Add the version eval pair: the same prompt (a form with pending state plus a ref-forwarding input) against a React 18.3 and a React 19 `package.json`. The 18 output must contain no `useActionState`, `use(` or ref-as-prop; the 19 output must not use `forwardRef`.

**Acceptance:**
- [x] The slice DoD is met.
- [x] Both version cases pass at `--runs 3` (version gating is high risk, so a single run isn't enough here).

**Verify:** `claude plugin eval . --runs 3 --ablation none` on `write-version-react18` and `write-version-react19`.
**Dependencies:** T5 · **Files:** `references/actions.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-version-react18/`, `evals/write-version-react19/` · **Scope:** M

**Done (2026-11-24).**
- **Rules: ACT (7).** 4 `error` (002 arg order, 003 `useFormStatus` placement, 004 optimistic outside a transition, 005 React 18 has no Actions), 3 `warn`.
- **Sources:** react.dev reference pages and the React 19 blog. 0 anchor misses.
- **Examples:** the ✅ examples compile against React 19.3 types, and the ACT-005 fallback against React 18 types. Negative control: React 18 types have no `useActionState` (TS2305).
- **SKILL.md:** 2 red-flag lines and 1 reference row.
- `check_catalog.py`: 57 rules OK.
- **Version evals (`--runs 3`):**
  - `write-version-react18`: **3/3 at 1.00**. Uses `forwardRef` and `onSubmit` with manual pending state, and no React 19 APIs.
  - `write-version-react19`: **3/3 at 1.00**, after a grader fix (below). No `forwardRef`; uses Actions hooks.
  - One output from each, rebuilt from the trace, type-checks against its own version's types (React 18 harness / React 19 harness), exit 0.
- **Grader fix (not a skill change):** the first React 19 run scored 0.87, because 2 of 3 outputs had a *comment* saying "no forwardRef is needed". The `forwardRef` and React 19-API graders now match imports and calls (`import … forwardRef`, `forwardRef(`/`forwardRef<`), not mentions. Applied to the 5 graders that used a bare-word pattern. vue-power-up needed the same fix for comment lines.

### ✅ Checkpoint B
See `plan.md`. **Stop for human review.**

**Status (2026-11-24): closed** (the status notes below were written while it was blocked).
- **The red-flag fix alone gave only 2/3** on `write-trap-effect-fetch`, since one run still followed the literal request.
- **Second fix:** workflow step 4 now has a **data-fetching bullet**: use the project's data layer even when the request says `useEffect`, treat that as a guardrail conflict, and read `effects.md` before writing any `useEffect`. With that, `write-trap-effect-fetch` passed **3/3 at 1.00**.
- **Full pass (`--tag plain write --runs 1`): 9/9 at 1.00.** SKILL.md: 170 lines.

**Notes written while blocked:**
- **Full pass of write + plain cases (`--tag plain write --runs 1`):** 8/9 at 1.00. **`write-trap-effect-fetch` regressed to 0.33**, and to 0.39 over 3 runs.
- **Root cause:** in those runs Claude never opened `effects.md`, and followed the literal request (a `useEffect` fetch). The SKILL.md red flag added in T6 read "`useEffect` to … fetch without race handling", which implies a race-handled fetch effect is fine even when TanStack Query is installed.
- **Fix applied:** the red flag is split. The first line now says "Fetching in `useEffect` when the project has TanStack Query, a router loader or Server Components: use those, even if the request says `useEffect`, and explain why. Without a data layer, a fetch effect needs race handling (REACT-EFF-005)". SKILL.md: 169 lines.
- **Not yet verified:** the re-run hit the account's 5-hour usage limit (`You've hit your 5-hour limit · resets 2:10pm (Europe/Belgrade)`).
- **To resume:**
  1. `claude plugin eval . --scaffold --case write-trap-effect-fetch --runs 3 --ablation none --allow-tools Write Edit --no-publish`, which must reach 3/3.
  2. Then re-run `--tag plain write --runs 1` to close Checkpoint B.
  3. Then continue with T9.

## Phase 3: Ecosystem libraries and routing

### T9: State: Zustand and Redux Toolkit
**Description:** Write `references/state.md` (`STATE`):
- the "where does state live" ladder: local → lifted → context → store → URL → server cache
- **Zustand v5:**
  - selectors
  - `useShallow` for selectors that return objects
  - slices
  - no store creation in render
  - SSR store-per-request in Next
- **Redux Toolkit v2:**
  - `createSlice`
  - typed `useAppSelector`/`useAppDispatch` (`.withTypes`)
  - serializable state
  - RTK Query basics, with a pointer to prefer TanStack Query when it's already present.

**Acceptance:**
- [x] The slice DoD is met.
- [x] Separate Zustand and RTK write evals both pass.
- [x] The APIs were verified against the current Zustand and RTK docs, and the URLs are recorded.

**Verify:** DoD commands.
**Dependencies:** T5 · **Files:** `references/state.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-zustand-store/`, `evals/write-rtk-slice/`, `evals/review-state/` · **Scope:** M

**Done (2026-11-24).**
- **Rules: STATE (10).** 3 `error` (004 Zustand v5 object selector without `useShallow`, 006 module-scope store under SSR, 009 non-serializable Redux state), 7 `warn`. The file opens with the "where state lives" ladder.
- **Sources:** react.dev, the Redux style guide, RTK, the Redux Next.js guide, Zustand, and TanStack Query. **Zustand's docs moved** to `/learn/…` and `/reference/…`; the old `/docs/guides/…` paths return 404, so the new paths are used. The v5 infinite-loop claim was checked against the v5 migration guide (*Requiring stable selector outputs*). 0 anchor misses.
- **Examples:** the ✅ examples compile with Zustand 5.1.0, RTK 2.15.0 and React Redux 9.3.1 against React 19 types, exit 0.
- **SKILL.md:** 172 lines. 1 red-flag line and 1 reference row.
- `check_catalog.py`: 67 rules OK.
- **Evals (`--runs 1`):** all three at **1.00**.
  - `write-zustand-store`: curried `create`, a derived total, selectors with `useShallow`. The output type-checks against React 19 + Zustand 5, exit 0.
  - `write-rtk-slice`, a Next.js App Router app: `createSlice`, `.withTypes` hooks, no `Date` in state, a `makeStore` factory. Its type-check is deferred to the T20 Next harness.
  - `review-state`: STATE-004, -006 and -009 all found; Request changes.

### T10: TanStack Query
**Description:** Write `references/tanstack-query.md` (`QUERY`):
- query key factories and `queryOptions`
- params included in the key
- `staleTime`
- invalidation after mutations
- optimistic updates with rollback
- `enabled` for dependent queries
- no `onSuccess` on queries (v5)
- no copying data into state
- `QueryClient` lifetime: never in render; one per request on the server
- Suspense queries
- SSR prefetch with `HydrationBoundary` (the Next-specific part is finished in T14).

**Acceptance:**
- [x] The slice DoD is met.
- [x] The review fixture includes the v5-removed `onSuccess` and a `QueryClient` created in render, and both are found.

**Verify:** DoD commands.
**Dependencies:** T5 · **Files:** `references/tanstack-query.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-query-list/`, `evals/review-query-misuse/` · **Scope:** M

**Done (2026-11-24).**
- **Rules: QUERY (11).** 5 `error` (001 key misses params, 003 client lifetime, 005 v5 callbacks, 006 no invalidation, 007 optimistic without rollback), 5 `warn`, 1 `info`.
- **Sources:** the official TanStack Query v5 guides. 0 anchor misses.
- **Examples:** the ✅ examples compile against TanStack Query 5 + React 19 types, exit 0. Negative control: v5 rejects `onSuccess` on `useQuery` (TS2769).
- **SKILL.md:** 174 lines. 1 red-flag line and 1 reference row.
- `check_catalog.py`: 78 rules OK.
- **Evals:**
  - `write-query-list`: **1.00**. Params in the key, invalidation on cancel, no v4 callbacks, no `cacheTime`, `queryOptions`. The output type-checks, exit 0.
  - `review-query-misuse`: **1.00**. QUERY-001, -003, -005 and -006 all found; Request changes.

### T11: React Router v8
**Description:** **Start by checking the official v8 docs and the v7 upgrade guide**, and record what was confirmed. Then write `references/react-router.md` (`RR`):
- data mode: `createBrowserRouter`, loaders, actions, `ErrorBoundary`/`errorElement`, lazy routes
- declarative mode
- imports from `react-router` and `react-router/dom` (v8)
- validated `params`
- `useSearchParams` for URL state
- `<Link>` instead of `<a>` for internal navigation
- no `navigate()` during render
- safe `?redirect=` handling
- v7 notes for React 18 projects
- framework mode: detected and noted only.

**Acceptance:**
- [x] The slice DoD is met.
- [x] Every v8-specific claim links to reactrouter.com.
- [x] A React 18 fixture doesn't get v8-only advice.

**Verify:** DoD commands.
**Dependencies:** T5 · **Files:** `references/react-router.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-rr-loader-page/`, `evals/review-rr-misuse/` · **Scope:** M

**Done (2026-11-24).**
- **Docs check** (reactrouter.com, latest 8.5.2, and the npm peer dependencies):
  - v8 requires **react/react-dom ≥ 19.2.7** and Node ≥ 22.22
  - it removes `react-router-dom` (`react-router` + `react-router/dom` instead)
  - the v7 future flags become the defaults.

  The SKILL.md table and D6 were corrected from "React 19" to **19.2.7**.
- **Rules: RR (9).** 3 `error` (004 `navigate` during render, 005 open redirect, 007 `react-router-dom` on v8), 5 `warn`, 1 `info`. Framework mode is noted only.
- **Sources:** reactrouter.com and the OWASP redirects cheat sheet. 0 anchor misses.
- **Examples:** compile against `react-router` 8.5.2 + React 19 types, exit 0.
- **SKILL.md:** 176 lines. 1 red-flag line and 1 reference row.
- `check_catalog.py`: 87 rules OK.
- **Evals (`--runs 1`):** all **1.00**.
  - `write-rr-loader-page`: loader, action/`Form`, no effect fetch, no `react-router-dom`, no internal `<a href>`, an error boundary. The output type-checks against React Router 8, exit 0.
  - `review-rr-misuse`: RR-003, -004, -005 and -007 found.
  - **`review-rr-v7-clean`** (second clean control; React 18 + v7 + `react-router-dom` + `forwardRef`): Approve, no `[error]`, and RR-007 / COMP-007 *not* raised. The fixture type-checks against React 18 + `react-router-dom` 7, exit 0.
- **Generator fix:** `case.yaml` descriptions are now JSON-quoted, since a colon broke YAML parsing. Grader patterns now escape `'` as `''` for YAML single-quoted scalars. A scan of the whole suite found no other affected files.

### T12: TanStack Router
**Description:** **Start by checking the current TanStack Router docs**: is the Vite plugin (`@tanstack/router-plugin`) or the CLI generator recommended, and what are the current `validateSearch` and Zod adapter patterns? Then write `references/tanstack-router.md` (`TSR`):
- file-based vs code-based routes
- never hand-edit `routeTree.gen.ts`
- the router type registration
- typed `Link`/`navigate` with `to` and `params`
- `validateSearch`
- `beforeLoad` for auth and redirects
- loaders with `ensureQueryData` (Query integration)
- pending and error components
- `strict: false` only with a reason.

**Acceptance:**
- [x] The slice DoD is met.
- [x] The write eval (a list page with search params and Query) passes.
- [x] The setup claim (plugin vs CLI) is sourced.

**Verify:** DoD commands.
**Dependencies:** T10 · **Files:** `references/tanstack-router.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-tsr-search-list/`, `evals/review-tsr-misuse/` · **Scope:** M

**Done (2026-11-24).**
- **Docs check:**
  - **Setup:** file-based routing on Vite uses `@tanstack/router-plugin` (`tanstackRouter({ target: 'react', autoCodeSplitting: true })`, before `react()`); the CLI is for other bundlers.
  - **Search params:** `validateSearch` takes a Zod schema directly, and the docs recommend `.catch()`.
  - **URLs:** the docs moved from `/router/latest/docs/framework/react/…` (now a 307 redirect) to `/router/latest/docs/…`.
- **Rules: TSR (9).** 1 `error` (004 search params in a loader without `loaderDeps`), 8 `warn`.
- **Sources:** 0 anchor misses.
- **Examples:** type-checked in a scratch project with real file routes, a tree generated by `@tanstack/router-cli`, and router type registration (`@tanstack/react-router` 1.170.46, Zod 4.6.7). **This caught a real error in the draft:** `errorComponent`'s `error` is `unknown` in 1.170, so the TSR-009 example now narrows with `instanceof Error`. After the fix: exit 0.
- **A15 completed** (the generator setup).
- **SKILL.md:** 178 lines. 1 red-flag line and 1 reference row.
- `check_catalog.py`: 96 rules OK.
- **Evals:**
  - `write-tsr-search-list`: **1.00**. `validateSearch`, loaderDeps or a Query key with all params, `$productId` typed links, no `strict: false`, no route-tree edits. Its output type-checks after generating the tree, exit 0. It named the detail route `products_.$productId.tsx`, TanStack Router's un-nesting convention, so the detail page doesn't need an `<Outlet />` in the list. That's a valid choice.
  - `review-tsr-misuse`: **1.00**. TSR-003, -004, -005 and -006 found.
- `tc_gen.sh` (scratch) now runs `tsr generate` before `tsc` for TanStack Router workspaces.

### T13: Forms: React Hook Form and Zod
**Description:** Write `references/forms.md` (`FORM`):
- `zodResolver`
- types from `z.infer` instead of duplicating them
- one schema shared between client and server
- server re-validation is mandatory
- `register` vs `Controller`
- errors linked to inputs with `aria-invalid` and `aria-describedby`
- `useFieldArray`
- no whole-form `watch()`
- integration with React 19 Actions (T8)
- Zod 3 vs 4 notes.

**Acceptance:**
- [x] The slice DoD is met.
- [x] The Zod 4 APIs are verified against zod.dev, and the 3.x differences are noted.

**Verify:** DoD commands.
**Dependencies:** T8 · **Files:** `references/forms.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-rhf-zod-form/`, `evals/review-forms/` · **Scope:** M

**Done (2026-11-24).**
- **Rules: FORM (9).** 3 `error` (002 no server re-validation, 007 index keys in a field array, 008 numbers arriving as strings), 5 `warn`, 1 `info` (009 Zod 4 APIs).
- **Sources:** React Hook Form docs, zod.dev (basics, API, v4 changelog), the OWASP input-validation cheat sheet and WCAG 3.3.1. 0 anchor misses. RHF's own *Handle errors* example uses `aria-invalid` + `role="alert"`, which backs FORM-004.
- **Examples:** compile against RHF 7.92.0, `@hookform/resolvers` 5.9.2 and Zod 4.6.7 with React 19 types, exit 0.
- **SKILL.md:** 180 lines. 1 red-flag line and 1 reference row.
- `check_catalog.py`: 105 rules OK.
- **Evals:**
  - `write-rhf-zod-form`: **1.00**. `zodResolver`, `z.infer`, `field.id` keys, coerced tickets, accessible errors. The output type-checks, exit 0.
  - `review-forms` (Next.js form + Server Action): **1.00**. FORM-002, -005, -007 and -008 found.

### ✅ Checkpoint C
See `plan.md`. **Stop for human review.**

**Closed (2026-11-24).** The full single-run pass of the write and plain-language review cases scored **21/21 at 1.00**. The first attempt hit the account's 5-hour usage limit after 7 cases, and the 14 interrupted cases were re-run after the reset. SKILL.md: 180 lines. 105 rules.

## Phase 4: Next.js and cross-cutting concerns

### T14: Next.js rendering, data and caching
**Description:** **Start by checking the Next 16 docs and the 15→16 upgrade guide**, and record what was confirmed. Then write `references/nextjs.md` (`NEXT`, rendering half):
- server vs client components
- the smallest possible `'use client'` islands
- no browser APIs during server render
- data fetching in RSC
- Cache Components / `"use cache"` and revalidation (16), with the 15 model noted
- Suspense and streaming
- `next/link` and `next/image`
- metadata
- module-scope mutable state on the server
- TanStack Query SSR in the App Router (prefetch, then `HydrationBoundary`)
- Pages Router: detected and noted only.

**Acceptance:**
- [x] The slice DoD is met.
- [x] The write eval "data page with a client island" passes, with no `'use client'` on the page.

**Verify:** DoD commands.
**Dependencies:** T10 · **Files:** `references/nextjs.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-next-data-page/`, `evals/review-next-boundaries/` · **Scope:** M

**Done (2026-11-24).**
- **Docs check** (Next 16.4.6, *Upgrading to Version 16*):
  - sync request APIs removed in 16 (async since 15)
  - `proxy.ts` replaces `middleware.ts` (Node runtime only; Edge stays on `middleware`)
  - `revalidateTag(tag, profile)` and `updateTag`
  - `cacheComponents` replaces `dynamicIO`/`useCache`/PPR
  - `reactCompiler` stable and off by default.

  These were added to the SKILL.md version table (a new Next 15 row; the Next 16 row extended).
- **Rules: NEXT 001–012** (rendering half; server half starts at 101 in T15). 4 `error` (002 non-serializable props, 004 un-awaited request APIs, 005 browser values during render, 006 per-request module state), 8 `warn`.
- **Sources:** nextjs.org docs and the hydration-error page. 0 anchor misses after one transient miss re-checked.
- **Examples:** type-checked in a scratch Next 16.4.6 project with real `app/` files, exit 0.
- **SKILL.md:** 183 lines. 1 red-flag line, 1 reference row, version rows.
- `check_catalog.py`: 117 rules OK.
- **Evals:**
  - `write-next-data-page`: **1.00**. The page stays a server component; it awaits `params`, has a `'use client'` island, `notFound()` and `<Suspense>` for reviews, and doesn't pass `supplierCost` to the client. The output type-checks against Next 16.4.6, exit 0.
  - `review-next-boundaries`: **1.00**. NEXT-001, -004, -005 and -006 found.
  - **T9's deferred check is done:** `write-rtk-slice` (re-run here at 1.00) type-checks against Next 16 + RTK, exit 0.
- **Generator fix:** grader `path:` values are now JSON-quoted, because `[id]` inside a YAML flow mapping was parsed as a sequence.

### T15: Next.js server: Server Actions, route handlers, proxy, env
**Description:** Write `references/nextjs-server.md` (`NEXT`, server half):
- Server Actions are public endpoints: validate with the shared Zod schema and check auth in every action
- route handlers: validation and auth
- `proxy.ts` (16) vs `middleware.ts` (15)
- `redirect()` never inside try/catch
- `server-only` for server modules
- never pass whole records or secrets to client props
- env: no `NEXT_PUBLIC_` on secrets
- the cookies and headers APIs (async per the 16 docs).

**Acceptance:**
- [x] The slice DoD is met.
- [x] The write evals "settings form + Server Action" and "route handler" pass.
- [x] The review fixture's unauthenticated action and leaked secret are both found.

**Verify:** DoD commands.
**Dependencies:** T13, T14 · **Files:** `references/nextjs-server.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-next-server-action/`, `evals/write-next-route-handler/`, `evals/review-next-server-unvalidated/` · **Scope:** M

**Done (2026-11-24).**
- **Docs check** (nextjs.org *Data Security*, *Authentication*, `use server`, `redirect`, `proxy`, env vars, `updateTag`):
  - `redirect` must be outside `try`
  - layout auth checks don't gate child segments
  - `NEXT_PUBLIC_*` values are inlined at build time
  - `proxy.ts` runs on Node only.
- **Rules: NEXT 101–111.** 8 `error` (101 auth, 102 validation, 103 DTOs, 105 `NEXT_PUBLIC` secrets, 106 route handlers, 107 `redirect` in `try`, 109 layout auth, 111 session cookies), 3 `warn`. **A13** is written in RATIONALE.
- **Sources:** 0 anchor misses.
- **Examples:** compile against Next 16.4.6 + Zod 4, exit 0. Negative control: one-argument `revalidateTag` is TS2554 on 16.
- **SKILL.md:** 185 lines. 1 red-flag line and 1 reference row.
- `check_catalog.py`: 128 rules OK.
- **Evals:**
  - `write-next-server-action`: **1.00**. `'use server'`, auth in the action, a schema parse, `redirect` outside `try`, minimal client props.
  - `write-next-route-handler`: **1.00**. Auth, awaited `params`, 401, ownership, minimal JSON. Its first attempt failed in the scaffold (no `app/` dir); fixed and re-run.
  - Both outputs type-check against Next 16, exit 0.
  - `review-next-server-unvalidated`: **1.00**. NEXT-101, -102, -103, -105 and -107 found.
  - The T14 Next cases re-ran at 1.00 under the shared tag.

### T16: Security and trap evals
**Description:** Write `references/security.md` (`SEC`) and complete SKILL.md's security checklist:
- `dangerouslySetInnerHTML` without a sanitizer
- `javascript:` URLs in `href`/`src`
- open redirects (React Router, TanStack Router, Next `redirect`)
- secrets in client bundles
- unvalidated or unauthorized mutations
- SSRF
- cookie flags
- sensitive data in RSC payloads or a hydrated Query cache
- `eval`/`new Function`.

Cross-link the domain-specific rules from T11–T15 instead of duplicating them. Add the trap evals "render user bio HTML" and "API key the client reads".

**Acceptance:**
- [x] The slice DoD is met.
- [x] Both traps produce the safe variant plus an explanation.
- [x] No duplicate rules across `SEC` and `NEXT`/`RR`/`TSR` (`check_catalog.py` gets a duplicate-title check).

**Verify:** DoD commands.
**Dependencies:** T11, T12, T15 · **Files:** `references/security.md`, `SKILL.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-trap-user-html/`, `evals/write-trap-client-secret/`, `evals/review-security/` · **Scope:** M

**Done (2026-11-24).**
- **Rules: SEC (9).** 7 `error` (001 raw HTML, 002 URL schemes, 003 redirects, 004 client secrets, 005 server authorization, 006 SSRF, 007 eval), 2 `warn` (008 `localStorage` tokens, 009 GET mutations and CSRF). Each cross-links its framework-specific rule instead of duplicating it.
- **Sources:** OWASP cheat sheets, react.dev, and the Vite and Next env docs. 0 anchor misses.
- **Examples:** compile in the Next 16 harness (DOMPurify 3 only for the "sanitizer already installed" example), exit 0.
- **SKILL.md security pass:** every sink now names its rule ids, and there's a `security.md` reference row. 188 lines.
- **`check_catalog.py` duplicate-title check:** case- and punctuation-insensitive. It catches a planted "treat props as READ-ONLY." duplicate of COMP-002 (fixture removed afterwards). It passes on the real catalog: 137 rules, no duplicates.
- **Evals:**
  - `write-trap-user-html` and `write-trap-client-secret`: **3/3 at 1.00** each. No raw HTML, a scheme-checked link, no new dependency, no `VITE_` key in the client, no direct third-party call, and the deviation explained.
  - `write-trap-effect-fetch` re-ran 3/3 at 1.00.
  - `review-security`: **1.00**. SEC-001, -002, -006, -007 and -008 found.
  - Both trap outputs type-check against React 19 types, exit 0.

### T17: Performance
**Description:** Write `references/performance.md` (`PERF`):
- React Compiler-aware memoization (A14)
- virtualizing large lists, naming TanStack Virtual only as an option, never adding it unasked
- code splitting with `lazy` and `next/dynamic`
- `useTransition` and `useDeferredValue`
- context re-render scope
- expensive work during render
- barrel imports (`info`).

**Acceptance:**
- [x] The slice DoD is met. *(A performance write eval wasn't planned for this slice; the compiler review fixture is its eval.)*
- [x] The review fixture "manual memo with the compiler enabled" yields `info`, not `warn`.

**Verify:** DoD commands.
**Dependencies:** T5 · **Files:** `references/performance.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/review-perf-compiler/` · **Scope:** S

**Done (2026-11-24).**
- **Docs check:** react.dev's compiler pages.
  - **Vite setup:** with `@vitejs/plugin-react` ≥ 6, it's `reactCompilerPreset()` through `@rolldown/plugin-babel`, because the inline babel option was removed. **SKILL.md's compiler detection** was updated to list that signal (A14 updated).
  - **Escape hatch:** manual `useMemo`/`useCallback` remain an escape hatch (e.g. for effect dependencies). PERF-001 includes that exception.
- **Rules: PERF (8).** 0 `error` (deliberate: measure first), 3 `warn` (003 expensive recomputation, 004 input lag, 005 code splitting), 5 `info`.
- **Sources:** 0 anchor misses.
- **Examples:** compile against React 19 types with `@tanstack/react-virtual` 3 and `lodash` 4, exit 0.
- **SKILL.md:** 193 lines, with a reference row.
- `check_catalog.py`: 145 rules OK.
- **Eval `review-perf-compiler`** (third clean control; the compiler is enabled with `reactCompilerPreset`; the component is full of manual memoization): **3/3 at 1.00**. It mentions the compiler, reports PERF-001/002 only as `info`, has no `[error]`, and approves.
- **Grader note:** the eval tool's regex engine (JavaScript) rejects inline flags like `(?i)`, so case variants are spelled out with character classes. No other grader in the suite uses `(?i)`.

### T18: Testing
**Description:** **Start by checking the Vitest 5, MSW 3 and RTL docs** (MSW 3 entrypoints, the ESM-only change, the Node 22 floor). Then write `references/testing.md` (`TEST`):
- Vitest + RTL + user-event
- queries by role or label, with `getByTestId` as the last resort
- `findBy`/`waitFor` instead of sleeps
- MSW instead of hand-mocking `fetch`
- a fresh `QueryClient` (retries off) and a fresh store per test
- router and provider wrappers
- testing Server Actions as functions
- the limits of testing async RSC
- Jest notes.

**Acceptance:**
- [x] The slice DoD is met.
- [x] A write eval in a project with a test setup produces RTL + MSW tests.
- [x] A project without a test setup gets an offer to set one up, not a dependency install.

**Verify:** DoD commands.
**Dependencies:** T5 · **Files:** `references/testing.md`, `rule-catalog.md`, `RATIONALE.md`, `evals/write-tested-component/`, `evals/write-no-test-setup/`, `evals/review-testing/` · **Scope:** M

**Done.**
- 10 `REACT-TEST` rules. Docs checked first: MSW 3 renamed `onUnhandledRequest` to `onUnhandledFrame` (cited from the official 2.x→3.x migration guide, TEST-005/006).
- `write-tested-component`, `write-no-test-setup` and `review-testing` each scored 1.00 over 3 runs (2026-11-24).
- **Gap found by actually running the output:** the generated `TodoList.test.tsx` type-checked and scored 1.00, but under Vitest 5 + jsdom 3 of 4 tests failed ("Found multiple elements"). The scaffold's Vitest has no `globals: true`, so RTL never auto-cleans. Fix: new rule **REACT-TEST-010** (`warn`, sources: RTL setup `#auto-cleanup-in-vitest`, API `#cleanup`), a `SKILL.md` red-flag clause, a RATIONALE entry, and a new `setup-cleanup` grader.
- Re-run (2026-11-25, `--runs 1 --ablation none --allow-tools Write,Edit`): 10/10 graders, 1.00. The skill added `cleanup()` to `src/test/setup.ts` by itself. The generated files, rebuilt from the run's trace, **run green under Vitest (4/4)** and `tsc --noEmit` exits 0. Negative control: the same tests without cleanup fail 3/4.
- `validate` ✓, `check_catalog` ✓ (155 rules), `check_links` ✓ (150 pages).

### ✅ Checkpoint D
See `plan.md`. **Stop for human review.**

**Checks run (2026-11-25), human review pending.**
- **Evals** (`--scaffold --runs 1 --ablation none --allow-tools Write,Edit -j 2`): all 33 write and plain-language review cases (`write-*` and `--tag plain`) ran, ~$11.
  - 32/33 scored 1.00 on the first pass.
  - `write-rr-loader-page` scored 0.88: `uses-loader` (`\bloader\b`) missed, although the final message described a route loader. A re-run with `--keep-temp` passed and showed the generated file names the function `loader`. The failed run's files weren't kept, so the likely cause, a different name such as `projectLoader`, is unconfirmed. The grader now also accepts `useLoaderData`, `LoaderFunctionArgs` or `Route.LoaderArgs`. Re-run with `--runs 3`: 3/3 at 1.00.
  - The 6 `/react-power-up:review` slash-command cases need `--allow-tools Bash`, which can't be granted from this sandbox. They're left for your run, as in Checkpoints A–C.
- **Rule completeness:** `check_catalog.py` ✓ (155 rules). A separate scan found every rule (including `info`) has a Source and a ❌/✅ example.
- **Domains:** all 15 SPEC domains have ≥ 1 `error` or `warn` rule (PERF, TEST and TS have warn only, no error).
- `validate` ✓ · SKILL.md 194 lines.

## Phase 5: Verification and polish

### T19: Trigger evals, coexistence with vue-power-up, description tuning
**Description:** Add the trigger evals:
- **positive:** "React component…", "TanStack Query hook", "Next.js Server Action", "TanStack Router route", "add a component to this `.tsx` file"
- **negative:** Vue, Nuxt, Svelte, Angular, React Native, Python.

Run one coexistence check with both plugins loaded (`--plugin-dir` ×2): a Vue prompt fires only vue-power-up, and a React prompt fires only react-power-up. Tune the skill description, and add the monorepo project-type fixture (R6).

**Acceptance:**
- [x] 100% of the trigger cases are correct.
- [x] Coexistence is correct both ways.
- [x] The monorepo fixture picks the right project type.

**Verify:** `claude plugin eval . --runs 1 --ablation none` on `trigger-*`; the coexistence check runs by hand headless and is recorded here.
**Dependencies:** T16, T17, T18 · **Files:** `skills/react-power-up/SKILL.md` (description), `evals/trigger-*`, `evals/write-monorepo-detect/` · **Scope:** M

**Done (2026-11-25).**
- **Trigger evals:** 12 cases (6 positive: react-component, query-hook, server-action, tsr-route, review-plain, tsx-file; 6 negative: vue-component, nuxt-page, svelte-store, angular-service, react-native, python-csv). `--runs 1 --ablation none`: **12/12 correct**, both before and after the description change.
- **Coexistence** (`tests/coexistence.sh`, headless, both `--plugin-dir`s):
  - First round: Vue, Nuxt, Pinia, React and Next prompts were all correct.
  - **Gap:** "TanStack Query hook useInvoices(page)…" fired *neither* skill in 4/4 runs, though react-power-up alone fires on it (`trigger-pos-query-hook`). Claude assumed React but treated the library as framework-ambiguous.
  - **Fix:** the description now names "custom hooks (use* functions)" and "TanStack Query (React Query) hooks", and says a "hook" request with no framework named is React (RATIONALE A16). After the fix: 4/4 fire react-power-up.
  - Regression round, including the closest Vue cases (a `useDebounce` composable without the word Vue, a `@tanstack/vue-query` composable): 7/7. Final scripted run: **9/9 correct**, never both skills.
- **Monorepo (R6), `write-monorepo-detect`:** 1.00 before and after the tuning. The final message identifies the admin app as React Router 8 library/data mode, uses a loader, and leaves `apps/web` untouched.
- `validate` ✓. Description 559 characters. README lists `tests/coexistence.sh`.

### T20: Type-check harnesses over generated code
**Description:** Build three harnesses in the scratchpad (never in this repo):
1. Vite + React 19 + TanStack Router + Query + Zustand + RHF/Zod + Vitest/RTL/MSW
2. Vite + React 19 + React Router v8 + RTK
3. Next 16 App Router

Copy each write eval's outputs into the matching harness and run `tsc --noEmit` (TS 7), plus a TS 5.x control run (R9). Include one negative control (a file with a deliberate type error) to prove that the harness catches errors.

**Acceptance:**
- [x] All write outputs type-check.
- [x] The negative control fails as expected.
- [x] The fallback is documented if a harness can't install (R7).

**Verify:** run `tsc --noEmit` in each harness and record the outputs here.
**Dependencies:** T19 · **Files:** none in the repo (scratchpad only), plus evidence in `tasks/todo.md` · **Scope:** M

**Done (2026-11-25).**
- **Harnesses** (scratchpad, reusing the installs built during T3–T18): `tsx19`, which covers plan harnesses 1 and 2 (React 19.3 types, React Router 8.5, TanStack Router 1.170 + Query 5, Zustand 5, RTK 2, RHF 7 + Zod 4, Vitest 5/RTL/MSW 3); `next16` (Next 16.4.6, RTK, Zod, `@types/node`); and `tsx18` (React 18 + React Router 7). All use TS 7.0.2. The TS 5.9.3 control is a separate install.
- **Outputs:** a fresh `--keep-temp` pass over all 19 `write-*` cases scored **19/19 at 1.00** ($5.48). Each output was rebuilt from its trace on top of its scaffold (the sealed workspaces were never opened), using the case's own tsconfig. The monorepo case was checked at `apps/admin`, and TSR route trees were generated with `tsr generate`.
- **`tsc --noEmit`: 19/19 exit 0 under TS 7, and 19/19 exit 0 under TS 5.9.**
- **Coverage check** (every generated file must be in `tsc --listFilesOnly`): it flagged `write-trap-client-secret/server/index.ts`. The scaffold's tsconfig includes only `src`, so the skill's server-side proxy route had never been checked. Checked separately with `module: NodeNext` + `@types/node`: exit 0 under both compilers, and it's in the program.
- **Negative control:** an `export const __neg: number = 'not a number'` planted in each case's own first generated file fails both compilers in 19/19 cases, plus the server file (TS2322).
- **R7 fallback:** not needed, since every harness installed. It's documented in RATIONALE A8.
- RATIONALE A8 filled in; the eval-design table gained a "Generated code" row.

### T21: Single-run pass over all cases, gap fixes, docs finalization
**Description:**
- Run the full suite with `--runs 1 --ablation none`.
- Fix the failures in the skill (never by weakening the graders) and re-run the affected cases.
- Finalize the README:
  - what the plugin does
  - requirements
  - install via `--plugin-dir` and via the local marketplace `react-power-up@mlsstjnvc`
  - write examples
  - review usage with output excerpts
  - the rule overview linking to the catalog
  - evals, including the exact full-run command
  - limitations
- Finalize RATIONALE: every decision, every rule, eval design, known limitations.
- Check off the SPEC success criteria with evidence.

**Acceptance:**
- [x] Every SPEC success criterion is checked or explicitly marked as needing the user's environment.
- [x] `validate --strict` passes.
- [x] `git log` shows no commits.

**Verify:** `claude plugin validate . --strict`; `python3 tests/check_catalog.py`; `python3 tests/check_links.py`; `sh tests/precheck.test.sh`; `wc -l skills/*/SKILL.md`; `git log`.
**Dependencies:** T20 · **Files:** `README.md`, `docs/RATIONALE.md`, `SPEC.md` (success criteria), `skills/**` (fixes) · **Scope:** M

**Done (2026-11-26).**
- **Scaffold fix (from T20):** `write-trap-client-secret`'s tsconfig now includes `server/` with Node types (plus `@types/node`). Re-checked: covered, exit 0 under TS 7 and TS 5.9, negative control fails.
- **Single-run pass** (`--runs 1 --ablation none`), 46 cases (everything except the 6 command cases):
  - **First attempt** granted `Bash` too. The sandbox then refused *every* case (credentials-file EACCES, $0), so the command cases can't share a run here.
  - Second attempt, with Write/Edit only: 41/46 at 1.00 on the first pass. 4 review cases hit the 5-hour usage limit mid-batch; re-run: 4/4 at 1.00.
  - **Real failure: `write-list-filter` 0.88.** The `labelled-controls` judge failed it (3/3): the expand button was named "Show notes" in every row. No rule covered this, and JSX-009's ✅ example used a bare "Details". Fix in the skill: **REACT-JSX-011** (`warn`; WCAG 2.4.6 and 2.5.3 `#intent`, checked), a RATIONALE entry, the `SKILL.md` reference map, and catalog/README counts. Re-run `--runs 3`: 3/3 at 1.00. Possibly affected cases re-run: `review-jsx-a11y`, `review-perf-compiler` (its "Details" buttons are now a correct `warn`) and `review-clean-control-components`, all 1.00.
  - **Result: 46/46 at 1.00.** That includes 19 write, 15 plain-language review (100% seeded-rule recall, 3 clean controls Approve with no `[error]`) and 12 trigger.
  - The 6 `/react-power-up:review` cases remain for your run with `--allow-tools Bash` (verified by hand in T4/T5).
- **README:** status, what it does, write examples with a walk-through, a real review excerpt, a rules table (156: 57 error / 84 warn / 15 info), evals with the exact full-run command and the Bash-refusal workaround, limitations, and design rationale.
- **RATIONALE:** status updated; stale stub notes removed; section 6 lists all 3 clean controls and the final 52-case suite; section 7 (known limitations) written; JSX-011 added.
- **SPEC success criteria:** 10 checked with evidence. 2 are explicitly marked as needing your environment: the local-marketplace install, and the formal command eval cases.
- **Verify:** `validate --strict` ✓ · `check_catalog` ✓ (156) · `check_links` ✓ (152) · `precheck.test.sh` ✓ · SKILL.md 194 + review 100 lines · `git log`: no commits.

### ✅ Checkpoint: Complete
- [x] All SPEC success criteria are met, or explicitly deferred to the user's environment (local-marketplace install; formal `/react-power-up:review` eval cases with `--allow-tools Bash`)
- [x] **Human sign-off** (2026-11-26)
