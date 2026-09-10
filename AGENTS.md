# AGENTS.md

Provider-neutral operating contract for AI coding agents in this repository.
`AGENTS.md` is the emerging cross-tool standard filename (Cursor, Codex, Aider,
Zed, and others read it). Provider-specific entrypoints (`CLAUDE.md`,
`GEMINI.md`, `.github/copilot-instructions.md`) should **point here**, not fork
it — see `ai/providers.md`.

This file is the index and the non-negotiable core. The depth lives in the
`ai/` modules; read the relevant one before doing the work it governs.

---

## The modules

| When you are… | Read |
|---|---|
| Operating at all (start here) | `ai/00-execution-policy.md` |
| Committing, branching, opening a PR, tagging | `ai/01-commit-and-pr-hygiene.md` |
| After any push / watching CI | `ai/02-ci-discipline.md` |
| Writing code that touches the network, storage, or native/external APIs | `ai/03-defensive-coding.md` |
| Recording or recalling cross-session knowledge | `ai/04-memory-framework.md` |
| Authoring or editing a sub-agent definition | `ai/05-agent-authoring.md` |
| Deciding *where* a piece of knowledge belongs | `ai/06-knowledge-placement.md` |
| Deciding which specialist to delegate to | `ai/07-agent-roster.md` (+ `ai/agents/*.md`) |

---

## Non-negotiable core (the short version)

These are the rules that change turn-to-turn behavior. The modules expand each.

1. **Incremental, focused commits.** A sequence of small commits that each leave
   the tree buildable — never one large end-of-session dump.
2. **Start from a known-good state.** Run the gate (`<gate-command>`, see
   `ai/01`) before changing anything. If it's red at session start, surface that
   to the user *before* touching code — never fix-forward silently.
3. **Generated baselines are append-only.** Golden snapshots, fixtures,
   recorded outputs, lockfiles-of-record: never `rm`, never overwrite, never
   fold into a "cleanup" pass. Regenerate only on explicit user approval,
   recorded in the commit message.
4. **Quality gates ratchet upward only.** Coverage floors, lint thresholds, and
   checks may be raised, never relaxed — except with explicit user approval in
   the commit message.
5. **Keep the human-facing status doc aligned in the same change.** When work
   changes project shape (a milestone advances, a component flips status),
   update the status doc (README / roadmap) in the *same* commit series.
6. **Watch every push to a green conclusion.** "It probably didn't break
   anything" is how red reaches the main branch. See `ai/02`.
7. **Never crash on external failure.** Networks time out, payloads are
   malformed, storage is unwritable. Degrade gracefully. See `ai/03`.
8. **Durable agent state lives in version control.** Agent definitions and
   on-disk memory are tracked files, not per-checkout scratch — anything that
   cleans or re-syncs a checkout will otherwise silently delete them. See
   `ai/05`.

---

## Autonomy level

The default posture is **propose-then-act for anything outward-facing or hard to
reverse** (pushing, opening PRs, deleting, anything that leaves the machine).

A repository MAY grant a broader **autonomous ("yolo") mode** — agents operate
with wide tool permissions and commit/push without per-step confirmation —
**conditional on the execution policy (rules 1–8) being honored**. The instant
those rules cannot be followed, drop out of autonomous mode and confirm with the
user. Grant and scope this in the provider config (`ai/providers.md`), not here.

---

## Sources of truth

Stack and architectural decisions come from exactly two places: **the user**, or
the repository's **decision records** (e.g. `docs/decisions/*`, ADRs). Nothing
else — do not infer choices from sibling repos, prior conventions, or training
priors. If the decision records are silent, ask the user. This file governs
*how* you work; the decision records govern *what* you build.
