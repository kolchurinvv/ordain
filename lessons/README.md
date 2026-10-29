# Lessons

Candidate rules harvested from projects and agent tools, waiting to be promoted
into the kit. One file per lesson, in the format defined by the `star-pupil`
agent (`ai/agents/star-pupil.md`), which writes them. The bar for promotion is
`ai/06-knowledge-placement.md` § Promoting a lesson out of a project.

This directory is not part of the kit: `ai/sync.sh` ships `ai/` only, so nothing
here reaches an adopting repository until it is promoted into a module.

## How lessons arrive

- **From the kit's owner:** commits from a star-pupil run on the owner's own
  machine.
- **From an adopting repository:** one pull request from a star-pupil run that
  the repository opted into. Each file's text was approved by the person who
  sent it.

## Reviewing a lessons PR

Review it like code. For each lesson, check:

- **The bar.** Does it clear `ai/06`: portable, evidenced, behavioral?
- **Already covered?** If the kit already says it, the lesson is evidence for
  that rule, not a new one.
- **Publishable and source-free?** It must name no people, clients, products,
  hosts, ticket numbers or paths, contain no customer data or secrets, and not
  say where it was learned (`ai/README.md` § Design stance). If anything slips
  through, ask the sender to fix it rather than editing it yourself: they
  approved that exact text.

Merging accepts the lessons as `candidate`.

## Status

A lesson's `status` moves from `candidate` to `promoted:<kit file>` (the
promoting commit changes both files) or to `rejected:<why>`.
