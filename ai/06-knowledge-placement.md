# Knowledge placement (the pointer pattern)

The instruction file is not a junk drawer. Every durable fact has a *correct*
home, and the entrypoint (`AGENTS.md` / `CLAUDE.md`) gets a **pointer** to it —
not a copy. This is what keeps the entrypoint small enough to actually be read
every session.

## Where each kind of knowledge lives

| Kind of knowledge | Home |
|---|---|
| A **decision** (stack choice, architectural invariant, "we use X not Y") | A decision record: `docs/decisions/*`, ADRs, a dated `stack-decisions.md`. Dated, append-mostly, supersession noted. |
| A **procedure** (how to run/deploy/regenerate something) | A runbook: `docs/runbooks/*`. |
| **History / why a change was made** | The commit message. Not a doc, not the entrypoint. |
| **In-flight task state** | A task list / plan in the current session — not a file. |
| **Cross-session institutional knowledge** (user prefs, validated approaches) | The memory framework (`ai/04`). |
| A **rule that changes turn-to-turn agent behavior** | The entrypoint — but only as a pointer, and only if it meets the bar below. |

## The bar for putting something in the entrypoint

A rule earns a line in `AGENTS.md` / `CLAUDE.md` only if **both**:

1. it changes how the agent behaves *turn to turn* (not just background
   context), **and**
2. getting it wrong has caused — or would obviously cause — real damage.

Everything else is a pointer to the decision record, runbook, or commit history
where it actually lives. Background "what this app is" context belongs in the
entrypoint only in cheat-sheet form, with the authoritative detail pointed-to.

## Why this matters

- An entrypoint that accretes every fact becomes one nobody reads, and the
  load-bearing rules drown.
- Decisions in dated records can be *superseded* cleanly (D24 supersedes D20);
  decisions copied into prose silently contradict each other.
- History in commit messages is queryable (`git log`, `git blame`) and attached
  to the exact change; history in a doc rots.

When you learn something durable, ask "what's the *correct* home?" before
defaulting to the entrypoint. Usually it's a decision record, a runbook, a
commit message, or a memory — and the entrypoint gets at most a pointer.
