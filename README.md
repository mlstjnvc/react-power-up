# react-power-up

A Claude Code plugin that helps Claude write **secure, idiomatic React 19 + TypeScript** code and review changes against the same rule set. It covers Next.js App Router, React Router, TanStack Router and Query, Zustand, Redux Toolkit, React Hook Form and Zod.

> **Status: v0.1.0.** 156 rules in 15 domains, a writing skill, a review command, and 52 eval cases. Every single-run check passed during development; the full 3-run comparison is yours to run (see [Evals](#evals)). The spec is in [`SPEC.md`](SPEC.md) and the build log in [`tasks/todo.md`](tasks/todo.md). MIT licensed. Not yet published to GitHub.

## What it does

- **Writing (automatic).** Describe what you need. The `react-power-up` skill fires on React work and has Claude:
  - detect your React, framework, router, library and TypeScript versions, and whether React Compiler is enabled
  - follow version-appropriate best practices (React 19 primary, React 18 differences handled)
  - avoid known anti-patterns
  - check every data flow for security issues
  - add tests when your project has a test setup.
- **Reviewing (on demand).** `/react-power-up:review` reviews your uncommitted changes, and `/react-power-up:review <commit>` reviews one commit. You get a standard code review with numbered proposed changes. Nothing is applied unless you ask.

## Requirements

- Claude Code
- For `/react-power-up:review`: `git`, and a POSIX shell (on Windows, Git Bash)

## Installation

### Local, without installing (development)

```bash
claude --plugin-dir /path/to/react-power-up
```

### Local marketplace

```text
/plugin marketplace add /path/to/react-power-up
/plugin install react-power-up@mlsstjnvc
/reload-plugins
```

The install id is `<plugin>@<marketplace>`: the plugin is `react-power-up` and the marketplace is `mlsstjnvc`.

**Remove it:**

```text
/plugin uninstall react-power-up@mlsstjnvc
/plugin marketplace remove mlsstjnvc
```

### GitHub marketplace

Not published yet. `repository` and `homepage` in `plugin.json` stay unset until the GitHub repo exists.

## Usage

### Writing code

Just ask for what you need. The skill fires on React work, including a `.tsx` file whose prompt never says "React". It stays out of Vue, Nuxt, Svelte, Angular, Solid and React Native work, and out of vue-power-up's way if both are installed.

```text
Add a project detail page at /projects/:projectId with a rename form
Write a TanStack Query hook useInvoices(page) that keeps the previous page visible
Create a Next.js Server Action that saves the contact form and shows validation errors
Show the user's bio, which they write as HTML, on their profile page
Write tests for src/components/TodoList.tsx
```

What happens, using the first prompt as an example:
1. **Context first.** Claude finds the nearest `package.json` (monorepos included), resolves the installed versions, the project type (here, a React Router 8 SPA) and whether React Compiler is on, and states them in its plan.
2. **Idiomatic code for that stack.** Here: a route `loader` and `action` instead of an effect fetch, `<Form>`/`useFetcher`, imports from `react-router` (not `react-router-dom`, which is v7), `<Link>` instead of `<a href>`, and an error boundary.
3. **Guardrails.** A request that conflicts with a rule is done the safe way and the deviation is explained. For example, user HTML is sanitized or rendered as text, an API key moves behind a server route, and a "fetch in `useEffect`" request gets a data-library or loader solution.
4. **Tests** are added when the project has a test setup (Vitest/Jest, Testing Library, MSW). Without one, Claude offers to set it up and never installs dependencies unasked.
5. **An honest report.** Checks that couldn't run (no `node_modules`, no shell) are reported as not run, never as passed.

### Reviewing: `/react-power-up:review [commit]`

```text
/react-power-up:review            # all uncommitted changes: staged, unstaged and untracked (respects .gitignore)
/react-power-up:review 1a2b3c4    # exactly what that commit changed (merge commits: diff vs first parent)
```

**Precondition:** git must be installed and you must be inside a git repository. Otherwise the command stops:
- `/react-power-up:review needs git installed; \`git\` was not found on PATH.`
- `/react-power-up:review must run inside a git repository; <cwd> isn't one.`

**Other early stops:**
- An argument that isn't a 4–40 character hex hash: `Invalid argument "…"`.
- An unknown or ambiguous hash.
- A clean working tree: `Nothing to review…`.

**The command never changes anything.** It doesn't edit, stage, commit, stash or check out. It runs only read-only git commands, which are pre-approved so they run without prompts. It skips generated files (`routeTree.gen.ts`, `.next/`, …), and it never reads real `.env*` files.

**Output: a standard code review**
1. **Scope** (files or commit), and **Context**: the React version, project type, TypeScript version, and whether React Compiler is on. For a commit, these are read from that commit's `package.json`.
2. **Summary** of what the change does.
3. **Verdict:** *Request changes* (any `error`), *Approve with suggestions* (`warn`), or *Approve*.
4. **Findings** by severity, for example `[error] REACT-COMP-001 src/components/Tag.tsx:2`, with why it matters (linked to the official source) and a suggestion. Bugs outside the catalog are reported as `GENERAL`.
5. **Proposed changes:** numbered `diff` blocks, including missing pieces such as tests or validation.
6. Optionally, what's done well.

**Excerpt** from a real run (eval `review-components`, trimmed):

````markdown
**Scope:** files: `src/components/MemberTable.tsx`, `src/components/RoleBadge.tsx`, `src/settings/SettingsContext.tsx`
**Context:** React 19.2 · plain React (Vite SPA) · TypeScript 5.9 (`strict` on) · React Compiler off

### Verdict
**Request changes**: there are three `error` findings, including a broken filter input and a default that silently does nothing.

### Findings
- **[error] REACT-COMP-001** `src/components/MemberTable.tsx:9`: A component is defined inside another component.
  - *Why:* `FilterInput` is a new component type on every render of `MemberTable`. … The input loses focus after every character. ([source](https://react.dev/learn/preserving-and-resetting-state#different-components-at-the-same-position-reset-state))
  - *Suggestion:* Render the `<input>` inline, or move `FilterInput` to module scope and pass it `value`/`onChange`. See Proposed change 1.
- **[error] REACT-COMP-011** `src/components/RoleBadge.tsx:7`: `defaultProps` on a function component in React 19.
- **[warn] REACT-TS-006** `src/settings/SettingsContext.tsx:5`: The context default is a fake object.

### Proposed changes
2. **Use a default parameter instead of `defaultProps`** (resolves REACT-COMP-011), `src/components/RoleBadge.tsx`
   ```diff
   -export function RoleBadge({ role }: { role?: Member['role'] }) {
   +export function RoleBadge({ role = 'viewer' }: { role?: Member['role'] }) {
      return <span className={`badge badge-${role}`}>{role}</span>
    }
   -
   -RoleBadge.defaultProps = { role: 'viewer' }
   ```

To apply any of these, tell me which (e.g. "apply 1 and 3").
````

To apply proposals, reply for example `apply 1 and 3`. Those edits then go through your normal Claude Code permissions.

You can also ask in plain language ("review `src/components/Cart.tsx`"). The same procedure and format are used, with the named files as the scope.

## Rules

Every rule has an id (`REACT-<DOMAIN>-NNN`), a severity (`error`, `warn` or `info`), an official source and a version range. The full index is in [`rule-catalog.md`](skills/react-power-up/references/rule-catalog.md).

Domains: `TS`, `HOOK`, `EFF` (effects), `COMP`, `JSX`, `ACT` (React 19 Actions), `STATE` (Zustand, Redux Toolkit), `QUERY` (TanStack Query), `RR` (React Router), `TSR` (TanStack Router), `NEXT`, `FORM` (React Hook Form + Zod), `SEC`, `PERF`, `TEST`.

| Domain | Rules | Domain | Rules | Domain | Rules |
|---|---|---|---|---|---|
| `TS` | 10 | `ACT` | 7 | `NEXT` | 23 |
| `HOOK` | 11 | `STATE` | 10 | `FORM` | 9 |
| `EFF` | 8 | `QUERY` | 11 | `SEC` | 9 |
| `COMP` | 11 | `RR` | 9 | `PERF` | 8 |
| `JSX` | 11 | `TSR` | 9 | `TEST` | 10 |

156 rules: 57 `error`, 84 `warn`, 15 `info`. Every `error` and `warn` rule cites official docs.

## Development

```bash
claude plugin validate . --strict                     # manifests
claude --plugin-dir . plugin details react-power-up   # component inventory, loaded from disk
claude --plugin-dir .                                 # dev loop
```

```bash
python3 tests/check_catalog.py                # rule headings ⇄ catalog index ⇄ RATIONALE
python3 tests/check_catalog.py --write-index  # regenerate the catalog index from rule headings
python3 tests/check_links.py                  # every rule's Source URL resolves (needs network)
```

### Evals

52 cases in `claude plugin eval` format, in [`evals/`](evals/): 19 write, 15 plain-language review, 6 review-command and 12 trigger cases.

```bash
# one case, single run, no baseline (fast iteration); keep the report local
claude plugin eval . --scaffold --case write-component-context --runs 1 --ablation none --allow-tools Write Edit --no-publish
```

Notes:
- `--case` takes one glob. If you pass it twice, only the last one counts. To select several cases, use a shared prefix (`--case 'review-*'`) or `--tag`.
- Without `--no-publish`, the HTML report is published to claude.ai by default.

```bash
sh tests/precheck.test.sh   # review precondition script (no model involved)
sh tests/coexistence.sh ~/projects/vue-power   # both plugins loaded: each prompt fires only its own skill (~9 headless runs, ~$2)
```

**Bash-granting eval cases** (`/react-power-up:review` command cases) need `--allow-tools Bash`, and an environment where the eval sandbox can grant it. In this development environment, the sandbox refuses because a credentials file can't be followed (EACCES), so those cases are verified by hand with headless runs (see `tasks/todo.md`, T4).

**Full run** (authoritative; from a normal terminal; 3 runs per case, with vs. without the plugin; roughly 300 agent runs, so expect it to take a while and cost on the order of tens of dollars):

```bash
claude plugin eval . --scaffold --allow-tools Bash Write Edit --no-publish
```

`--scaffold` is needed because cases build their fixture projects and git repos with bundled scripts. The 6 command cases need `Bash`. If your environment refuses a Bash grant (the eval prints a credentials-file EACCES message for every case), run everything else with `--allow-tools Write Edit` and select by `--case 'write-*'`, `--case 'trigger-*'` and `--tag plain`. Results go to `evals/results/` (git-ignored).

## Limitations

- **Guidance, not hard enforcement.** There are no hooks. Claude follows the rules through the skill and a mandatory self-check, and can still deviate.
- **The review command needs Bash permission** (for its git precheck) **and a POSIX shell** (Git Bash on Windows). Plain-language reviews need only read access.
- **Partial coverage** for Next.js Pages Router and React Router framework mode (core React rules only, and Claude says so). React Native is out of scope.
- **Rule coverage is finite.** Reviews report bugs outside the catalog as `GENERAL` findings.
- **Without `node_modules` or a lockfile**, versions are taken as the minimum of the `package.json` range. That's conservative: it never produces code your install can't compile.
- **No whole-project audit mode** (out of scope for now).

Details: [`docs/RATIONALE.md` § Known limitations](docs/RATIONALE.md#7-known-limitations).

## Design rationale

Every decision and rule is explained in [`docs/RATIONALE.md`](docs/RATIONALE.md). The specification is in [`SPEC.md`](SPEC.md).

## License

MIT, see [`LICENSE`](LICENSE).
