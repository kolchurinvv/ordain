# Commit & PR hygiene

The mechanics of landing work cleanly and without manual babysitting. This is
where "minimize the tedium of committing and pushing" gets cashed out: the
agent does it continuously and correctly, so the human never has to.

## The gate

Every repo using this kit defines **one** aggregate command that runs the full
local check suite — typecheck + lint + format-check + tests + whatever
project-specific gates exist (coverage, docs-coverage, codegen-drift, etc.).
Bind it to `<gate-command>`. Conventionally:

- `just check` / `just precommit`,
- `make check`,
- `npm run check`,
- or a single script `./scripts/check.sh`.

Two tiers are useful:

- **`check`** — fast aggregate, no heavyweight E2E. Run before every commit.
- **`precommit`** — `check` plus the slow suite (E2E, screenshot diff). Run
  before pushing anything that touches user-facing surfaces, and wire it into
  the git pre-commit hook (`ai/templates/pre-commit`, installed via a
  `hook-install` recipe that sets `git config core.hooksPath`).

Keep the hook a thin delegator to the gate so the justfile/Makefile stays the
single source of truth for "what passes." See `ai/templates/pre-commit`.

**When you add a new test surface** (a new E2E flow, a new gate recipe), add it
to the aggregate in the *same* commit series — otherwise the gate silently skips
it and the coverage is a lie.

## Conventional commits

Use Conventional Commits: `type(scope): summary`.

- Types: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `perf`, `build`,
  `ci`, `style`.
- Agent-infrastructure changes get a clear scope: `chore(agents):` /
  `feat(agents):` for agent-definition edits, `chore(goldens):` for approved
  baseline regen.
- The body carries the *why* and any approval the policy requires recorded
  in-message ("user-approved regeneration", "threshold raise approved"). The
  commit message is the durable home for change rationale — see
  `ai/06-knowledge-placement.md`.

## Branching

Never commit straight to the default branch. Branch first:

```
git switch -c <type>/<short-slug>
```

If the repository uses a **bare-repo + worktree layout** (one folder per branch,
work checked out into sibling folders):

- One folder = one branch for that branch's whole lifetime. Never
  `git checkout -b` inside an existing worktree; never switch branches in place.
- `git worktree add ../feature-foo -b feature-foo` for a new branch + folder.
- A worktree's `.git` is a pointer *file*, not a broken directory to "fix."

## Pull requests

```
gh pr create --base <base> --title "..." --body "..."
```

- In a **bare-repo/worktree** layout, `gh` can't infer the head branch from the
  pointer-file HEAD — pass `--head <branch>` explicitly.
- Link the tracked issue in the body (`Closes #NN`) so board automation moves
  the card.
- End the PR body with whatever attribution footer the repo standardizes on.

**Enforce issue-first with a gate, not a convention.** A CI job that fails any PR
whose body carries no issue reference is worth its weight: it makes every change
traceable to the request that motivated it. That link is not bookkeeping — it is
the precondition for `ai/08-adversarial-review.md`'s first rule, which asks
whether the change does what was *asked*. A change with no recoverable request
cannot be reviewed for conformance at all, only for correctness, and correctness
is the cheap half. File the issue when work is dispatched, not when the PR opens.

Provide named escape hatches (a `no-issue` label, a branch-name prefix for
machine-authored fixes carrying their own ticket ID) so the gate is bypassable on
purpose and not by habit.

## Milestone / rollback tags

When the user asks for a milestone or rollback point:

- **Name:** `milestone/YYYY-MM-DD-short-slug` — slash, ISO date, kebab slug. No
  `v`, no semver, no project-letter prefix. (Match the repo's existing shape if
  it differs; read the previous tag with `git tag -n100 <prev>`.)
- **Annotated, not lightweight:** `git tag -a <name> -m "..." <commit>`.
- **Body** summarizes the state: one sentence on the headline change, then which
  gates were green, then what was true at this point.
- **Tag the commit where every gate was actually green** — not HEAD-by-default
  if there were post-verify fixups. Re-verify or tag the earlier commit.
- **Do not push tags unless explicitly asked** (`git push` doesn't push tags by
  default; "tag it" with no qualifier = local-only).
- **Never delete or move an existing milestone tag** without explicit
  instruction — ask first.

## What gets committed that agents often miss

- **Agent definitions and on-disk memory** (`ai/05-agent-authoring.md`) — track
  them, or a worktree clean wipes them.
- **Provider config that's meant to be shared** (e.g. a tracked
  `settings.local.json` with permission grants) — stage and commit edits in the
  same change, don't leave it dirty across worktrees.
