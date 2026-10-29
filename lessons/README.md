# Lessons

Candidate rules harvested from projects and agent tools, waiting to be promoted
into the kit. One file per lesson, in the format defined by the `star-pupil`
agent (`ai/agents/star-pupil.md`), which writes them. The bar for promotion is
`ai/06-knowledge-placement.md` § Promoting a lesson out of a project.

This directory is not part of the kit: `ai/sync.sh` ships `ai/` only, so nothing
here reaches an adopting repository until it is promoted into a module.

A lesson's `status` moves from `candidate` to `promoted:<kit file>` (the
promoting commit changes both files) or to `rejected:<why>`. Lessons are written
to be publishable: no people, clients, products, hosts or source paths.
