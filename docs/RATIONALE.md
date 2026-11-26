# react-power-up — Design Rationale

This document explains **why** each implementation decision and each rule exists:
- `SPEC.md` says *what* is built
- `tasks/plan.md` says *in what order*.

Ids used here:
- decision ids (`D*`) come from the SPEC decisions log
- architecture ids (`A*`) come from the plan
- rule ids (`REACT-*`) come from the rule catalog.

> **Status: complete for v0.1.0 (T21).** Every decision (D1–D16, A1–A16), every rule (156) and the eval design are covered. Entries were written by the task that implemented them; `tasks/todo.md` holds each task's evidence.

---

## Contents

1. [Product decisions (D1–D16)](#1-product-decisions)
2. [Architecture decisions (A1–A16)](#2-architecture-decisions)
3. [Repository layout and packaging](#3-repository-layout-and-packaging)
4. [Rule system](#4-rule-system)
5. [Rules, by id](#5-rules-by-id)
6. [Evaluation design](#6-evaluation-design)
7. [Known limitations](#7-known-limitations)

---

## 1. Product decisions

### D1: Name: `react-power-up` everywhere
**Decision:** The plugin (`plugin.json` `name`), the marketplace's plugin entry, the main skill directory and the repo folder are all `react-power-up`.

**Why:**
- Claude Code namespaces every component under the plugin name, so the review skill becomes `/react-power-up:review`.
- One name for the plugin, the skill and the folder keeps the command, the skill list and local paths predictable.
- The name mirrors the sister plugin `vue-power-up`, so users of one can find the other.
- It doesn't start with `claude-`/`anthropic-` and contains no reserved word, so `claude plugin validate` raises no name warning.

### D2: Separate repo, own marketplace
**Decision:** The plugin lives in its own repo with its own `marketplace.json` (`source: "./"`). The vue-power repo is not touched.

**Why:**
- The `ml2stjnvc` marketplace is defined inside vue-power with `source: "./"`, so it can only list the plugin at its own root.
- Listing a second plugin there would mean either restructuring vue-power into a monorepo or pointing at an external source. Both are publishing decisions that are better made once both plugins are on GitHub.
- A separate repo keeps the two plugins' development, evals and versions independent.

### D3: Writing is the primary use
**Decision:** The main skill is built around one write workflow (understand → detect → plan → implement → security pass → tests → self-check → report). Review is a secondary, user-invoked command (D9).

**Why:** Most of the value comes from producing correct code the first time: Claude applies the guardrails while writing instead of finding violations afterwards. This is the same choice as in vue-power-up, where it held up in evals.

### D4: React 19 primary, React 18 noted
**Decision:** Rules and examples target React 19. Where React 18 differs, the rule's *Applies* range says so, and the 18 alternative is given.

**Why:**
- React 19 is the current major (19.3 on npm, 2026-11-24).
- React Router v8 already requires React 19+, so the newest parts of the ecosystem assume it.
- React 18 apps are still common, and the main API differences have clear equivalents:
  - ref as a prop vs `forwardRef`
  - `use()`
  - `useActionState`, `useOptimistic` and `useFormStatus`
  - `<Context>` used as the provider
  - Without version gating, Claude would emit APIs those apps don't have.

### D5: Next.js App Router as the full-stack framework
**Decision:** Next.js App Router gets full coverage. The Pages Router is detected and only noted. TanStack Start is out of scope.

**Why:**
- Next.js is the most used React framework. The App Router is its current model and is where the riskiest mistakes happen:
  - server/client boundaries
  - Server Actions being public endpoints
  - secrets leaking into client bundles
  - caching
- This is the equivalent of Nuxt in vue-power-up.
- TanStack Start would roughly double the framework content and evals for a much smaller user base. It is left for a later version.

### D6: Routing: React Router (v8 primary, v7 noted) and TanStack Router v1
**Decision:**
- **React Router:** library mode (data mode and declarative mode). Framework mode is only noted. v8 is primary and v7 is noted.
- **TanStack Router:** covered fully.

**Why:**
- These are the two most used client routers.
- Framework mode is effectively a second full-stack framework (formerly Remix), so it is left out for the same reason as TanStack Start.
- The spec first said v7. The Plan-phase check found that v8 is current:
  - it requires React ≥ 19.2.7 (its peer dependency, confirmed in T11)
  - it is ESM-only
  - it removes `react-router-dom`
  - it turns on the v7 future flags by default.

  Because v8 needs React 19, React 18 projects stay on v7, which is why v7 is kept as notes.

### D7: Library coverage
**Decision:** The covered libraries are:
- TanStack Query v5
- Zustand
- Redux Toolkit, including the basics of RTK Query
- React Hook Form with Zod
- Vitest, React Testing Library, user-event and MSW

SWR, Jotai, Playwright, TanStack Table, Tailwind and shadcn/ui are mentioned but have no rules.

**Why:**
- Each covered library has anti-patterns that cause real bugs:
  - TanStack Query: query keys that leave out parameters
  - Zustand: selectors that re-render on every change
  - Redux Toolkit: state that can't be serialized
  - forms: validation only on the client
  - tests: assertions on implementation details
- They are also the most used choice in their category.
- The mention-only libraries either overlap with a covered one (SWR/Query, Jotai/Zustand) or are styling and UI layers where idiomatic use is mostly a matter of taste.

### D8: No hooks, no audit mode
**Decision:** Enforcement comes from skill guidance plus a mandatory self-check. There are no Claude Code hooks and no whole-repo audit.

**Why:**
- The scope is the same as vue-power-up's, chosen by the user.
- Hooks would run scripts on every edit in every project, including non-React ones.
- The self-check step plus running the project's own type-check, lint and tests covers most of what a hook would catch, without that cost.

### D9: Automatic writing skill, one review command
**Decision:**
- The writing skill fires on its own.
- Review is `/react-power-up:review [commit]`, implemented as a user-invoked plugin skill (`disable-model-invocation: true`).

**Why:**
- Writing help should need no ceremony.
- Review is something the user asks for on purpose, and it must not fire during write tasks.
- Plugin skills are namespaced, and Claude Code now recommends `skills/` over `commands/`.

### D10: Shared catalog via `${CLAUDE_PLUGIN_ROOT}`
**Decision:** The review skill reads the main skill's references through `${CLAUDE_PLUGIN_ROOT}/skills/react-power-up/references/…`.

**Why:** Rules are written once, so writing and review can't disagree. This worked as designed in vue-power-up.

### D11: Review precondition and output reused from vue-power-up
**Decision:** The git precondition, the read-only scope resolution, the hash validation and the standard-review output format are the same as vue-power-up's D13/D14. `precheck.sh` is ported with only the command name changed.

**Why:** That design is already built, tested by shell tests and evals, and documented. Reusing it removes risk instead of re-deriving it. It is the user's own work, so reusing it raises no licensing question.

### D12: Native eval format; the full run is the user's
**Decision:** Evals use `claude plugin eval` (`prompt.md` + `graders/`, with an optional `case.yaml`). During development only targeted single-run cases are run. The user runs the full 3-run, with-and-without-plugin comparison.

**Why:**
- The format is native, so it needs no extra tooling.
- The full run is costly.
- In vue-power-up, the development sandbox couldn't grant Bash, so the user's environment is the authoritative one (see plan R1).

### D13: README and RATIONALE are deliverables
**Decision:** Both are created in T1 and updated in the same task as any change to behaviour, commands, install steps or rules. RATIONALE explains every decision and every rule.

**Why:** The user requires it. It also keeps the reasoning next to the code, so future changes can see why a rule exists before weakening it.

### D14: Marketplace `mlsstjnvc`
**Decision:** The marketplace is named `mlsstjnvc`, owner Milos Stojanovic. The install id is `react-power-up@mlsstjnvc`.

**Why:**
- The user chose the name.
- It differs from vue-power's `ml2stjnvc`, so the two local marketplaces don't collide when both repos are added on one machine.

### D15: Author Milos Stojanovic, license MIT
**Decision:** `plugin.json` has `author` and `license: "MIT"`, and there is a matching `LICENSE` file. `repository` and `homepage` stay unset until the GitHub repo exists.

**Why:**
- This matches vue-power-up (its D17), as the user confirmed.
- With `author` and `license` set, `claude plugin validate --strict` passes from day one.
- Repository URLs aren't guessed.

### D16: Git initialized, never committed by Claude
**Decision:** Claude ran `git init` (branch `main`). Claude never commits, pushes or tags; the user handles git writes.

**Why:** The user asked Claude to start git. Committing stays under the user's control, the same rule as in vue-power.

---

## 2. Architecture decisions

### A1: Two skills: automatic `react-power-up` and user-only `review`
**Decision:** `skills/react-power-up` fires on its own on React work. `skills/review` runs only as `/react-power-up:review` (`disable-model-invocation: true`, added in T4).

**Why:**
- Writing help should need no ceremony, so the main skill fires from its description.
- The review procedure must never start by itself during a write task. Plain-language requests such as "review this component" go through the main skill, which points to the same procedure (`references/review.md`, T5).
- **The review skill (T4):** `disable-model-invocation: true` means only the user can start it, as `/react-power-up:review`. Its description lists the React areas it reviews, so it reads well in the skill list, but the model never matches against it.

### A2: One shared rule catalog
**Decision:** Every rule lives in exactly one `skills/react-power-up/references/*.md` file and has one row in `rule-catalog.md`. The review skill reads the same files (D10).

**Why:**
- If the writing and review rules were stored separately, they would drift apart: Claude would write code that its own review flags, or the reverse.
- `tests/check_catalog.py` enforces the single source mechanically. Every rule heading must have a matching index row with the same severity and file, every index row must have a heading, and every rule must have a RATIONALE entry.
- The index is generated from the headings (`--write-index`), so it can't go stale through hand edits.

### A3: Progressive disclosure, SKILL.md ≤ ~300 lines
**Decision:** SKILL.md holds the workflow, the detection tables, the red flags and a reference index. Rule detail lives in one reference file per domain, loaded only when the task touches that domain. In T2, SKILL.md was 146 lines against a working target of 150, which leaves room for each domain to add a red flag or two.

**Why:**
- A skill's body is loaded every time it fires (~3.5k tokens measured in T2 via `plugin details`). Reference files cost nothing until they're read.
- With 15 domains and 17 reference files (vue-power-up had 10 and 12), loading everything would put the Next.js server rules into a Vite SPA button task.
- **Rows are added to the reference table only when the file exists.** A row pointing at a missing file would make Claude try to read it and fail, or guess its contents.

### A4: Rule ids `REACT-<DOMAIN>-NNN`, severity, source, version range
See [§4 Rule system](#4-rule-system).

### A5: No shell pre-execution with user arguments
**Decision:** The review skill never puts `$ARGUMENTS` into a `` !`…` `` pre-executed command. Claude checks the argument against `^[0-9a-fA-F]{4,40}$` first, and only then runs git.

**Why:**
- Pre-executed commands run before the model sees anything. An argument like `--output=pwned.txt` or `; rm -rf ~` would reach the shell unchecked.
- A failing pre-executed command aborts the skill, instead of producing a friendly message.
- Verified in T4: `--output=pwned.txt`, `main` and `deadbeef` were all rejected with the documented messages, no file was created, and git state was unchanged.

### A6: Narrow `allowed-tools` for the review skill
**Decision:** `allowed-tools` pre-approves the precheck script, the exact read-only git forms the skill uses (`rev-parse`, `status --porcelain`, `diff HEAD`, `diff --cached`, `ls-files --others --exclude-standard`, `show`), and Read, Grep and Glob. The skill text separately forbids `--output`, `-o`, `--ext-diff`, `--textconv`, redirection, and any other command.

**Why:**
- `allowed-tools` only *pre-approves* tools. It doesn't restrict them, and patterns like `git show *` also match write-capable flags (plan risk R2). So the restriction has to live in the instructions, and the eval graders check for it.
- Pre-approving the safe forms means the command runs without permission prompts in headless mode. In T4, all 9 headless scenarios completed with no prompts.
- **Same list as vue-power-up:** the git surface is identical. Only the file filter differs (see A15).

### A7: Graders: regex for files, LLM for short answers
**Decision:** Write evals pin their output paths in the prompt.
- `regex` graders check the produced files: required APIs present, anti-patterns absent.
- `llm` graders judge semantics a regex can't, and are pointed at one file or the final message.
- Every case includes `tool_used: Skill`, matching `react-power-up`.

**Why:**
- Regexes over files are deterministic, so a failure means the output changed, not the judge.
- The LLM judge sees a short, focused input, which keeps it stable.
- The `skill-fired` grader separates "the skill didn't trigger" from "the skill triggered but gave bad advice". Those two failures have different fixes: the description versus the rules.
- This is the same design as vue-power-up's, where it gave stable single-run results.

### A8: Type-checking in scratch harnesses
**Decision:** Code produced by the write evals is type-checked outside the eval runs, in harness projects in the scratchpad (never in this repo).
- **Harnesses:** `tsx19` (React 19 + React Router 8, TanStack Router/Query, Zustand, RTK, RHF/Zod, Vitest/RTL/MSW), `next16` (Next 16.4.6 App Router + RTK, Zod, `@types/node`) and `tsx18` (React 18 + React Router 7), all with TS 7.0.2.
- **TS 5.9 control (R9):** every check also runs with a separate `typescript@5.9` install.
- **Rebuilding the output:** each output is rebuilt from the run's trace (its `Write`/`Edit` inputs) on top of the case's own `scaffold.sh`. The harness's `node_modules` is symlinked in, and the case's own `tsconfig.json` is used.

**Why:**
- Eval workspaces start empty and can't `npm install` within the scaffold time limit. Keeping the installs outside the repo also keeps dependencies out of the plugin.
- The kept eval workspaces are sealed, because the plugin under test wrote them. The trace has the exact file contents, so the workspaces are never unsealed.
- **Two guards stop "0 errors" from meaning "nothing checked":**
  - **Coverage:** every generated `.ts`/`.tsx` file must appear in `tsc --listFilesOnly`.
  - **Negative control:** a type error planted in each case's own generated file must make both compilers fail.
- The coverage guard caught a real blind spot in T20. `write-trap-client-secret` correctly moved the API key into the scaffold's `server/index.ts`, but the scaffold's tsconfig includes only `src`, so that file had never been checked. It's now checked separately against Node types.

**Fallback (R7):** if a harness can't install, check against the library's types only, or do a static review, and record which one was used. It wasn't needed: all three harnesses installed.

### A9: README links to the catalog instead of copying it
**Decision:** The README's Rules section gives a domain overview and links to `rule-catalog.md`. It never lists individual rules.

**Why:** Domain tasks add rules often. A copied list would go stale, or force a README edit in every task. The catalog index is generated, so a link to it is always accurate.

### A10: Git precondition in a bundled, ported script
**Decision:** `skills/review/scripts/precheck.sh` is vue-power-up's script, unchanged except for its header comment. It's pre-executed through `` !`${CLAUDE_SKILL_DIR}/scripts/precheck.sh` `` and pre-approved. The skill maps its three statuses to exact messages that name `/react-power-up:review`. If shell injection is disabled, the skill falls back to running the script through the Bash tool.

**Why:**
- The check is deterministic, takes no user input (so pre-executing it is safe, unlike A5), and always exits 0. That gives a friendly message instead of an aborted skill.
- **Ported instead of rewritten,** because it already has shell tests. `tests/precheck.test.sh` (also ported) passes all 9 assertions here: not a repo, repo root, subdirectory, no git on PATH, inside `.git`, exit codes, and a single output line.
- The messages live in SKILL.md rather than the script, so the script stays plugin-neutral.

### A11: Numbered, proposal-only review changes
**Decision:** The review output (`references/review.md`) has these parts:
1. Scope and Context
2. Summary
3. Verdict
4. Findings by severity, each `[severity] REACT-ID file:line` with a code-specific *Why* and a source link
5. an optional Pre-existing note
6. numbered Proposed changes as `diff` blocks
7. an optional "What's done well"
8. the line "To apply any of these, tell me which."

Nothing is applied.

**Why:**
- **It matches how human code review works:** analysis, then suggestions. Numbering lets the user say "apply 1 and 3", and keeping it proposal-only keeps the command read-only (D11).
- **The Context line replaces vue-power-up's Versions line.** A React review depends on more than versions: the project type (App Router vs SPA) and the compiler change which rules apply. Stating them up front lets the user catch a wrong detection immediately.
- **Calibration rule 8:** never flag outside the **Applies** range, and never flag manual memoization as a problem when the compiler is off. These are the two React-specific false-positive traps.
- **Never quote secret values:** the review transcript may be shared. A leaked credential is reported by location, and the user is told to rotate it.
- **Verified in T5:**
  - the 4 command scenarios, run headless and graded with each case's own regex graders, all passed
  - the plain-language seeded case: 1.00
  - the clean control: 1.00, Approve with no `[error]`.

### A12: Project-type detection picks the references
**Decision:** Workflow step 2 classifies the project using the table in SKILL.md:
- Next.js App Router
- Next.js Pages Router (noted only)
- React Router framework mode (noted only)
- TanStack Router SPA
- React Router SPA
- plain React SPA

The signals are dependencies plus marker files and dirs (`app/`, `pages/`, `react-router.config.*`, `routeTree.gen.ts`, router plugins in the Vite config). Conflicting signals mean asking the user.

**Why:**
- The same request needs different code in different React project types. "Add a page that lists orders" is an async server component in the App Router, a loader in React Router, and a route with `ensureQueryData` in TanStack Router. Picking the wrong model produces code that runs but fights the framework.
- **Order matters:** `next` is checked before the routers, because Next apps sometimes have a router library installed for other reasons. Framework mode is checked before library mode, because both depend on `react-router`.
- **The "noted only" types** (Pages Router, framework mode) are explicitly named, so Claude says it's working outside full coverage instead of silently applying App Router or library-mode rules where they don't fit (D5, D6).
- **The nearest `package.json`** handles monorepos with several apps (plan risk R6).
- **React Native is excluded here and in the skill description.** It shares `react` but has different primitives (no DOM, no `dangerouslySetInnerHTML`, no `href`), so most rules would be wrong there.

### A13: Next.js split into `nextjs.md` and `nextjs-server.md`
**Decision:** The `NEXT` domain spans two files:
- **`nextjs.md`** (ids 001–012): rendering, data, caching, navigation and metadata
- **`nextjs-server.md`** (ids 101–111): Server Actions, route handlers, proxy, env, sessions and data exposure.

**Why:**
- A client-component or page task needs the boundary and data rules, but not the route-handler and session rules, and vice versa. vue-power-up's single `nuxt.md` grew to 416 lines. Together, the two files here hold 23 rules, but each loads only when its half is relevant.
- **Separate id ranges** (001+ and 101+) let both files grow without interleaving ids, and the range tells a reader which file a finding came from.
- **One domain, not two:** it's all one framework, and the review procedure's domain map points Next.js changes at both files.

### A14: React Compiler detection decides the memoization advice
**Decision:** SKILL.md detects the compiler (`babel-plugin-react-compiler` configured, or `reactCompiler: true` in the Next config). With the compiler on, Claude adds no manual memoization, and existing memoization counts as redundant (`info`). With it off, Claude memoizes only for a measured cost or for referential identity.

**Why:**
- The compiler (1.0 stable on npm, 2026-11-24) memoizes components and values automatically. Hand-written `useMemo`/`useCallback` then add noise and can mask the compiler's own analysis.
- Without the compiler, react.dev's guidance is that memoization is an optimization for specific costs, not a default.
- A single static rule would therefore be wrong for one of the two groups. The detail rules (PERF) land in T17; T2 only puts the detection and the two-row decision table into the workflow.
- Existing memoization is left alone unless the task touches that code, so a small feature doesn't turn into a refactor.
- **T17 update (docs checked):**
  - **Vite detection:** with `@vitejs/plugin-react` ≥ 6, the compiler is enabled with `reactCompilerPreset()` through `@rolldown/plugin-babel`, because the inline `babel` option was removed in plugin-react 6 (react.dev *Installation → Vite*). SKILL.md's detection now lists that signal alongside the Babel config, the old inline option and Next's `reactCompiler`.
  - **Escape hatch:** react.dev's compiler introduction says to rely on the compiler for new code and to keep `useMemo`/`useCallback` as an escape hatch, for example for effect dependencies. REACT-PERF-001 encodes that, including the exception.

### A15: Generated route trees and build output excluded
**Decision:**
- **Never reviewed:** `routeTree.gen.ts`, `.react-router/`, `next-env.d.ts`, and build output (`.next/`, `dist/`, `build/`, `out/`, `coverage/`).
- **Never hand-edited:** the same generated files are a red flag for edits in SKILL.md.
- **`.env*` files:** reported only as changed, never read; only `.env.example` is reviewed.

**Why:**
- Generated files are rewritten by the next build or dev server. Findings in them are noise, and edits to them vanish.
- `routeTree.gen.ts` can be thousands of lines, so reviewing it would also push real files out of the large-diff budget.
- **`.env*`:** real env files hold secrets. Reading them would put the values in the transcript, so the review only notes that they changed. `.env.example` is safe, and it's where a missing `NEXT_PUBLIC_` mistake usually shows up.
- **Server code first in large diffs:** Server Actions, route handlers and loaders are where the highest-severity rules (`SEC`, `NEXT`) apply.
- **TanStack Router half (T12):** the docs (checked 2026-11-24) say that file-based routing on Vite uses `@tanstack/router-plugin` (`tanstackRouter({ target: 'react', autoCodeSplitting: true })`, placed before `react()`), and other bundlers use `@tanstack/router-cli`. Both regenerate `routeTree.gen.ts` on every route change, and the docs recommend excluding it from linting and formatting. REACT-TSR-001 makes "never hand-edit it" a rule, and SKILL.md's self-check generates the tree before type-checking when the project's script does that, since stale trees give false type errors.

### A16: Coexistence with vue-power-up
**Decision:** The skill description names React-specific triggers (`.tsx`, hooks, Next.js App Router, React Router, TanStack, Zustand, Redux Toolkit, React Hook Form) and ends with "Not for Vue, Nuxt, Svelte, Angular, Solid or React Native". vue-power-up's description already excludes React.

**Why:**
- The user owns both plugins and may install both. If both skills fired on one prompt, Claude would load two conflicting rule sets: Vue's `v-html` rules next to React's `dangerouslySetInnerHTML` rules, Pinia next to Zustand.
- Mutual exclusions in both descriptions are the cheapest way to keep each skill to its own framework.
- **Verified in T19 with both plugins loaded** (`tests/coexistence.sh`, headless `claude -p --plugin-dir` ×2). `claude plugin eval` loads only the plugin under test, so the check can't be an eval case.
- **What T19 found:** Vue, Nuxt, Pinia, React and Next.js prompts went to the right skill from the start. But "Write a TanStack Query hook useInvoices(page)…" fired **neither** skill in 4 of 4 runs with both loaded, although react-power-up alone fired on it. TanStack Query exists for both frameworks, so Claude treated the prompt as ambiguous: it assumed React but skipped the skill, and twice also wrote a Vue version.
- **Fix:** the description now says "custom hooks (use* functions)", "TanStack Query (React Query) hooks", and "A \"hook\" request that names no framework is React". The hook/composable vocabulary is the one real signal in such a prompt: React says hook, Vue says composable. After the change it fired 4 of 4, and the closest Vue cases (a `useDebounce` *composable*, a `@tanstack/vue-query` composable) still go only to vue-power-up.

---

## 3. Repository layout and packaging

### Skill under `skills/react-power-up/`, not at the repo root
The `skills/<name>/` layout keeps the shipped skill payload separate from the repo's README, SPEC, docs, evals and tasks, so none of those load as skill content.

### Marketplace in the same repo, `source: "./"`
One repo can be added directly as a marketplace (`/plugin marketplace add <path>`) without a separate marketplace repo (D2, D14).

### Manifest contents
- **`plugin.json`:**
  - name, version `0.1.0` (pre-release until T21), description, author, license, keywords
  - no `repository`/`homepage` (D15)
  - no explicit component paths, since Claude Code discovers the default `skills/` layout.
- **`marketplace.json`:** one plugin entry, category `development`.

### `.gitignore`
Ignores `evals/results/` (eval output), `.idea/` and `.DS_Store`, the same as vue-power.

### Verification performed in T1
- `claude plugin validate .` and `claude plugin validate . --strict` both pass (exit 0) with no manifest warnings.
- The validator's separate *plugin directory* check reports one warning: `ICON_MISSING`. It doesn't affect the result. An icon is a design asset for the user to provide (vue-power's icon is Vue-specific, so it isn't reused).
- `claude --plugin-dir . plugin details react-power-up` loads the plugin as `react-power-up 0.1.0` with 0 components and ~0 always-on tokens, as expected before T2.

---

## 4. Rule system

### Rule ids: `REACT-<DOMAIN>-NNN`, never renumbered
- **Traceability:** a review finding, a code comment such as `// REACT-SEC-001 accepted by user`, and a RATIONALE entry all refer to the same id. If ids were renumbered, old comments and reports would point at the wrong rule.
- **Gradeable:** eval graders can check for a rule id with a simple regex, which is deterministic (A7).
- **15 domains, one reference file each.** The exception is `NEXT`, which spans `nextjs.md` and `nextjs-server.md` (A13).
- **Short domain codes:** `RR` and `TSR` keep the two routers apart. `EFF` is separate from `HOOK` because effect misuse is the largest single class of React bugs, and react.dev covers it in a dedicated guide ("You Might Not Need an Effect").
- **`check_catalog.py` rejects unknown domains,** so a typo like `REACT-HOOKS-001` can't create a silent sixteenth domain.
- **Retired, not deleted:** a retired rule keeps its row marked *Retired*, so its id is never reused with a different meaning.

### Three severities, tied to behaviour
| Severity | Write mode | Review |
|---|---|---|
| `error` | never produced unless the user insists | Request changes |
| `warn` | avoided unless there's a stated reason | Approve with suggestions |
| `info` | the project's convention wins | never blocks |

- **Why only three:** each level maps to a distinct action in both modes. More levels would need extra rules about how they differ, with no difference in what Claude does. This is the same model as vue-power-up.
- **`error` means a bug, data leak or security issue.** A reviewer must be able to justify blocking a change. "Unidiomatic" alone isn't enough to block, so it's `warn`.
- **Unofficial means `info` at most.** The plugin is published to a marketplace, so its defaults must be neutral. The list of what counts as official is fixed in `rule-catalog.md`, so the cap can be applied mechanically.

### Rule template
Every rule has: **Why**, **Source**, a ❌/✅ **example**, **Applies** and **Exceptions**.
- **Why:** the model applies a rule better, and can explain a deviation, when it knows the failure the rule prevents.
- **Source:** an official URL makes each rule verifiable and guards against outdated or invented APIs (plan risk R3). It's required for `error` and `warn`. `check_links.py` checks that every source page resolves.
- **❌/✅ example:** one minimal pair communicates a pattern more reliably than prose, and gives the review a concrete before and after. Examples are TSX, because that's what the plugin writes.
- **Applies:** see version gating below. It can also name a project type ("App Router only").
- **Exceptions:** the main defence against false positives (plan risk R4).

### Version gating
**Decision:** Every rule states the versions where its recommended fix exists. SKILL.md has a minimum-version table for the most important APIs, and the workflow resolves versions *before* writing code.

**Why:**
- Recommending ref-as-a-prop or `useActionState` to a React 18 project produces code that doesn't work, which is worse than the pattern it replaces.
- **Resolution order is `node_modules` → lockfile → `package.json` range minimum.** `node_modules` holds what actually runs, and the lockfile is what will be installed. A range like `^18.2.0` only guarantees its minimum.
- **`react-router-dom` is also resolved,** because v7 projects often still depend on it, while v8 removed it (D6).
- **The table lists only cross-cutting minimums** (React 18/19, React Router 8, TanStack Query 5, Next 16). Library-specific minimums live in each rule's **Applies**, so the table doesn't grow with every domain.
- **Next.js entries are limited** to the two v16 changes confirmed in the Plan phase (`proxy.ts`, opt-in Cache Components). Further 15↔16 details are added in T14/T15 after checking the official docs (plan risk R3).
- **Below the range, a rule isn't flagged.** In write mode, the skill uses the best alternative available and mentions the upgrade path once.

<a id="write-workflow-steps"></a>
### Write workflow steps
| Step | Why it exists |
|---|---|
| 1. Understand | Restating the deliverable catches misunderstandings cheaply. The example questions are the ones where React projects genuinely split: server vs client component, where state lives (URL, local, store, server cache), route vs modal, Server Action vs route handler. Anything else gets a sensible default that's named in the report. |
| 2. Detect context | Most best-practice mistakes depend on context: the version (gating), the project type (A12), the compiler (A14), existing libraries. Introducing Zustand in a Redux app fragments the codebase. **Never adding dependencies unasked** respects the user's control over the supply chain and bundle size. |
| 3. Plan files | Listing files before writing forces structural decisions (component vs hook vs store) while they're cheap to change. Marking **server/client** per file in the App Router makes the boundary an explicit decision instead of an accident, which is where most App Router bugs start. |
| 4. Implement | Function components and hooks are the only form react.dev teaches for new code, and `.tsx` keeps type safety. Class components are left alone so a feature request doesn't become an unrequested migration. **Generated files** are never edited, because the next build overwrites them (A15). |
| 5. Security pass | Security bugs come from data flows, not single lines. The sinks listed are the ones React apps actually have: raw HTML, URL attributes, redirects, server code (Server Actions are public HTTP endpoints even when they look like function calls), client-visible data (including server-to-client props and hydrated caches), and cookies. Rule ids are added to each sink in T16, when the `SEC` rules exist. |
| 6. Tests | Tests are part of "done" in projects that have them. Role and label queries test what users experience and survive refactors. A fresh `QueryClient` or store per test prevents leaked state between tests. When there's no setup, the skill *offers* one, because test tooling is a project-level decision. |
| 7. Self-check | The red flags catch process mistakes, and the project's own type-check, lint and tests catch what reading misses. **The route tree is generated first** for TanStack Router, because its types come from `routeTree.gen.ts` and a stale tree gives false type errors. Only **existing** checks are run. |
| 8. Report | Listing every guardrail deviation makes visible wherever Claude didn't do literally what was asked. Listing the checks that ran stops unverifiable "all good" claims. Server/client per file lets the user check the App Router boundary at a glance. |

### Conflict policy: deliver safely, explain, comply only if the user insists
- **Why not comply silently:** the user gets an anti-pattern or a vulnerability without knowing it.
- **Why not refuse:** the user often has context Claude doesn't, such as a trusted HTML source or a legacy constraint.
- **The middle path:** build the safe version and explain. If the user insists, comply, and leave a **code comment with the rule id**, so the decision is visible to future maintainers and future reviews.

### Cross-cutting red flags in SKILL.md
In T2, SKILL.md has only process-level red flags:
- versions and project type
- dependencies
- class components or `.js` files
- unexplained deviations
- unchecked data flows
- generated files
- unverified claims
- type escapes.

Each domain slice may add one or two lines for its most common, highest-impact `error` rules, with ids. Everything else stays in the reference files, so SKILL.md stays within its budget (A3).

### Skill description (frontmatter)
- **It lists concrete triggers:** `.tsx` components, hooks, context, forms, App Router pages, layouts, Server Actions and route handlers, both routers, TanStack Query, Zustand, Redux Toolkit, React Hook Form with Zod, and tests. The description is what Claude matches requests against, so it names what users actually ask for.
- **It includes "reviewing,"** so plain-language review requests also use the rules.
- **It explicitly excludes** Vue, Nuxt, Svelte, Angular, Solid and React Native (A16).
- **It names \"custom hooks (use* functions)\" and \"TanStack Query (React Query) hooks\", and says a \"hook\" request with no framework named is React.** This was added in T19 for the coexistence case above (A16).
- **Length:** 559 characters, well under the 1,024-character frontmatter limit.
- **Trigger evals (T19):** 6 positive cases (React component, TanStack Query hook, Server Action, TanStack Router route, plain-language review of a snippet that never says "React", and a `.tsx` file in a project whose prompt never says "React") and 6 negative ones (Vue, Nuxt, Svelte, Angular, React Native, Python). Negative graders use `tool_used` with `max: 0`. All 12 were correct before and after the tuning.
- **Monorepo fixture (R6), `write-monorepo-detect`:** a pnpm workspace with a Next 16 app and a Vite + React Router v8 app, and a framework-free root `package.json`. The task targets the admin app. Graders reject Next.js imports, `'use client'`, `react-router-dom` and effect fetching in the new route, and require that nothing is created in the Next app. Detection must come from the nearest `package.json`, as SKILL.md says.

---

## 5. Rules, by id

Every source URL and `#anchor` below was checked while its rule was written: pages with `check_links.py`, and anchors with a scratch script that confirms the fragment's `id` exists on the page. Every ✅ example was type-checked in scratch harnesses (React 19 types and React 18 types, TS 7.0.2, `strict`). Examples gated to one version were checked against that version's types.

### TypeScript (`REACT-TS`, `references/typescript.md`)

#### REACT-TS-001 · Type every component's props explicitly
- **Included:** the props type is the component's contract. Without it, call sites go unchecked.
- **`warn`, not `error`:** under `strict`, untyped props are already a compile error (`noImplicitAny`), so the realistic case is a non-strict project where the code still runs.
- **Source anchor:** react.dev's TypeScript page has no "typing component props" anchor; the guidance sits under *TypeScript with React Components*.

#### REACT-TS-002 · No `any` / unchecked `as` / silencing `!`
- **Included:** these escape hatches undo every other TS rule.
- **`warn`, not `error`:** the type escape itself isn't the bug; *unvalidated external data* is. That case is covered at `error` by the `SEC`, `NEXT`, `FORM` and router rules, and keeping this one at `warn` avoids counting one problem twice. This is the same reasoning as vue-power-up's VUE-TS-010.
- **Exceptions:** `as const`, narrowing event targets, test doubles, and a commented `!` after a check the compiler can't follow are the legitimate uses.

#### REACT-TS-003 · `children: React.ReactNode`
- **Included:** `JSX.Element` for children is one of the most common typing mistakes in React code. It rejects strings and `null`, which are valid children.
- **Exception:** components that clone or inspect a single child genuinely need `ReactElement`.

#### REACT-TS-004 · React event types
- **Included:** handlers declared outside JSX lose inference, and `any` is the usual fallback.
- **The example uses `currentTarget`, not `target`:** `currentTarget` is typed as the element the handler is attached to, while `target` is any descendant and is only typed as `EventTarget`.

#### REACT-TS-005 · Typed `useRef` with an initial value
- **Included:** this is a real breaking change in React 19's types. `useRef<T>()` with no argument fails to compile (confirmed in the harness: TS2554, "Expected 1 arguments, but got 0"). The `null` initial value for DOM refs is also what makes `ref.current` nullable and safe.
- **`warn`:** the compiler catches the 19 case. The rule exists so Claude never writes it in the first place.
- **Source:** react.dev's TypeScript page has no `useRef` section, so the rule cites the `useRef` reference page and the React 19 upgrade guide's *useRef requires an argument*.

#### REACT-TS-006 · `null` context default + guard hook
- **Included:** `createContext<T>({} as T)` type-checks and then fails at runtime. The `null` + throwing-hook pattern is the one react.dev shows under *Typing useContext*.
- **Exception:** contexts with a real default (theme, locale) are valid outside a provider.

#### REACT-TS-007 · Discriminated-union props
- **`info`:** discriminated unions are official TypeScript, but applying them to props is a design choice react.dev doesn't prescribe. Under the source rule (§4), that caps it at `info`.

#### REACT-TS-008 · `React.FC` optional
- **Included** mainly to stop Claude *adding* `React.FC` everywhere out of habit. react.dev's examples use plain functions with typed parameters.
- **`info`:** both forms are correct. The project's convention wins.

#### REACT-TS-009 · Generic components
- **Included:** `any[]` lists are the main way type safety leaks out of reusable components. The example also uses `getKey`, so the key comes from the data (see `JSX` rules in T7), not from the index.
- **`warn`:** the fix is a standard TypeScript feature (handbook: Generics), and the failure is a lost type link that hides real bugs in callbacks.

#### REACT-TS-010 · `React.ComponentProps<'tag'>` for wrappers
- **`info`:** react.dev lists `ComponentProps` under *Useful Types* but doesn't prescribe it.
- **Included anyway:** hand-written wrapper props usually drop `aria-*` and `disabled`, which hurts accessibility. The example also defaults `type="button"` so the wrapper doesn't submit forms by accident.

### Component design (`REACT-COMP`, `references/components.md`)

#### REACT-COMP-001 · No component definitions inside components
- **`error`:** it's a functional bug, not a style issue. State and focus reset on every parent render (react.dev's pitfall under *Different components at the same position reset state*). The example shows the most visible symptom: an input that loses focus after each keystroke.
- **Exception:** render helpers called as functions are not components, so they don't remount, and they're not flagged.

#### REACT-COMP-002 · Props are read-only
- **`error`:** mutating a prop corrupts the parent's state without a re-render, which is a Rules of React violation (*Props and state are immutable*).
- **The example uses `.sort()`,** the most common accidental mutation. `toSorted` is shown with a note on its ES2023 lib requirement, because older targets don't have it.

#### REACT-COMP-003 · Pure render
- **`error`:** side effects during render run an unpredictable number of times (StrictMode, concurrent rendering, discarded renders).
- **The ✅ example also encodes the id** with `encodeURIComponent`, so it doesn't build a URL from raw input. This follows the security pass.
- **Exceptions:** local mutation and lazy ref initialization are explicitly allowed by react.dev (*Local mutation*, *Lazy initialization*), so they're listed to avoid false positives.

#### REACT-COMP-004 · Controlled or uncontrolled, never both
- **`error`:** both failure modes are user-visible bugs. One is a read-only input that ignores typing; the other is the uncontrolled-to-controlled switch React warns about. react.dev has a dedicated troubleshooting entry for that warning, which is cited.
- **Exception:** `readOnly` makes a deliberately read-only input explicit.

#### REACT-COMP-005 · Composition before context
- **`warn`:** drilling works. It just couples layers. react.dev's *Before you use context* recommends passing props, then extracting components and passing JSX as children, before reaching for context. The rule follows that order.
- **Exception:** one or two levels of props is normal and often clearest. It's listed so reviews don't flag ordinary prop passing.

#### REACT-COMP-006 · Stable context values
- **`warn`:** an unstable value costs re-renders, not correctness. It's the documented optimization on the `useContext` page.
- **Compiler exception (A14):** with React Compiler on, the compiler memoizes the value, so the manual `useMemo`/`useCallback` in the ✅ example would be redundant.

#### REACT-COMP-007 · React 19: ref as a prop
- **`warn`:** `forwardRef` still works on 19. It's redundant, and React's 19 release post says it will be deprecated.
- **Exception:** libraries that support 18 still need `forwardRef`.

#### REACT-COMP-008 · React 18: `forwardRef`
- **`error`:** on 18, ref-as-a-prop silently doesn't work (`ref` is stripped from props), so the parent's ref stays `null`.
- **Why a separate rule from COMP-007:** the two versions need opposite advice, and both are real failure modes. A React 19 habit applied to an 18 project is exactly what version gating exists to prevent (D4). The version eval in T8 checks this pair.

#### REACT-COMP-009 · `<Context>` as provider
- **`info`:** both forms work on 19. `.Provider` is slated for deprecation, but it's not deprecated yet. The rule only steers new code.

#### REACT-COMP-010 · Suspense fallbacks and error boundaries
- **`warn`:** missing boundaries make failures bigger (a blank page, or an unmounted tree) rather than creating them.
- **Exceptions:**
  - Framework route-level boundaries (Next `error.tsx`/`loading.tsx`, React Router `ErrorBoundary`, TanStack Router components) are the idiomatic place in those projects.
  - **The error-boundary class exception** is also recorded in SKILL.md's red flags. Writing a new class component is otherwise a red flag, but error boundaries can only be classes (react.dev: *Catching rendering errors with an error boundary*). Without it, the skill would contradict itself. A library such as `react-error-boundary` is used only if the project already has it, since dependencies are never added unasked.

#### REACT-COMP-011 · React 19: default parameters, not `defaultProps`
- **`error`:** on 19, `defaultProps` on function components is removed and **silently ignored**, so props that used to have defaults arrive `undefined`. That's a runtime bug that appears only after upgrading (React 19 upgrade guide, *Removed: propTypes and defaultProps*).
- **Recommended on 18 too:** default parameters work everywhere, so new code never needs `defaultProps`.
- **Exception:** class components still support `defaultProps`.

### Hooks and state (`REACT-HOOK`, `references/hooks.md`)

#### REACT-HOOK-001 · Hooks only at the top level
- **`error`:** breaking call order corrupts state or throws. It's one of the two Rules of Hooks.
- **The example uses an early `return` before a hook,** the most common real-world form. Loops and conditions are covered by the same rule.
- **Exception:** `use()` is explicitly allowed in conditions and loops (React 19), so it's listed to prevent false positives.

#### REACT-HOOK-002 · Hooks only from components and custom hooks
- **`error`:** it's the second Rule of Hooks, and a violation throws or binds state to the wrong component.
- **The example uses an event handler,** where the mistake usually happens. The fix moves the hook to the component and reads the value in the handler.

#### REACT-HOOK-003 · Complete dependencies, no linter suppression
- **`error`:** a missing dependency gives a stale value, which is a correctness bug. react.dev has a dedicated section on why suppressing the linter is dangerous.
- **Exceptions:** `setState`, `dispatch` and refs are stable by React's guarantee. Reading a value without reacting to it has a proper tool (HOOK-004), so dropping the dependency is never the fix.

#### REACT-HOOK-004 · `useEffectEvent` for non-reactive reads
- **Version:** `useEffectEvent` became stable in React 19.2 (react.dev blog, *React 19.2*, 2025-10-01). The harness types (`@types/react` 19.3.0) export it. It's gated to ≥ 19.2, and the pre-19.2 fallbacks are given.
- **`warn`:** the alternatives (re-running too often, or a ref updated in an effect) work, just worse.
- **Exceptions** restate the documented caveats: Effect Events may only be called from effects and must never be passed down or listed as dependencies. Breaking these is the main new misuse risk of this API.

#### REACT-HOOK-005 · Stable dependencies
- **`warn`:** unstable dependencies cause extra runs. They become loops only when the effect also sets state, and that case is caught by tests and lint.
- **Compiler note:** the compiler stabilizes many values, but primitive dependencies are still the clearest for effects, so the advice holds in both modes (A14).

#### REACT-HOOK-006 · Never mutate state
- **`error`:** a mutated state value that's set back as the same reference skips the re-render, which is a user-visible bug. This is react.dev's *Treat state as read-only*.
- **Exceptions:** local copies and Immer drafts mutate legitimately. RTK's `createSlice` uses Immer, so this exception avoids false positives in the `STATE` domain later.

#### REACT-HOOK-007 · Updater form for state that depends on the previous state
- **`warn`, not `error`:** in a single synchronous update both forms are equal. react.dev's *Is using an updater always preferred?* says so explicitly, so the rule only targets multi-update, async and timer cases.

#### REACT-HOOK-008 · Initializer function for expensive initial state
- **`warn`:** wasted work, not incorrect output. The second ❌ line (`JSON.parse(localStorage…)`) is also an SSR hazard, so the exception points to the Next.js rules rather than duplicating them.

#### REACT-HOOK-009 · `use*` naming matches hook usage
- **`warn`:** both directions matter. A hook without the prefix escapes the linter's and the compiler's checks, and a prefixed non-hook can't be called conditionally. react.dev's *Should all functions called during rendering start with the use prefix?* is the basis for the second half.

#### REACT-HOOK-010 · `useSyncExternalStore` for external stores
- **`warn`:** the effect + state version works, but it shows a stale value on the first render and can tear in concurrent rendering. The ✅ example includes a server snapshot (`() => true`), so it's SSR-safe.
- **Exception:** libraries with their own hooks already use this API internally.

#### REACT-HOOK-011 · No `ref.current` during render
- **`warn`:** react.dev's `useRef` pitfall says not to read or write refs during render, except for initialization. The visible symptom (a stale count on screen) is a bug, but a contained one.
- **Exceptions:** lazy initialization, and use in handlers and effects, are the documented legitimate uses.

### Effects (`REACT-EFF`, `references/effects.md`)

The whole domain follows react.dev's *You Might Not Need an Effect*. It's a separate domain because effect misuse is the most common source of React bugs that compile and pass a quick manual test: duplicate requests, stale UI, leaks. The reference file opens with the decision questions, because the most important call is whether to write an effect at all.

#### REACT-EFF-001 · Derive during render
- **`error`:** the synced copy is one render stale, and it drifts whenever the sync is missed. This was the spec's example rule (SPEC *Code Style*).

#### REACT-EFF-002 · Event logic in handlers
- **`error`:** effects keyed on a "submitted" flag re-fire on remount and on StrictMode's development double-mount, which sends duplicate POSTs. That's a data bug, not a style issue.
- **Exception:** page-view analytics and connections are caused by display, so they're valid effects. react.dev makes this exact distinction.

#### REACT-EFF-003 · Reset with `key`
- **`warn`:** the effect version works, but it renders once with leaked state. react.dev's example (a comment draft leaking across profiles) is reused because it shows the user-visible symptom.

#### REACT-EFF-004 · No effect chains
- **`warn`:** each link costs a render and makes the flow hard to follow. It isn't always wrong.
- **Exception:** dependent network requests, which react.dev also allows. They point to dependent queries in `tanstack-query.md` (T10).

#### REACT-EFF-005 · Fetch effects need race handling; prefer the data layer
- **Placement in SKILL.md (Checkpoint B finding):** a red flag alone wasn't enough. With the trap prompt ("just fetch in a `useEffect`"), Claude sometimes followed the literal wording without opening `effects.md`. The data-layer rule is therefore also a bullet in workflow step 4 (Implement), framed as a guardrail conflict. The trap went from 2/3 to 3/3 after this.
- **`error`:** without cleanup, out-of-order responses show wrong results, a correctness bug that's easy to reproduce by typing fast.
- **Two-level advice:** the *race handling* is mandatory everywhere. The *data layer* (Query, loader, RSC) is preferred **only when it's already installed**, because dependencies are never added unasked.
- **The ✅ example** uses `AbortController`, `encodeURIComponent`, and `unknown` plus a parser, so it also satisfies REACT-TS-002 and the security pass. This is the trap eval's target behaviour (`write-trap-effect-fetch`).

#### REACT-EFF-006 · Clean up everything you start
- **`error`:** leaks cause duplicated work and `setState` on an unmounted component. StrictMode's double-mount exists to surface this. The ❌ example puts two leaks in one effect, a common real-world shape.

#### REACT-EFF-007 · Fix the cleanup; don't block StrictMode
- **`warn`:** the ref guard "works" in development and moves the bug to production. react.dev has a dedicated *Don't use refs to prevent Effects from firing* section.
- **Exception:** true app-level one-time initialization belongs at module scope, per react.dev's *Initializing the application*.

#### REACT-EFF-008 · Notify parents in the handler
- **`warn`:** one render late, with a possible inconsistency in between. It's react.dev's *Notifying parent components* case. The ✅ example also shows the fully controlled alternative.

### JSX and accessibility (`REACT-JSX`, `references/jsx.md`)

**Accessibility sources:** WCAG 2.2 *Understanding* documents, the WAI-ARIA Authoring Practices Guide (APG), and the eslint-plugin-jsx-a11y rule docs. All three are on the official list in `rule-catalog.md`.
- The **HTML Living Standard** was added to that list in T7, for JSX-006: the default `type` of `<button>` is defined there, and nowhere more authoritative.
- **The anchor checker was widened** to recognise unquoted `id=` attributes, which the WHATWG spec uses. Single-quoted ids were added at the same time.

**Severity reasoning for a11y:** a control that keyboard or screen-reader users *can't operate or identify* is a bug for those users, so it's `error` (JSX-003, JSX-004). Missing alt text, missing state announcements and link/button confusion degrade use without blocking it, so they're `warn`.

#### REACT-JSX-001 · Stable keys from the data
- **`error`:** index keys on lists that change move state, focus and input values to the wrong rows. That's a visible data bug, as react.dev's *Keeping list items in order with key* shows.
- **Random keys are covered too:** they remount every row each render, which is worse.
- **The Fragment example** covers the "several elements per item" case, where keys are most often forgotten.
- **Exception:** truly static, stateless lists, which react.dev allows.

#### REACT-JSX-002 · No number on the left of `&&`
- **`error`:** a stray `0` rendered in the UI is a visible bug, and react.dev's pitfall in *Logical AND operator* is the source.
- **`.length &&`** is the most common form, so it's the first ❌ line.

#### REACT-JSX-003 · `<button>` for actions
- **`error`:** a `<div onClick>` is unusable by keyboard (WCAG 2.1.1) and unidentifiable by screen readers (4.1.2).
- **The ✅ example** adds `type="button"` (JSX-006) and an `aria-label` for the icon-only content (JSX-005), so it satisfies every related rule at once.

#### REACT-JSX-004 · Accessible labels for form controls
- **`error`:** an unlabelled input fails WCAG 1.3.1 and 4.1.2 and is unusable with a screen reader.
- **Placeholders aren't labels:** they're the usual "label" in generated code, so they're called out explicitly.
- **`useId` for ids:** it's SSR-safe and unique. The T3 eval's output already used this pattern.

#### REACT-JSX-005 · `alt` text
- **`warn`:** informative images without `alt` lose information, but the page stays operable.
- **`alt=""` for decorative images:** inventing an `alt` for decoration adds screen-reader noise.
- **Icon-only buttons** get the label on the button and `alt=""` on the icon. That's the combination jsx-a11y and WCAG 1.1.1 recommend.

#### REACT-JSX-006 · `type="button"` for non-submit buttons
- **`warn`:** an accidental submit is a real bug, but it only happens inside forms, and an explicit `type` fixes it everywhere. It matters more with React 19 form actions, where an accidental submit runs a Server Action.

#### REACT-JSX-007 · Pass handlers, don't call them
- **`error`:** `onClick={remove(id)}` runs during render, so the action fires on every render, and can loop through `setState`. This is react.dev's pitfall in *Adding event handlers*.
- **Exception:** handler factories that return a function are valid. The rule says so, to avoid false positives.

#### REACT-JSX-008 · Links navigate, buttons act
- **`warn`:** both directions work with a mouse but break keyboard behaviour, open-in-new-tab and screen-reader expectations (APG link pattern, jsx-a11y `anchor-is-valid`).
- **Exception:** navigating after an action is still a button.

#### REACT-JSX-009 · Announce disclosure and toggle state
- **`warn`:** without `aria-expanded`/`aria-pressed`, the widget works but its state is invisible to screen readers (APG disclosure pattern, WCAG 4.1.2).
- **Exception:** native `<details>`, and the project's accessible UI library, already handle it.

#### REACT-JSX-010 · Heavy logic out of JSX
- **`info`:** readability only. react.dev shows the *assign JSX to a variable* pattern without prescribing it.

#### REACT-JSX-011 · Item-specific names for repeated row actions
- **Found in T21:** `write-list-filter` scored 0.88. Its output labelled every control and named the delete button after the task, but the expand button was just "Show notes" in every row, and the `labelled-controls` judge failed it (3/3). No rule said this: JSX-003 showed an item-specific name only for an icon-only button, and JSX-009's ✅ example uses a bare "Details". So the skill was fixed, not the grader.
- **`warn`, not `error`:** the control works and has a name. The defect is ambiguity between identical names (WCAG 2.4.6), which hurts but doesn't block use.
- **"Starts with the visible text":** an `aria-label` that drops the visible words breaks voice control (WCAG 2.5.3). Prefixing keeps both working.

### React 19 Actions (`REACT-ACT`, `references/actions.md`)

**Why a separate domain:** Actions are the largest new API surface in React 19 (`useActionState`, `useOptimistic`, `useFormStatus`, `<form action>`, async transitions). Their misuse modes are new: wrong argument order, a hook outside its form, optimistic updates outside a transition. Mixing them into `HOOK` or `FORM` would hide the version gate.

**Verification:** the ✅ examples compile against React 19.3 types. The React 18 fallback (ACT-005) compiles against React 18 types. A negative control confirmed that React 18's types have no `useActionState` (TS2305), which is exactly the failure ACT-005 prevents.

#### REACT-ACT-001 · `useActionState` for result, error and pending state
- **`warn`:** hand-rolled pending state works for one submission. Its real defect is ordering on repeated submits, which `useActionState` solves by queuing (*How useActionState queuing works*).
- **Exceptions:** React Hook Form forms keep RHF's own state (T13 decides how the two combine). React 18 uses the ACT-005 pattern.

#### REACT-ACT-002 · `(previousState, formData)` argument order
- **`error`:** the wrong order throws or reads `undefined`. It's a documented troubleshooting entry (*My action can no longer read the submitted form data*), and the most likely bug when converting a form action into a `useActionState` action.

#### REACT-ACT-003 · `useFormStatus` inside the form
- **`error`:** in the form's own component, `pending` is always `false`, so the pending UI silently never appears. The documented fix (a child component) is the ✅ example.

#### REACT-ACT-004 · Optimistic updates only inside an action or transition
- **`error`:** outside a transition, React raises an error and the value doesn't revert, so a failed request leaves wrong UI. The ✅ example uses a reducer-style updater (`delta`) so the setter takes a meaningful argument, and keeps the real `count` as the source of truth.

#### REACT-ACT-005 · React 18: no function `action` props or Action hooks
- **`error`:** on 18, a function `action` doesn't run (the browser submits normally) and the hooks don't exist. This is the React 19 → 18 counterpart of COMP-008, and the target of the version eval.
- **The ✅ fallback** guards pending state with a call counter, so an earlier response can't clear a later submission's pending flag. That's the same ordering problem ACT-001 solves on 19.

#### REACT-ACT-006 · Re-wrap state updates after `await`
- **`warn`:** without it the update still happens, but outside the transition. This is a documented caveat (*React doesn't treat my state update after await as a Transition*).

#### REACT-ACT-007 · Preserve input on failed actions
- **`warn`:** losing the user's input on a validation error is a real usability bug, but not a data bug. The ✅ example returns the values in the state and re-keys the field, so its `defaultValue` applies after the automatic reset.

### State (`REACT-STATE`, `references/state.md`)

**The "where does state live" ladder** opens the file, because the most consequential state decision is the *location*, not the library. The order (derived → local → lifted → URL → server cache → context → store) follows react.dev's *Choosing the State Structure* and *Sharing State Between Components*, and the Redux style guide's *Evaluate where each piece of state should live*. Global stores come last on purpose.

**Versions checked:** Zustand 5.1.0, Redux Toolkit 2.15.0, React Redux 9.3.1. All ✅ examples compile against them with React 19 types. Zustand's docs moved to `/learn/…` and `/reference/…` paths, so the old `/docs/guides/…` URLs return 404. Every source here uses the current paths.

#### REACT-STATE-001 · Don't store what you can derive
- **`warn`:** a stored copy drifts, but usually visibly and fixably. It's backed by react.dev's *Avoid redundant state* and the Redux style guide's *Keep state minimal*.
- **The Zustand example** stores `total` next to `items`, the most common form in generated store code.

#### REACT-STATE-002 · Server data in a server cache
- **`warn`:** a hand-rolled fetch store works, but it re-implements caching, deduplication and invalidation. Backed by the Redux style guide (*Use RTK Query for data fetching*) and TanStack Query's *Does this replace client state?*.
- **Exception:** with no data library installed, a store is acceptable, because dependencies are never added unasked.

#### REACT-STATE-003 · Zustand: select slices
- **`warn`:** whole-store subscriptions cost re-renders, not correctness. Selecting is the pattern in Zustand's TypeScript guide.

#### REACT-STATE-004 · Zustand v5: `useShallow` for selectors that return new references
- **`error`:** in v5, a selector that returns a new object or array causes an infinite render loop ("Maximum update depth exceeded"). The v5 migration guide documents this under *Requiring stable selector outputs*, which was checked during T9. That makes it a crash, not a performance issue.
- **Applies:** `useShallow` exists from Zustand 4.4. In v4 the same pattern only over-renders, which the rule text states.

#### REACT-STATE-005 · Zustand: curried `create<T>()(…)`, actions in the store
- **`warn`:** the curried form is what Zustand's TypeScript guide documents for correct middleware inference. Colocated actions are its *recommended pattern*.
- **Exception:** Zustand also documents the "no store actions" pattern, so projects using it aren't flagged.

#### REACT-STATE-006 · Store per request under SSR
- **`error`:** a module-scope store on the server is shared across requests, so one user's data can leak to another. That's a data-leak bug, documented by both Zustand's Next.js guide and Redux's Next.js guide (*Creating a store per request*).
- **The ✅ example** uses the Redux guide's `useRef` lazy-init provider pattern, which is also allowed by REACT-COMP-003's lazy-ref exception.
- **Exception:** Vite SPAs, which have no server render.

#### REACT-STATE-007 · Redux: `createSlice`
- **`warn`:** hand-written reducers work. They're legacy, and the Redux style guide marks *Use Redux Toolkit* as Priority A.
- **The ✅ example** shows an Immer "mutation" (`state.items.push`), which is safe inside `createSlice`. It's listed in REACT-HOOK-006's exceptions so reviews don't flag it.

#### REACT-STATE-008 · Redux: typed hooks
- **`warn`:** untyped hooks lead to `any` or repeated annotations. `.withTypes<…>()` is the current pattern in the official TypeScript quick start (React Redux ≥ 9.1).

#### REACT-STATE-009 · Redux: serializable state and actions
- **`error`:** non-serializable values break DevTools, persistence and SSR hydration, and they're a Priority A *Essential* rule in the Redux style guide.

#### REACT-STATE-010 · URL-worthy state in the URL
- **`warn`:** local state for filters and pagination works until reload, share or back. The ✅ example also validates what it reads from the URL, since search params are user input.

### TanStack Query (`REACT-QUERY`, `references/tanstack-query.md`)

**Version checked:** `@tanstack/react-query` 5.x (npm latest 5.108). All ✅ examples compile against it with React 19 types. A negative control confirmed QUERY-005: v5's types reject `onSuccess` on `useQuery` (TS2769). Every source is a page in the official TanStack Query v5 guides, with anchors checked.

#### REACT-QUERY-001 · Every variable in the key
- **`error`:** a missing key variable shows data for the wrong parameters. That's a correctness bug, and the docs give it a dedicated section.

#### REACT-QUERY-002 · `queryOptions` / key factories
- **`warn`:** hand-written duplicate keys work until one drifts. The ❌ example shows the typical failure: a typo'd invalidation that never matches. `queryOptions` is a v5 API, hence the gate.

#### REACT-QUERY-003 · One `QueryClient`: not in render, not shared across requests
- **`error`, two failure modes:**
  - A client created in render gives an empty cache every render.
  - A module-scope client on the server leaks data between users.
- **Both follow the setup sections** of the official SSR guides, which show `useState(() => new QueryClient())` and the `getQueryClient()` helper.
- **Exception:** a fresh client per test, which is deliberate.

#### REACT-QUERY-004 · Don't copy query data into state
- **`warn`:** the same redundant-state reasoning as REACT-STATE-001 and REACT-EFF-001, applied to the server cache.
- **`select`** is the idiomatic way to derive.
- **Exception:** seeding an editable draft, keyed by id so it resets per entity.

#### REACT-QUERY-005 · v5: no query callbacks
- **`error`:** in JavaScript they silently don't run; in TypeScript they don't compile (confirmed). The ✅ example shows the two documented replacements: derive from `data`, and use global `QueryCache` callbacks.
- **Exception:** mutations keep their callbacks, so they aren't flagged.

#### REACT-QUERY-006 · Invalidate or update after mutations
- **`error`:** without invalidation, the UI shows stale data after the user's own change, which is a visible correctness bug (*Invalidations from Mutations*).

#### REACT-QUERY-007 · Optimistic cache updates: cancel, snapshot, roll back
- **`error`:** skipping `cancelQueries` lets an older response overwrite the optimistic value, and skipping the rollback leaves wrong data after a failure.
- **The ✅ example** returns the key in the context, so rollback and invalidation use exactly the key that was written.
- **The rule also points to the simpler "via the UI" approach**, which needs no rollback.

#### REACT-QUERY-008 · Key + `enabled`, not effects + `refetch()`
- **`warn`:** the effect pattern refetches the old key and races. It's the query-specific form of REACT-EFF-005/HOOK-003.
- **The `!` in the ✅ example** is the documented dependent-query pattern, safe because `enabled` guarantees the value. This is the "check the compiler can't follow" exception in REACT-TS-002.

#### REACT-QUERY-009 · v5 names
- **`warn`:** old names fail to compile, or change meaning. `isLoading` in v5 is `isPending && isFetching`, so guarding on it lets `undefined` data through. The ✅ example narrows with `isPending`, then `isError`, so `data` is typed as defined.
- **Gated to v5,** so v4 code isn't flagged.

#### REACT-QUERY-010 · Pass the `signal`
- **`info`:** an optimization. The docs describe it under *Query Cancellation* as opt-in.

#### REACT-QUERY-011 · SSR: prefetch + `HydrationBoundary` + `staleTime` > 0
- **`warn`:** without it the page works, but shows avoidable spinners and double-fetches. The advanced SSR guide recommends this whole setup, including a non-zero default `staleTime`.
- **Next.js App Router specifics** (where providers live, streaming) are added in `nextjs.md` (T14) and cross-referenced.

### React Router (`REACT-RR`, `references/react-router.md`)

**Docs checked in T11** (reactrouter.com, latest = 8.5.2; npm peer dependencies):
- **v8 requires `react`/`react-dom` ≥ 19.2.7** and Node ≥ 22.22. It removes `react-router-dom`: everything comes from `react-router`, and DOM APIs come from `react-router/dom`. It also turns the v7 future flags on by default (middleware, split route modules, and others).
- **Peer dependencies match:** the npm peer range of every v8.x is `react >=19.2.7`. The SKILL.md version table and D6 were corrected from "React 19" to "React 19.2.7".
- **Examples compile** against `react-router` 8.5.2 and React 19 types.
- **Framework mode** gets no rules of its own, per D6. The detection table points it to the core rules plus the library-mode rules that apply.

#### REACT-RR-001 · Loaders, not component effects
- **`warn`:** an effect fetch in a route works (and REACT-EFF-005 covers the race at `error`). The loader version removes waterfalls and loading flashes. It's the documented data-mode pattern.
- **Exception:** declarative mode has no loaders, so the rule points to the data layer or the race-safe effect.

#### REACT-RR-002 · Params are untrusted strings
- **`warn` here:** the client-side consequence is usually a broken page. The server-side and security consequences are covered at `error` in `SEC`/`NEXT`.
- **The ✅ example** validates the id's shape, encodes it, and throws `data(…, { status: 404 })` so the route's error boundary renders a proper 404.

#### REACT-RR-003 · `<Link>`, not `<a href>`
- **`warn`:** a full reload works but throws away client state and the router's data flow. `NavLink` is shown for navigation menus, since it sets `aria-current`.

#### REACT-RR-004 · No `navigate()` during render
- **`error`:** it's a side effect during render (REACT-COMP-003): React warns about it, it runs twice under StrictMode, and it can loop.
- **Two replacements:** `redirect()` in a loader for data mode (it happens before render), and `<Navigate>` for declarative mode.

#### REACT-RR-005 · Validate redirect targets
- **`error`:** an open redirect is a security bug (OWASP *Unvalidated Redirects and Forwards*).
- **`safeRedirect` blocks the common bypasses:** it accepts only paths starting with a single `/`, and rejects `//evil.example` (protocol-relative) and backslash variants (`/\evil.example`, which some browsers normalize to `//`).
- **Cross-framework:** this rule is React Router's instance. `security.md` (T16) holds the general rule and links here.

#### REACT-RR-006 · An error boundary on the route tree
- **`warn`:** without one, users see the developer error screen. Failures still happen either way; the boundary makes them presentable. Documented in *Error Boundaries → Data mode*.

#### REACT-RR-007 · v8 imports
- **`error` on v8:** `react-router-dom` no longer exists in v8, so its imports fail to resolve (upgrade guide, *react-router-dom*).
- **Gated:** on v7, `react-router-dom` is a working re-export. The `review-rr-v7-clean` control (React 18 + v7 + `react-router-dom`) checks that this rule isn't applied there, which is the T11 acceptance check that a React 18 fixture gets no v8-only advice.

#### REACT-RR-008 · Mutations through actions
- **`warn`:** hand-rolled submits work, but skip the automatic loader revalidation, so the page shows stale data until reload.
- **Exception:** React Hook Form forms submit through `useSubmit`/`fetcher.submit`.

#### REACT-RR-009 · `lazy` routes
- **`info`:** code splitting is an optimization, and the route object's `lazy` is the documented mechanism.

### TanStack Router (`REACT-TSR`, `references/tanstack-router.md`)

**Docs checked in T12** (tanstack.com/router, latest; npm `@tanstack/react-router` 1.170.46):
- **Setup:** the Vite plugin is the documented setup for file-based routing on Vite, and the CLI is for other bundlers (see A15).
- **Search params:** `validateSearch` accepts a Standard Schema such as Zod directly. The docs recommend `.catch()` so malformed params fall back rather than erroring.
- **Old paths:** the old `/router/latest/docs/framework/react/…` URLs now redirect (307) to `/router/latest/docs/…`, so sources use the new paths.

**Verification against a real route tree:** the examples were type-checked in a scratch project with file routes, a tree generated by `@tanstack/router-cli`, and router type registration. This caught a real error in the first draft of TSR-009: in 1.170, `errorComponent` receives `error: unknown`, so `error.message` doesn't compile. The example now narrows with `instanceof Error`. After the fix: exit 0.

#### REACT-TSR-001 · Never hand-edit `routeTree.gen.ts`
- **`warn`:** an edit is overwritten on the next change, so it's lost work and desynced types rather than shipped breakage. It's also a SKILL.md red flag (A15).

#### REACT-TSR-002 · Register the router type
- **`warn`:** without registration, everything still runs, but every link and hook loses type checking. That's the main reason to use TanStack Router at all. The `Register` augmentation is the documented pattern (*Type Safety*).

#### REACT-TSR-003 · `validateSearch`
- **`warn`:** consistent with REACT-RR-002. Unvalidated search params break pages on the client, and the security consequences are handled server-side in `SEC`.
- **`.catch()` over `.default()`:** malformed params fall back instead of rendering an error page. This follows the docs' stated reasoning.

#### REACT-TSR-004 · Search params in loaders go through `loaderDeps`
- **`error`:** without `loaderDeps`, the router caches one loader result per path, so a different `?page=` shows the previous page's data. That's a correctness bug, documented under *Using loaderDeps to access search params*.

#### REACT-TSR-005 · Typed links: `to` + `params` + `search`
- **`warn`:** template-string paths work at runtime. They lose route checking and parameter encoding, which can break silently after a route rename.

#### REACT-TSR-006 · Auth in `beforeLoad`
- **`warn`:** a component-level check flashes protected UI and starts child loaders. `beforeLoad` + `throw redirect` is the documented pattern.
- **UX, not security:** the rule says so, and cross-references REACT-RR-005 for validating the `redirect` value, since the same open-redirect risk applies.

#### REACT-TSR-007 · Query integration: `ensureQueryData` + `useSuspenseQuery`
- **`warn`:** two caches that disagree is a maintainability and staleness problem. The documented integration (*External Data Loading*, *TanStack Query integration*) keeps one cache.
- **`useSuspenseQuery`** means `data` is never `undefined` in the component, which removes the need for non-null assertions.

#### REACT-TSR-008 · Route-bound hooks
- **`warn`:** `strict: false` gives loose unions and hides mistakes. `getRouteApi` is the documented way to get typed hooks in a different file (*Fixing the component context problem*).

#### REACT-TSR-009 · `notFound()` plus error and pending UI
- **`warn`:** returning `null` pushes "not found" handling into every component. `notFound()` and the route components are the documented mechanism.

### Forms (`REACT-FORM`, `references/forms.md`)

**Versions checked:** `react-hook-form` 7.92.0, `@hookform/resolvers` 5.9.2 and `zod` 4.6.7. All ✅ examples compile against them with React 19 types. Zod 4 changes were checked against the official v4 changelog.

**Framing:** the file opens with "one schema, two places". The most damaging form bug, trusting client validation, is a server-side omission that a client-only rule set would never catch.

#### REACT-FORM-001 · Schema resolver + `z.infer`
- **`warn`:** inline rules and a hand-written interface work until they drift. The resolver pattern is RHF's documented *Schema Validation*, and `z.infer` is Zod's.
- **Exception:** no schema library installed. Dependencies are never added unasked.

#### REACT-FORM-002 · Server re-validation with the same schema
- **`error`:** missing server validation is a security bug. OWASP's input validation guidance requires server-side validation, because client checks can be bypassed.
- **The ✅ example** takes `unknown` (not the client type), uses `safeParse`, returns field errors, and writes only the parsed fields. It also hashes the password, so the example never models storing a raw secret.

#### REACT-FORM-003 · `register` vs `Controller`
- **`warn`:** spreading `register` on a component without the ref and change contract silently loses the value. That's a bug, but a visible one in testing. RHF documents both paths (*Integrating Controlled Inputs*).
- **Exception:** library inputs that forward refs work with `register`.

#### REACT-FORM-004 · Accessible error wiring
- **`warn`:** consistent with the JSX accessibility severities. Errors that aren't announced degrade the form without blocking it.
- **Sources agree:** RHF's own *Handle errors* example uses `aria-invalid` + `role="alert"` (checked in T13), and WCAG 3.3.1 requires identifying the field in error.
- **`aria-describedby`** is added so the message is read with the field, not just announced once.

#### REACT-FORM-005 · `useWatch` for specific fields
- **`warn`:** whole-form `watch()` costs re-renders, not correctness. The RHF `watch` docs and `useWatch` describe the isolation pattern.

#### REACT-FORM-006 · Default values; `values`/`reset` for async data
- **`warn`:** missing defaults break `isDirty` and `reset`, and cause controlled/uncontrolled warnings. A `setValue` loop in an effect is also an EFF anti-pattern.
- **`values`** is the documented fix (*Fields stay empty after data loads from an API*), gated to ≥ 7.41.

#### REACT-FORM-007 · `field.id` keys in field arrays
- **`error`:** the same bug class as REACT-JSX-001: values and errors move between rows. RHF's `useFieldArray` rules require the generated `id` as the key.

#### REACT-FORM-008 · Coerce number and date inputs
- **`error`:** with a `z.number()` schema every submission fails, and without one arithmetic silently concatenates strings. That's a correctness bug, documented as *A number input is submitted as a string*.
- **Two fixes are given:** `valueAsNumber` on the client, and `z.coerce.number()` when the same schema also parses `FormData` on the server, where everything is a string.
- **Exception:** string-shaped numbers (phones, postcodes) must not be coerced.

#### REACT-FORM-009 · Zod 4 APIs in Zod 4 projects
- **`info`:** deprecated v3 forms still work in v4 with warnings. The rule mostly prevents the reverse mistake, v4-only functions in a v3 project, so it's gated and kept low.

### Next.js rendering (`REACT-NEXT-001…012`, `references/nextjs.md`)

**Docs checked in T14** (nextjs.org, Next 16.4.6 on npm; *Upgrading to Version 16*):
- **Async request APIs:** sync access to `params`, `searchParams`, `cookies()`, `headers()` and `draftMode()` was **removed in 16**. 15 introduced the async APIs with temporary sync compatibility.
- **`proxy.ts`** replaces the deprecated `middleware.ts`. It runs on Node.js only; Edge users keep `middleware`.
- **`revalidateTag`** now requires a cache-life profile, and there's a new `updateTag` for read-your-writes in Server Actions (T15).
- **`cacheComponents: true`** replaces `experimental.dynamicIO`, `useCache` and PPR. Enabling it "is not a rename-only change".
- **`reactCompiler`** is stable and off by default, which matches SKILL.md's compiler detection (A14).

**Verification:** the ✅ examples were type-checked in a scratch Next 16.4.6 project (real `app/` files, `next/headers`, `next/cache` `cacheLife`/`cacheTag`, `next/image`, `next/link`, `generateMetadata`, `error.tsx`), exit 0. One anchor check failed transiently and passed on re-run; the anchor exists in the page HTML.

**Numbering:** the `NEXT` domain spans two files (A13). Rendering rules are 001–012, and the server-side rules in `nextjs-server.md` start at 101, so each file can grow without interleaving ids.

#### REACT-NEXT-001 · Server pages and layouts; `'use client'` on leaves
- **`warn`:** a client page works. It costs bundle size and server-side data fetching (*Reducing JS bundle size*).
- **Exception:** context providers, documented under *Context providers*.

#### REACT-NEXT-002 · Serializable server→client props
- **`error`:** functions and class instances can't cross the boundary, and fail at build or render time.
- **Exception:** Server Actions, which may be passed.
- **The security half** (passing only the fields the client needs, never secrets) is in `nextjs-server.md` (T15), where data-exposure rules live.

#### REACT-NEXT-003 · Fetch in Server Components
- **`warn`:** it's the App Router form of REACT-EFF-005 and REACT-RR-001.
- **Exception:** user-driven client data goes through TanStack Query.

#### REACT-NEXT-004 · Await request-time APIs
- **`error` on 15+:** un-awaited access gives `undefined`, or fails to compile, and 16 removed the sync fallback entirely.
- **Gated:** 14 is synchronous, so it isn't flagged there.
- **The ✅ example** also mentions the `PageProps` helper from `next typegen` (15.5+), per the upgrade guide.

#### REACT-NEXT-005 · No browser-only values during render
- **`error`:** it throws on the server (`localStorage` is undefined), or causes hydration mismatches. Next's hydration-error doc lists these exact causes, and the effect-based fix.
- **Exception:** `suppressHydrationWarning` is documented for expected differences.

#### REACT-NEXT-006 · No per-request data in module scope
- **`error`:** a cross-request data leak. This is the Next.js instance of REACT-STATE-006 and REACT-QUERY-003.
- **The ✅ example** uses `React.cache()` (*Reusing data with React.cache*), the documented per-request memoization. The *Data Security* guide's data-access-layer pattern builds on it.

#### REACT-NEXT-007 · Parallel fetches and streaming
- **`warn`:** waterfalls and blocking slow sections are performance problems. Both fixes are documented (*Parallel data fetching*, *Streaming*).

#### REACT-NEXT-008 · Next 16 Cache Components
- **`warn`:** misplacing request-time APIs inside `"use cache"` is caught at build. The rule mainly guides correct structure: read outside, pass in, wrap in `Suspense`.
- **Exception:** don't enable `cacheComponents` unasked. The upgrade guide warns it can surface build errors across the app, which makes it a project-level decision, like adding a dependency.

#### REACT-NEXT-009 · `next/link`
- **`warn`:** the Next-specific form of REACT-RR-003. A full reload loses prefetching and client state.

#### REACT-NEXT-010 · `next/image`
- **`warn`:** unoptimized images cost performance and cause layout shift. `alt` is also required by REACT-JSX-005.
- **Exception:** hosts that can't be allow-listed.

#### REACT-NEXT-011 · `metadata` / `generateMetadata`
- **`warn`:** `next/head` doesn't work in `app/`, so tags silently don't appear. The documented API also merges metadata across layouts.

#### REACT-NEXT-012 · `error.tsx`, `notFound()`, `loading.tsx`
- **`warn`:** missing boundaries make failures uglier. It's the App Router form of REACT-COMP-010.
- **`error.tsx` must be a client component** (documented); getting that wrong is a build error.

### Next.js server side (`REACT-NEXT-101…111`, `references/nextjs-server.md`)

**Framing:** the file opens with the model that drives every rule here:
- Server Actions and route handlers are **public endpoints**.
- Anything passed to a client component or returned from an action is **sent to the browser**.

Most App Router security bugs come from forgetting one of those two facts.

**Docs checked in T15** (nextjs.org *Data Security*, *Authentication*, `use server` *Security considerations*, `redirect`, `proxy`, environment variables, `updateTag`/`revalidateTag`):
- `redirect()` "should be called outside the try block"
- layout auth checks don't re-run on navigation and don't stop child segments
- `NEXT_PUBLIC_*` values are inlined into the browser bundle at build time
- `proxy.ts` is Node-only, and Edge stays on `middleware.ts`.

**Verification:** the ✅ examples compile against Next 16.4.6 + Zod 4 in the scratch Next project (a Server Action file, a route handler, `proxy.ts`, a data-access layer). A negative control confirmed NEXT-110's claim: one-argument `revalidateTag` is a type error on 16 (TS2554).

#### REACT-NEXT-101 · Auth inside every Server Action
- **`error`:** an unauthenticated mutation is a security bug.
- **The ✅ example:** takes `unknown`, reads the session from cookies (never from a parameter, as the docs require), checks ownership, fails closed, and then revalidates with `updateTag`.
- **Exception:** public actions still validate input.

#### REACT-NEXT-102 · Runtime validation of action and handler input
- **`error`:** TypeScript types don't exist at runtime, so mass-assignment and type confusion are possible (*Validating client input*).
- **Relation to REACT-FORM-002:** that rule is the form-specific case. This one covers every action, including non-form ones such as the quantity update in the example. Reviews report the more specific one where both fit (`review.md`, calibration).
- **The ✅ example** scopes the update to the user's own cart in the `where` clause, so it authorizes and validates in one query.

#### REACT-NEXT-103 · DTOs for client props and action results
- **`error`:** whole records leak every field into the RSC payload, visible in DevTools. The docs' *Passing data from server to client* and *Controlling return values* sections are the source.
- **The ✅ example** uses a `select` plus an explicit mapped object, so fields can't leak by default.
- **Taint APIs** are mentioned only as a safety net, since they're experimental.

#### REACT-NEXT-104 · `import 'server-only'`
- **`warn`:** an accidental client import is often caught by a runtime error anyway. The marker turns it into a build error (*Preventing client-side execution of server-only code*, *Preventing environment poisoning*).
- **The `server-only` package** is the documented mechanism. Because it's a dependency, it's never added unasked.

#### REACT-NEXT-105 · No secrets in `NEXT_PUBLIC_`
- **`error`:** a leaked secret, inlined at build time and persisting in old bundles. The same applies to `VITE_*`, noted in **Applies** so SPA projects are covered too.
- **Exception:** publishable keys, which are public by design.

#### REACT-NEXT-106 · Route handlers validate and authorize
- **`error`:** the same reasoning as NEXT-101/102 for `route.ts`.
- **The ✅ example** returns 401/404 rather than leaking existence, and selects only the fields it returns.

#### REACT-NEXT-107 · `redirect()`/`notFound()` outside `try`/`catch`
- **`error`:** the redirect is silently swallowed and the code after it runs, a correctness bug documented under `redirect` → *Behavior*.
- **The ✅ example** moves the redirect after the `try`, keeping the result in a variable.

#### REACT-NEXT-108 · `proxy.ts` for optimistic checks only
- **`warn`:** the rename is a deprecation, not a breakage.
- **The security point:** proxy and middleware can't be the only gate, because matchers miss paths. The docs call proxy auth checks *optimistic* (*Optimistic checks with Proxy*).

#### REACT-NEXT-109 · Not layouts for auth
- **`error`:** the docs explicitly warn that layouts don't re-run on navigation and don't stop child segments from rendering into the RSC payload, so protected data can be fetched and sent.
- **The ✅ example** moves the check into the data-access layer.

#### REACT-NEXT-110 · Revalidate after mutations
- **`warn`:** stale UI after a save is a visible bug, but not a data or security one.
- **Version split:** `updateTag` (read-your-writes) and the two-argument `revalidateTag` on 16, the one-argument form on 15.

#### REACT-NEXT-111 · Server-set `httpOnly`/`secure`/`sameSite` session cookies
- **`error`:** a JS-readable or insecure session token is exploitable through XSS or CSRF. The options match the docs' *Setting cookies (recommended options)*.
- **The general cookie rule** in `security.md` (T16) points here, rather than repeating it.

### Security (`REACT-SEC`, `references/security.md`)

**Scope:** cross-cutting rules only. Where a framework domain already has the specific form (Next.js Server Actions and route handlers, React Router redirects, form re-validation, SSR state leaks), `security.md` links to it instead of repeating it, and each rule's text names the specific rule.
- **Why one problem keeps one id:** reviews report it once, at the most specific rule (`review.md`, calibration), and the catalog stays small.
- **Enforced mechanically:** `check_catalog.py` gained a duplicate-title check in T16 (case- and punctuation-insensitive).

**Sources:**
- OWASP cheat sheets (XSS, DOM XSS, redirects, authorization, SSRF, HTML5 storage, CSRF), react.dev, and the Vite and Next.js env docs. Anchors checked, 0 misses.
- **No claim about React blocking `javascript:` URLs:** react.dev's common-components page doesn't document one, so SEC-002 doesn't rely on framework behaviour.
- **Vite's docs** state that `VITE_*` values "will be exposed in client-side source code".

**Verification:** the ✅ examples compile in the scratch Next 16 project, with DOMPurify 3 for the sanitizer case. DOMPurify is only an example of a sanitizer "already in the project"; the rule never adds one.

#### REACT-SEC-001 · No untrusted content in `dangerouslySetInnerHTML`
- **`error`:** stored or reflected XSS.
- **Two ✅ forms:** text by default, and a sanitizer *only if the project has one or the user approves it*. That keeps "never add dependencies" intact. The trap eval `write-trap-user-html` checks this behaviour.

#### REACT-SEC-002 · Validate URL schemes
- **`error`:** `javascript:`/`data:` URLs run script on click (OWASP *URL contexts*, DOM XSS rule 5).
- **The ✅ helper** parses with `new URL()` and allow-lists `http(s):`, and falls back to text for invalid values.

#### REACT-SEC-003 · Same-site redirects, in every router
- **`error`:** an open redirect. The general rule; React Router's instance is REACT-RR-005, which owns the `safeRedirect` helper. The example shows the Next.js Server Action form, which the router rules don't cover.

#### REACT-SEC-004 · No secrets in client code or client-exposed env
- **`error`:** a leaked credential. The general form of REACT-NEXT-105, covering Vite and any bundler.
- **The ✅ example** moves the call behind the app's own server endpoint. This is also the target behaviour of the `write-trap-client-secret` eval.

#### REACT-SEC-005 · Client guards are UX; the server authorizes
- **`error`:** broken access control, OWASP's top web risk. The OWASP authorization cheat sheet requires checks on every request, in the right place.
- **Relation to other rules:** it generalizes REACT-TSR-006's "UX only" note, REACT-NEXT-108's optimistic proxy checks, and REACT-NEXT-109.

#### REACT-SEC-006 · No SSRF
- **`error`:** a server fetching attacker-chosen URLs can reach internal services and cloud metadata.
- **The ✅ example** allow-lists hosts (OWASP *Case 1*), requires `https:`, and sets `redirect: 'error'`, so an allowed host can't bounce the request elsewhere.

#### REACT-SEC-007 · Never evaluate user input as code
- **`error`:** code injection. OWASP DOM XSS rule 3 covers the JavaScript execution context.
- **The ✅ pattern** replaces evaluation with a lookup table keyed by a validated enum.

#### REACT-SEC-008 · No session tokens in `localStorage`
- **`warn`, not `error`:** storage isn't itself a vulnerability. It turns any XSS into token theft (OWASP HTML5 *Local Storage*). Some architectures genuinely use bearer tokens, so the rule gives the in-memory, short-lifetime alternative.

#### REACT-SEC-009 · No state changes on GET; CSRF for cookie-authenticated endpoints
- **`warn`:** `sameSite=lax` cookies already block many CSRF vectors in modern browsers. The rule covers what remains: GET mutations, and endpoints without an origin check.
- **Next.js:** Server Actions get POST-only plus an Origin/Host comparison built in (*Built-in Server Actions security features*). Route handlers don't, which is why the example is a route handler.

### Performance (`REACT-PERF`, `references/performance.md`)

**Severity stance:** most performance rules are `info` or `warn`. Performance problems rarely produce wrong behaviour, and react.dev's own guidance is "measure first" (*How to tell if a calculation is expensive*). No PERF rule is `error`.

**Verification:** anchors checked, 0 misses. The ✅ examples compile against React 19 types, with `@tanstack/react-virtual` 3 and `lodash` 4 used only for the "library already in the project" examples.

#### REACT-PERF-001 · Compiler on: no new manual memoization
- **`info`:** redundant memoization is noise, not a bug. The `review-perf-compiler` eval checks that a review reports it **only** as `info` and never blocks on it, which is this task's acceptance criterion.
- **Exception:** effect dependencies, per react.dev's escape-hatch note.

#### REACT-PERF-002 · Compiler off: memoize for measured cost or identity
- **`info`:** blanket memoization is harmless but wasteful. react.dev's *Should you add useMemo everywhere?* and *Should you add memo everywhere?* describe when it helps. Project convention wins.

#### REACT-PERF-003 · No expensive recomputation on unrelated re-renders
- **`warn`:** the inverse of PERF-002. Genuinely expensive work in a hot component causes visible lag (*Skipping expensive recalculations*). It's automatic with the compiler, hence the gate.

#### REACT-PERF-004 · `useDeferredValue` / `useTransition` for input-driven heavy renders
- **`warn`:** input lag is a user-visible problem with a documented fix.
- **The exception separates network-bound search**, where deferral doesn't help and caching or debouncing does.

#### REACT-PERF-005 · Code splitting
- **`warn`:** shipping heavy, rarely used code to everyone delays interactivity.
- **The rule requires `lazy` at module scope:** react.dev's troubleshooting notes that `lazy` inside a component resets state.

#### REACT-PERF-006 · Virtualize long lists, with an existing virtualizer
- **`info`:** the fix usually means a library, and dependencies are never added unasked. So the rule suggests one, or pagination, unless the project already has it.
- **Source:** TanStack Virtual's docs, the official docs of the library used in the example.

#### REACT-PERF-007 · Stable props for memoized children
- **`info`:** it only matters when the child is memoized for a reason (*Minimizing props changes*). It's irrelevant with the compiler.

#### REACT-PERF-008 · Import only what you use from large libraries
- **`info`:** the impact depends on the bundler's tree-shaking. Next's `optimizePackageImports` is cited as the framework-level mitigation.

### Testing (`REACT-TEST`, `references/testing.md`)

**Docs checked in T18:**
- **Versions:** Vitest 5.1.1, `@testing-library/react` 16.3.3, `@testing-library/user-event` 14, MSW 3.0.7.
- **MSW 3** (official *2.x → 3.x* migration guide):
  - handlers moved to designated entry points (`http`/`HttpResponse` from `msw/http`); the Node server is from `msw/node`
  - **`onUnhandledRequest` was renamed to `onUnhandledFrame`**
  - Node ≥ 22.
- **Next.js Vitest guide:** Vitest doesn't support async Server Components; use E2E for them.
- **RTL docs:** recommend importing `act` from `@testing-library/react` rather than `react`.

**Verification caught a real error:** the first draft's MSW setup used `server.listen({ onUnhandledRequest: 'error' })`. Against MSW 3.0.7's types that's TS2353, because the option no longer exists. The types and the migration guide both point to `onUnhandledFrame`. A second draft error was corrected before checking: it advised importing `act` from `react`, which contradicts RTL's own recommendation. After the fixes, the examples compile against Vitest 5, RTL 16, user-event 14, MSW 3, TanStack Query 5 and React Router 8, exit 0.

**Severity stance:** testing rules protect test *quality*. Bad tests are flaky or brittle, but they don't ship bugs to users directly, so no TEST rule is `error`.

#### REACT-TEST-001 · Accessible queries first
- **`warn`:** Testing Library's documented query priority. Role and label queries also exercise accessibility.

#### REACT-TEST-002 · `user-event` over `fireEvent`
- **`warn`:** `fireEvent` passes on interactions a user couldn't perform (*Differences from fireEvent*). `setup()` + `await` is the v14 API.

#### REACT-TEST-003 · `findBy*`/`waitFor`, no sleeps
- **`warn`:** sleeps are flaky in both directions.
- **Exception:** fake timers, with user-event's `advanceTimers` integration, for timer-driven code.

#### REACT-TEST-004 · Behaviour, not implementation
- **`warn`:** Testing Library's guiding principles.
- **Exceptions:** `renderHook` for hooks, where the hook *is* the unit, and callback props, which are a component's public interface. Both are listed so reviews don't flag legitimate tests.

#### REACT-TEST-005 · MSW over `fetch` stubs
- **`warn`:** fetch stubs couple tests to the HTTP client.
- **Gated to projects that already have MSW;** it's never added unasked. The v3/v2 entry points are both shown, so v2 projects aren't told to use v3 imports.

#### REACT-TEST-006 · Isolation: fresh client and stores, reset handlers, fail on unhandled requests
- **`warn`:** shared state between tests causes order-dependent failures. TanStack Query's testing guide (*Turn off retries*) and MSW's `listen` docs back the setup shown.
- **The MSW 3 rename is shown inline,** with the v2 equivalent in a comment.

#### REACT-TEST-007 · Real test routers
- **`warn`:** mocking router hooks hides navigation and loader behaviour.
- **Per router:** `createRoutesStub` is React Router's documented data-mode test helper. TanStack Router and Next.js have their equivalents named in the rule.

#### REACT-TEST-008 · Next.js: unit-test what's unit-testable; E2E for async Server Components
- **`info`:** it guides test strategy. The Next.js Vitest guide's statement is the source.

#### REACT-TEST-009 · No manual `act()` around RTL calls
- **`info`:** redundant wrapping is noise that hides the real cause of act warnings.
- **Two documented facts:** RTL recommends its own `act` re-export, and React 19 removed `react-dom/test-utils`.

#### REACT-TEST-010 · RTL `cleanup` without a global `afterEach`
- **Found by running, not by grading:** in T18 the `write-tested-component` output scored 1.00 on every grader, but when actually run under Vitest 5 + jsdom, 3 of 4 tests failed with "Found multiple elements". The scaffold, like many real Vitest setups, has no `globals: true`, so RTL's auto-cleanup never registers. Adding `afterEach(cleanup)` to the setup file made all 4 pass.
- **`warn`, not `error`:** the failure shows up immediately as a red test, not as a silent production bug, but it makes tests order-dependent and leaks memory.
- **Fix in the setup file, not via `globals: true`:** RTL documents both. One hook in the existing setup file is the smaller change. Turning on globals changes the project's test config and its ambient types (`vitest/globals`), which a test-writing task shouldn't do unasked.
- **Eval:** the grader `setup-cleanup` requires `cleanup` in `src/test/setup.ts`. Graders can't OR across files, so a correct per-test-file `afterEach(cleanup)` would fail it. This is accepted because the rule and the RTL docs both name the setup file, and the prompt points at `src/test/`.

---

## 6. Evaluation design

### Layers of verification
| Layer | Tool | What it proves | Model involved? |
|---|---|---|---|
| Manifests | `claude plugin validate . --strict` | The plugin and marketplace load | no |
| Catalog consistency | `tests/check_catalog.py` | Every rule follows the template and is in the index (same severity and file) and in this document | no |
| Sources | `tests/check_links.py`, plus an anchor check while each rule is written | Every source page resolves, and every cited `#anchor` exists | no (network) |
| Examples | scratch harnesses (React 19 and React 18 types, TS 7, `strict`) | The ✅ examples compile for the versions they claim | no |
| Generated code | scratch harnesses + TS 5.9 control, rebuilt from eval traces (A8) | Write-eval outputs compile, every generated file is in the program, and a planted error is caught | no (needs a kept eval run) |
| Behaviour | `claude plugin eval` (`evals/`) | The skills change what Claude produces | yes |

**Why deterministic checks first:** they're free, instant and never flaky, so the expensive evals only measure behaviour.

**Why an anchor check:** `check_links.py` only fetches pages. In T3, two cited anchors that looked plausible (`#typing-component-props` and `#useref` on react.dev's TypeScript page) turned out not to exist. A rule that links to the wrong section is weaker evidence, so anchors are checked whenever rules are written.

### Eval case families
- **`write-*`:**
  - A realistic request with **pinned output paths**. A scaffold creates a minimal project (`package.json` with real version ranges, `tsconfig`, Vite config), so version and project-type detection have something real to read. There are no `node_modules`, so the project's own checks can't run.
  - Graded with:
    - regexes over the produced files (required API present, anti-pattern absent)
    - `llm` checks for semantics a regex can't see (a stable provider value, no nested components)
    - an `llm` check that the final report doesn't claim unrun checks passed
    - `tool_used: Skill`.
- **`review-*`:** a scaffold seeds files with known violations. Graders check:
  - the seeded rule ids
  - the verdict
  - safety: no `Write`/`Edit`.

### First cases (T3)
- **`write-component-context`** is a React 19 SPA with no compiler. It exercises:
  - TS-006: `null` default plus a throwing guard hook
  - COMP-006: a stable provider value
  - COMP-007: ref as a prop, so no `forwardRef` on 19
  - COMP-011: no `defaultProps`
  - COMP-001: no nested components
  - an honest report.
- **`review-components`** is a plain-language review of three files seeded with COMP-001, COMP-002, COMP-011 and TS-006, one of each kind:
  - a remount bug
  - a parent-data mutation
  - a silently ignored default
  - a runtime crash hidden by a cast.

### Review command cases (T4–T5)
- **Deterministic repos:** the scaffolds use a fixed author, committer and dates, so the hashes are reproducible (`5b5d937` root → `cab60c5`), and prompts can name them.
- **Cases:**
  - `review-clean-tree`
  - `review-commit-hash` (finds COMP-011, Request changes, a `diff` proposal)
  - `review-root-commit` (Approve, no `[error]`, which doubles as a false-positive guard)
  - `review-uncommitted` (staged, unstaged and untracked together; finds COMP-001, COMP-002 and TS-002; the scope names the untracked file)
  - `review-invalid-arg`
  - `review-precheck-no-repo`
- **Safety graders on every case:**
  - no `Write`/`Edit`
  - no write-capable git subcommand
  - no `--output`
  - no redirection.
- **These need Bash.** The development environment's eval sandbox refuses Bash (plan R1, credentials-file EACCES), so they were verified with headless runs. Each run's output was graded with the case's own regex graders by a scratch script, and git state was hashed before and after. The cases stay in the suite for the user's full run.

### Clean controls
Three fixtures of correct code, which must come back **Approve** with no `[error]`. They guard against false positives (plan R4, SPEC: 3 controls).
- **`review-clean-control-components`:** idiomatic React 19 (a guard-hook context with a memoized value, ref as a prop, `useId` labels, `toSorted`, stable keys). It type-checks in the React 19 harness.
- **`review-rr-v7-clean`:** React 18 + React Router v7 with `react-router-dom` and `forwardRef`. Both are correct *for that version*, so RR-007 and COMP-007 must not be raised. This tests version gating in reviews.
- **`review-perf-compiler`:** React Compiler enabled, with manual `useMemo`/`useCallback`/`memo` everywhere. It must mention the compiler and report PERF-001 at `info` only, never `warn` or `error`.

### The final suite (T21): 52 cases
| Family | Cases | What they cover |
|---|---|---|
| `write-*` | 19 | One or more per domain. Traps (user HTML, client secret, effect fetch) must produce the safe variant plus an explanation. Version cases (React 18 / 19) must not use an API above the detected version. The monorepo case (R6) must pick the right project type. Testing cases need a test setup (or an offer, not an install). |
| `review-*`, plain language | 15 | Seeded fixtures per domain plus the 3 clean controls. They need only read tools. |
| `review-*`, command | 6 | `/react-power-up:review`: clean tree, commit hash, root commit, uncommitted changes, invalid argument, not a repo. They need `--allow-tools Bash`. |
| `trigger-*` | 12 | 6 positive and 6 negative prompts (Vue, Nuxt, Svelte, Angular, React Native, Python). |

**Coexistence** with vue-power-up can't be an eval case, because `claude plugin eval` loads one plugin. It's the script `tests/coexistence.sh` (A16).

**Beyond graders:** since T18/T20, generated code is also rebuilt and checked outside the eval: type-checked (A8), and for `write-tested-component`, actually run with Vitest. Both found gaps the graders couldn't (REACT-TEST-010; the client-secret server file outside the tsconfig).

---

## 7. Known limitations

| Limitation | Why it's acceptable / mitigation |
|---|---|
| **Enforcement is guidance, not a hook** (D8). Claude can still deviate. | The user chose no hooks. Mitigated by the mandatory self-check step, the red flags, running the project's own checks when they're available, and the evals. A hook can be added later without changing the rules. |
| **`allowed-tools` pre-approves but doesn't restrict** (A6). | The argument is validated before use, write flags are forbidden in the skill text, and the command evals assert no write-capable git calls and no edits. |
| **The review command needs Bash permission and a POSIX shell** (precheck, A10). | Documented in README; Git Bash on Windows. Plain-language reviews need only read tools. |
| **Rule coverage is finite** (156 rules, 15 domains). | Reviews report non-catalog bugs as `GENERAL`. The catalog grows without renumbering (A4). |
| **Partial coverage** for Next.js Pages Router and React Router framework mode (noted-only project types), and none for React Native. | Stated in SKILL.md's project-type table: Claude says so and applies only the core rules. |
| **Version detection without `node_modules` or a lockfile uses the range minimum.** | That direction is safe: assuming *older* never produces code that fails to compile on the real install. |
| **Docs drift.** Next.js, React Router, TanStack and MSW change fast (e.g. MSW 3 renamed `onUnhandledRequest`). | Every rule has an Applies range and a source. `check_links.py` catches moved pages. Re-verify on each major release. |
| **Eval scores here are single runs** (D12). | The user's full run (3 runs, with and without the plugin) is authoritative and shows variance and the plugin's added value. |
| **Bash-granting evals couldn't run in the development sandbox** (credentials-file EACCES). A run that grants Bash is refused *as a whole*, so mixed runs fail too. | The 6 command cases were verified by hand with headless runs (T4/T5). Run them, or the whole suite with `--allow-tools Bash`, from a normal terminal. |
| **Regex graders check text, not behaviour.** T18 showed an output that scored 1.00 while its tests failed at runtime. | Generated code is also type-checked with a coverage check (A8), and the testing case was run with Vitest. `llm` graders judge only short final messages (A7). |
| **Some `llm` graders can vary between runs.** | Used only where a regex can't decide, with concrete PASS/FAIL criteria. |
| **Coexistence depends on the wording of both descriptions.** A framework-agnostic prompt ("a TanStack Query hook") fired neither skill until T19. | `tests/coexistence.sh` covers the known ambiguous prompts. Re-run it after changing either plugin's description. |
