# Amendments

Some kit updates change what a rule asks agents to do. Each of those changes is
recorded here, newest first, in the same commit series that makes it.

An update rewrites `ai/` and the core block in `AGENTS.md`. It can't reach text
the repository wrote itself: a Bindings row, a review skill or command, a copied
agent definition, a contributing guide, a pull request template. Nor can it reach
an agent that is mid-session and still holds the old text. Each entry's
**Check outside `ai/`** names where the old rule may have been restated.

So an update isn't finished until those are reconciled. The repository's
Bindings carry an `Amendments reconciled` row (`Through A<number>`), and
`ai/sync.sh --check` lists every entry newer than that number and exits 3,
the same hold as an unfilled Bindings row, until the row is raised. A first
install sets the row to the newest entry, since there is nothing older to
reconcile. The steps are in `INSTALL.md` § Update.

A repository that wants to keep the old behavior says so in its Bindings or a
decision record, which win over the kit's defaults (core § Sources of truth),
and raises the row.

An entry looks like this. The check finds entries by their `## A<number> `
heading, so keep that shape, number entries in order, and never renumber or
delete one:

```markdown
## A<n> (<YYYY-MM-DD>): <the rule as it now stands>

- **Changed:** the modules and rules whose text changed.
- **Was:** the behavior it supersedes.
- **Now:** what agents do instead.
- **Why:** the failure that made the old rule wrong.
- **Check outside `ai/`:** where an adopting repository may have restated the old rule.
```
