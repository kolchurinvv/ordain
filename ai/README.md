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

## Install (any repo)

1. Copy `AGENTS.md` and this `ai/` directory to the repo root.
2. Point each provider's entrypoint at `AGENTS.md` (symlink or one-line stub) —
   see `providers.md`.
3. Bind the repo-specific placeholders, chiefly `<gate-command>`. Add the gate
   recipes from `templates/gate.just`.
4. Install the hook: `cp ai/templates/pre-commit .githooks/ && chmod +x
   .githooks/pre-commit && just hook-install`.
5. For Claude Code, drop `templates/claude.settings.json` at
   `.claude/settings.json` and edit the placeholders to set your autonomy level.
6. Drop the specialists you want into the host's agent dir (e.g. `cp
   ai/agents/*.md .claude/agents/`), and bind their `<...>` placeholders. The
   delegation policy is `07-agent-roster.md`.
7. Commit everything — agent definitions and memory must be tracked
   (`05-agent-authoring.md`).

## Design stance

- **Content is provider-agnostic; entrypoints are thin.** Never fork the rules
  per tool — point every tool at the same `AGENTS.md` + `ai/*`.
- **The instruction file is an index, not a junk drawer.** Decisions go in
  decision records, procedures in runbooks, history in commit messages, durable
  facts in memory — the entrypoint gets pointers (`06-knowledge-placement.md`).
- **Autonomy removes tedium, not judgment.** Broad permissions to commit/push/
  test freely, conditional on the execution policy; hard stops on the few
  genuinely dangerous actions.
