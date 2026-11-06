# AGENTS.md

Tool- and model-neutral operating contract for AI coding agents in this
repository. `AGENTS.md` is the cross-tool convention most coding agents read on
their own. A tool that reads a different file is wired to import this one
(`ai/providers.md`), never given a copy.

This repository is `ord-ai-n`, the home of the kit itself: the contract below is
the product, and this file carries it the same way any adopting repository does.
To adopt it elsewhere, see `ai/README.md`.

<!-- ord-ai-n:core:begin -->
## Agent working contract

<!-- Generated from ai/CORE.md by ai/sync.sh — do not edit this block in place;
     the next sync overwrites it. Repo-specific values belong in Bindings. -->

How AI agents work in this repository, whatever the tool or model. This block is
the non-negotiable core; the depth lives in the `ai/` modules — read the relevant
one before doing the work it governs. `<angle-bracket>` placeholders are bound
once, in this file's **Bindings** section. Where the Bindings or this
repository's decision records say otherwise, they win over the kit's defaults.

### The modules

| When you are… | Read |
|---|---|
| Operating at all (start here) | `ai/00-execution-policy.md` |
| Committing, branching, opening a PR, tagging | `ai/01-commit-and-pr-hygiene.md` |
| After any push / watching CI | `ai/02-ci-discipline.md` |
| Writing code that touches the network, storage, or native/external APIs, or that handles errors at all | `ai/03-defensive-coding.md` |
| Recording or recalling cross-session knowledge | `ai/04-memory-framework.md` |
| Authoring or editing a sub-agent definition | `ai/05-agent-authoring.md` |
| Deciding *where* a piece of knowledge belongs | `ai/06-knowledge-placement.md` |
| Deciding which specialist to delegate to | `ai/07-agent-roster.md` (+ `ai/agents/*.md`) |
| Reviewing agent-authored work before it lands | `ai/08-adversarial-review.md` (+ `ai/agents/adversary.md`) |
| Running several agents on one codebase at once | `ai/09-parallel-streams.md` |
| Writing tests, especially for anything that persists data | `ai/10-test-discipline.md` |
| Setting or changing a coverage floor, threshold, exemption or grandfather list | `ai/11-quality-ratchets.md` |
| Configuring the type checker, linter, formatter or a guard script; writing an architecture rule | `ai/12-static-strictness.md` |

### Non-negotiable core

These are the rules that change turn-to-turn behavior. The modules expand each.

1. **Incremental, focused commits.** A sequence of small commits that each leave
   the tree buildable — never one large end-of-session dump.
2. **Start from a known-good state.** Run the gate (`<gate-command>`, see
   `ai/01`) before changing anything. If it's red at session start, surface that
   to the user *before* touching code — never fix-forward silently. If your
   environment cannot run it, say so up front and in your report — never present
   unverified work as verified.
3. **Generated baselines are append-only.** Golden snapshots, fixtures,
   recorded outputs, lockfiles-of-record: never `rm`, never overwrite, never
   fold into a "cleanup" pass. Regenerate only on explicit user approval,
   recorded in the commit message.
4. **Quality gates ratchet upward only.** Coverage floors, lint thresholds, and
   checks may be raised, never relaxed — except with explicit user approval in
   the commit message. See `ai/11`.
5. **Keep the human-facing status doc aligned in the same change.** When work
   changes project shape (a milestone advances, a component flips status),
   update the status doc (README / roadmap) in the *same* commit series.
6. **Watch every push to a green conclusion.** "It probably didn't break
   anything" is how red reaches the main branch. See `ai/02`.
7. **Fail soft on the world, loud on yourself.** Networks time out, payloads are
   malformed, storage is unwritable: degrade gracefully. But a broken invariant,
   a contract your own code violates, or a check that cannot run fails loudly and
   at once — never a silent default, a swallowed error, or a vacuous pass. See
   `ai/03`.
8. **Autonomous mode is conditional on rules 1–7.** Where a repository grants
   broad tool permissions, they hold only while the rules above are honored. The
   instant one cannot be, drop out and confirm with the user. See `ai/00`.
9. **Durable agent state lives in version control.** Agent definitions and
   on-disk memory are tracked files, not per-checkout scratch — anything that
   cleans or re-syncs a checkout will otherwise silently delete them. See
   `ai/05`.
10. **Agent-authored work gets an adversarial pass before it lands,** and every
    finding gets an answer: fixed, rebutted with evidence, or held for the user's
    ruling. The pass's first question is "is this the change that was asked
    for?", the failure no gate can see, because gates check a change against
    itself. A green pipeline is a claim to verify, not evidence. See `ai/08`.

> **Numbering is a contract.** Items 1–8 mirror `ai/00-execution-policy.md`'s
> rule numbers exactly, so "rule 4" means the same thing in every repo and every
> module that cites it. Items 9–10 are core rules whose depth lives elsewhere.
> If you change one list, change the other in the same commit.

**Done means done.** A change is finished only when `ai/00` § Definition of
done holds. Name whatever you couldn't verify in your report.

### Autonomy level

The default posture is **propose-then-act for anything outward-facing or hard to
reverse** (pushing, opening PRs, deleting, anything that leaves the machine).

A repository MAY grant a broader **autonomous ("yolo") mode** — agents operate
with wide tool permissions and commit/push without per-step confirmation —
**conditional on the execution policy (rules 1–7) being honored**. The instant
those rules cannot be followed, drop out of autonomous mode and confirm with the
user. Grant and scope this in the provider config (`ai/providers.md`), and record
what is granted in Bindings.

### Sources of truth

Stack and architectural decisions come from exactly two places: **the user**, or
the repository's **decision records** (e.g. `docs/decisions/*`, ADRs — Bindings
names this repository's). Nothing else — do not infer choices from sibling repos,
prior conventions, or training priors. If the decision records are silent, ask
the user. This block governs *how* you work; the decision records govern *what*
you build.
<!-- ord-ai-n:core:end -->

## Bindings

The values this repository gives the core's placeholders. Unbound entries say so
rather than staying silent.

| Binding | Here |
|---|---|
| `<gate-command>` | **None yet.** The only verification is `nix flake check` plus `ai/sync.sh --check .`; say so rather than claiming a gate ran. |
| `<base>` branch | `main` |
| Commit / branch convention | Conventional Commits (`ai/01`); branches `<type>/<short-slug>`. Every change reaches `main` through a pull request and is squash-merged, CI or not; nothing is pushed to `main` directly (owner's ruling). A squash makes each PR one commit on `main`, so one concern per PR, with a step-by-step commit series inside it. The PR title becomes that commit's subject, so it is a Conventional Commit too. |
| Decision records | None yet; decisions come from the user. |
| Status doc (rule 5) | Root `README.md` (what the kit is, how to install it); `ai/README.md` describes the kit's contents. |
| Generated baselines (rule 3) | `flake.lock` — update only on request, in its own commit. |
| `<read-back>` (`ai/10`) | none: the kit stores nothing and has no tests yet. |
| `<floors>` (`ai/11`) | none: nothing is measured yet (no tests, no linted code beyond two shell scripts). |
| `<exemptions>` (`ai/11`) | none: no gate takes exemptions. |
| `<static-checks>` (`ai/12`) | Partial: `shellcheck` on `ai/sync.sh` and `install.sh`, run by hand, not yet a gate. |
| Memory root | Harness-local only; no tracked memory root. |
| Autonomy | Limited. Agents commit on a branch, push it and open its pull request without asking, and may rebase and force-push their own open PR branch (`--force-with-lease`), as stacked PRs need after a squash merge. Merging is the owner's call. Everything else outward-facing (tags, releases, issues, repository settings, rewriting `main` or anyone else's branch, anything sent to another repository) is propose-then-act. |
| `Feedback (star-pupil)` | On (kit run): the owner's machine and projects; transcripts only on request. Lessons go to `lessons/`. |

## Developing the kit

- The dev shell comes from the Nix flake (`flake.nix`, nixpkgs `nixos-unstable`,
  Linux and macOS on x86_64 and aarch64). Enter it with `nix develop`.
- Add tools to `devShells.default` in `flake.nix` rather than installing them
  globally, then re-enter the shell.
- Refresh the lock with `nix flake update` only when asked, in its own commit
  (Bindings: generated baselines).
- Test changes to `ai/sync.sh` or `install.sh` against a scratch repository,
  never against a real adopter.
