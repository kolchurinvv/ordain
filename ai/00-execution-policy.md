# Execution policy

How agents operate, independent of language or stack. Rules 1–7 are
unconditional. Rule 8 (autonomous mode) is *conditional* on the others being
honored. These are the rules that prevent drift and laziness; treat them as
load-bearing, not advisory.

> Placeholders in `<angle-brackets>` are repo-specific — bind them once in your
> provider entrypoint (`CLAUDE.md` etc.) or a top-of-repo note. The canonical
> one is `<gate-command>`: the single command that runs the full local check
> aggregate (see `ai/01-commit-and-pr-hygiene.md`).

## 1. Incremental commits

Land work as a sequence of small, focused commits, not one large dump. Each
commit:

- leaves the tree in a buildable / passing state,
- describes exactly one logical change,
- is something a reviewer could read in isolation.

A long agent session that ends with a single 40-file commit has failed this
rule even if the code is correct. Commit at every coherent stopping point.

## 2. Start every session from a known-good state

Run `<gate-command>` at the start of a session **before** making changes —
unless the checkout demonstrably already matches a known-good baseline (e.g. you
just verified it, or it's at a tagged milestone).

If the gate is **red at session start**, surface that to the user before doing
anything else. Do not "fix forward" silently — a pre-existing failure is the
user's to know about, and silently absorbing it into your change destroys the
signal of what *you* broke.

If your environment **cannot run the gate** — no container runtime, no network,
a sandbox missing the toolchain — say so before you start and again in your
report. You may still do the work, but it is unverified, and it must be
presented as unverified: never let "I couldn't run it" read as "it passed." In
a repository whose agents run in harnesses nobody controls, this is the case
you will meet most often.

## 3. Never delete generated baselines

Golden snapshots, recorded fixtures, approval-test outputs, committed codegen,
and lockfiles-of-record are **append-only from an agent's perspective**.

- Never `rm` one.
- Never overwrite one without explicit confirmation.
- Never sweep one into a "cleanup" or "regenerate everything" pass.

Regenerate **only** when the user explicitly approves it, and record that
approval in the commit message (e.g. `chore(goldens): regenerate onboarding
snapshots (user-approved)`). The baseline is the test oracle; silently rewriting
it is silently deleting the test.

## 4. Quality gates ratchet upward only

Coverage floors, lint thresholds, type strictness, and check counts may be
**raised**, never **lowered**. The one exception is explicit user approval
recorded in the commit message. A red gate is fixed by fixing the code, not by
lowering the bar. Disabling a check "temporarily" is the same violation.

No inline escape hatches for gates that have a central exemption mechanism: if
the project has an exemptions registry, exemptions live *only* there, edits to
it require user approval, and stale entries (matching nothing) should fail the
gate. Scattered `// lint-allow` comments rot; a central registry is auditable.

## 5. Keep the human-facing status doc aligned

The status doc (top-level `README.md`, a roadmap board, a `STATUS.md`) is the
manager-facing dashboard. When work changes the *shape* of the project — a
component advances a maturity level, a release ships or starts, an infra slot
flips status — update it in the **same** change. Per-commit trivia does not need
to touch it; release-shape progress does.

## 6. Watch every push to green

After any push, watch every relevant CI workflow to a terminal conclusion before
considering the work done. The full discipline is in `ai/02-ci-discipline.md`.
The one-line version: **assuming green is how red reaches the main branch.**

## 7. Defensive by default

Code you write must not crash on external/upstream/system failure. Full rules in
`ai/03-defensive-coding.md`.

## 8. Autonomous ("yolo") mode — conditional

Where a repository grants it (in provider config), agents may operate with broad
tool permissions: read freely, edit, commit, and push without per-step
confirmation, to move fast without tedious manual gating.

This permission is **conditional on rules 1–7 above.** If any of them cannot be
honored — the gate is red and you can't explain why, you're about to delete a
baseline, a change can't be made incrementally — **drop out of autonomous mode
and confirm with the user before proceeding.**

Autonomous mode never extends to:

- **Writes outside this repository.** Reads from sibling repos may be permitted;
  writes to them always require explicit user approval.
- **Irreversible outward actions** beyond normal commit/push — force-pushing
  shared branches, deleting remote branches/tags, publishing releases, touching
  production — unless the user durably authorized that specific action.

Autonomy is about removing tedium (manual commit/push/test cycles), not about
removing judgment on the few actions that are actually dangerous.
