# Provider adapters

The kit is provider-agnostic: the *content* lives in `AGENTS.md` + `ai/*.md`,
and each AI tool reads it through whatever entrypoint that tool expects. **One
source of truth, many thin entrypoints.** Never fork the content per provider —
point each provider at it.

## Entrypoint filenames by provider

| Provider / tool | Entrypoint it auto-reads | Sub-agent dir | Settings/permissions |
|---|---|---|---|
| **Claude Code** | `CLAUDE.md` | `.claude/agents/*.md` | `.claude/settings.json` (shared, tracked), `.claude/settings.local.json` (local; track it if you want grants shared) |
| **Cursor** | `AGENTS.md` (also `.cursor/rules/*.mdc`) | — | `.cursor/rules/` |
| **GitHub Copilot** | `.github/copilot-instructions.md` | — | — |
| **Gemini CLI** | `GEMINI.md` | — | — |
| **OpenAI Codex / Aider / Zed / others** | `AGENTS.md` | varies | varies |

## Install: copy the kit, then wire the entrypoints

1. Copy `AGENTS.md` and the `ai/` directory into the target repo's root.
2. Make each provider's entrypoint point at `AGENTS.md` instead of duplicating
   it. Two ways:

   **Symlink (preferred — zero drift):**
   ```sh
   ln -s AGENTS.md CLAUDE.md
   ln -s AGENTS.md GEMINI.md
   mkdir -p .github && ln -s ../AGENTS.md .github/copilot-instructions.md
   ```
   Cursor reads `AGENTS.md` natively, so no symlink needed there.

   **Stub (if symlinks are awkward on the team's platform):** a one-line file
   whose whole content is `See AGENTS.md` (plus, for `CLAUDE.md`, any genuinely
   Claude-Code-specific notes — see below).

3. Bind the repo-specific placeholders once (at minimum `<gate-command>`,
   `<base>` branch, and the memory root). Put these in the provider entrypoint
   or a short top-of-repo section; the `ai/*` modules stay generic.

4. Install the pre-commit hook: `cp ai/templates/pre-commit .githooks/pre-commit
   && chmod +x .githooks/pre-commit` then a `hook-install` recipe that runs
   `git config core.hooksPath .githooks`.

5. **Commit the lot.** Agent definitions and memory must be tracked
   (`ai/05-agent-authoring.md`).

## Per-provider specifics

### Claude Code
- A real `CLAUDE.md` (not a symlink) is worth keeping when you have
  Claude-Code-specific operating notes: scratchpad goes in repo-local `.tmp/`
  not `/tmp`; CI watching runs under the Monitor tool; skills/plan-mode/task
  conventions. Have it open with `See AGENTS.md for the universal contract`,
  then add only the deltas.
- **Permissions** are the autonomy lever. `ai/templates/claude.settings.json`
  shows a yolo-but-guarded profile: broad `allow`, with a `deny` list that
  protects baselines and forbids writes to sibling repos. Autonomy is granted
  *here*, conditional on the execution policy (`ai/00`).
- **Sub-agents** go in `.claude/agents/*.md` with frontmatter `name`,
  `description`, optional `model`, `color`, `memory`. Track them.
- CI-watch and other recurring read-only commands belong in the `allow` list so
  they don't burn an approval round-trip each run.

### Cursor
- Reads `AGENTS.md` directly. For rules that should always-apply or glob-scope,
  mirror them into `.cursor/rules/*.mdc` with `alwaysApply: true` or a `globs:`
  selector. Keep those `.mdc` files thin — pointers into `ai/*`, not copies.

### Copilot
- `.github/copilot-instructions.md` is a single file with no include mechanism;
  symlink it to `AGENTS.md`. Copilot won't traverse `ai/*` on its own, so the
  entrypoint's inline core (the non-negotiables) is what it reliably honors.

### Generic / unknown tool
- If it reads `AGENTS.md`, it gets the contract and can follow the pointers into
  `ai/*` on demand. If it reads nothing automatically, paste `AGENTS.md` into
  its system prompt / rules field.

## CI-side agents (optional)

If you run an agent in CI (e.g. responding to `@mention` on issues/PRs), keep its
workflow minimal and least-privilege: trigger only on the mention, grant
`contents/issues/pull-requests: read` plus `id-token: write`, add
`actions: read` only if the agent needs to read CI results. The same execution
policy applies — it's the same contract, a different host.
