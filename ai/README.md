# AI workflow kit

A provider-agnostic set of rules and scaffolding that gives any AI-enabled repo
the same robust agent behavior: no drift, clean incremental commits, disciplined
CI, durable memory, and automation that removes the tedium of committing,
pushing, and gating by hand.

It drops into any repo and works with any agent (Claude Code, Cursor, Copilot,
Gemini, Codex, …).

## What's here

| File | Concern |
|---|---|
| `../AGENTS.md` | Provider-neutral entrypoint: the core block (generated from `CORE.md`) + this repo's Bindings. |
| `CORE.md` | The non-negotiable core and module index: the block `sync.sh` generates into every adopting repo's `AGENTS.md`. |
| `sync.sh` | Vendors the kit into a repo (`sync.sh <repo>`); verifies a vendored copy (`sync.sh --check <repo>`). |
| `00-execution-policy.md` | How agents operate: incremental commits, known-good start, append-only baselines, ratchet-only gates, conditional autonomy. |
| `01-commit-and-pr-hygiene.md` | The gate, commit messages (host convention first), branching/worktrees, PRs, milestone tags. |
| `02-ci-discipline.md` | Watch every push to green; use the poll recipe; artifact triage. |
| `03-defensive-coding.md` | Never crash on external failure — the six boundaries. |
| `04-memory-framework.md` | File-based cross-session memory; stale memory is worse than none. |
| `05-agent-authoring.md` | Writing sub-agents; keeping definitions + memory in git. |
| `06-knowledge-placement.md` | The pointer pattern: where each kind of knowledge belongs. |
| `07-agent-roster.md` | The standing roster of specialists and the delegation policy. |
| `08-adversarial-review.md` | Reviewing agent-authored work: conformance-to-request first, green is a claim, falsify your own findings. |
| `09-parallel-streams.md` | Running several agents on one codebase: frozen/owned/shared allocation, append protocol, resource serialization. |
| `agents/*.md` | Drop-in specialist definitions: adversary, coding-teacher, explorer, planner, reviewer. |
| `providers.md` | How each AI tool ingests the kit; one source of truth, thin entrypoints. |
| `templates/pre-commit` | Hook that delegates to the project gate. |
| `templates/agent-template.md` | Provider-neutral sub-agent definition skeleton. |
| `templates/claude.settings.json` | Yolo-but-guarded permissions profile. |
| `templates/gate.just` | The `check` / `precommit` / `hook-install` / `ci-watch` recipe contract. |

## Adopt it in a repository

The kit travels as a **vendored, read-only `ai/` directory** plus **one generated
block in the host's `AGENTS.md`**. Everything repo-specific lives in the host's
own files, never under `ai/`, so a re-sync is a plain copy and its diff is
exactly the kit's change.

Nobody adopting the kit can promise which harness or model will read it, so it
takes hold in three layers, from weakest guarantee to strongest:

1. **The inline core.** The ten rules, generated into `AGENTS.md`, which nearly
   every coding agent loads unprompted. A model that follows no pointer still
   reads them.
2. **The modules.** `ai/*.md` hold the depth, for agents that follow the core's
   pointers.
3. **Mechanical enforcement.** Hooks and CI checks bind whatever wrote the
   change, including an agent that read nothing. A rule that matters and that a
   script can check should be checked by one.

### Steps

1. **Mark where the block goes.** In the host's `AGENTS.md` (create one with a
   title if it has none), add these two lines near the top, after the project
   summary. The sync never guesses a placement.
   ```
   <!-- ord-ai-n:core:begin -->
   <!-- ord-ai-n:core:end -->
   ```
2. **Sync.** From an ord-ai-n checkout with no uncommitted changes, run
   `ai/sync.sh <host-repo>`. It copies `ai/`, records the kit version and each
   file's hash in `ai/.kit-manifest`, and regenerates the block from
   `ai/CORE.md`.
3. **Write the host's Bindings.** Directly after the block, add a `## Bindings`
   section that binds each placeholder to this repository: the gate command and
   what to do where it cannot run, the base branch, the commit and branch
   convention, the decision records, the status docs, the generated baselines,
   how to watch CI, the memory root, where agent definitions live, and the
   autonomy granted. An entry with no value says so ("none: …"); never leave one
   silently unbound.
4. **Reconcile, don't stack.** Where the host already has rules (a constitution,
   a commit convention, its own review skill), the host's documents win over the
   kit's defaults. Record that in Bindings, and point the host's existing tools
   at the matching module instead of adding a parallel one.
5. **Wire the entrypoints** for tools that don't read `AGENTS.md` themselves
   (`providers.md`). For Claude Code, that is a `CLAUDE.md` that starts with
   `@AGENTS.md`. Optionally, drop the specialists you want into the host's agent
   dir (e.g. `cp ai/agents/*.md .claude/agents/`, delegation policy in
   `07-agent-roster.md`), and set the autonomy level from
   `templates/claude.settings.json`.
6. **Enforce what can be enforced.** At minimum, run `ai/sync.sh --check .` in CI
   so neither the block nor `ai/` can be edited in place. Then add a gate and a
   hook (`templates/gate.just`, `templates/pre-commit`) and CI checks for the
   host's own load-bearing rules.
7. **Commit all of it.** Agent definitions and memory must be tracked
   (`05-agent-authoring.md`).

The kit must live at `ai/` in the host, because its modules cite each other by
that path.

### Re-sync

Run `ai/sync.sh <host-repo>` again and commit the result on its own. Never edit
`ai/` or the block in the host: change them in ord-ai-n and sync. `--check`
fails on in-place edits and on files under `ai/` that the kit does not ship.

## Design stance

- **Content is provider-agnostic; entrypoints are thin.** Never fork the rules
  per tool — point every tool at the same `AGENTS.md` + `ai/*`.
- **The instruction file is an index, not a junk drawer.** Decisions go in
  decision records, procedures in runbooks, history in commit messages, durable
  facts in memory — the entrypoint gets pointers (`06-knowledge-placement.md`).
- **Autonomy removes tedium, not judgment.** Broad permissions to commit/push/
  test freely, conditional on the execution policy; hard stops on the few
  genuinely dangerous actions.
