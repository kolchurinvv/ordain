# Install, update or remove the kit

Step by step, for a repository that already has code, history and other people
working in it. Adopting the kit is a change like any other: it goes on its own
branch and through the repository's normal review. Why it is shaped this way:
`README.md` § Adopt it in a repository.

**What the installer touches:** it adds `ai/` (including `ai/.kit-manifest`) and
rewrites the block between two marker lines in `AGENTS.md`. Nothing else. It
refuses to overwrite an `ai/` directory it didn't create, or one with
uncommitted changes.

**You need:** `bash`, `curl`, `tar`, `git`. While the kit repository is
private, you also need read access to `kolchurinvv/ordain` and `gh auth login`.

## Install

### 1. Branch first

Never adopt on the default branch. Name the branch the way the repository
names branches (a ticket key, a type prefix); `add-agent-contract` below is a
placeholder.

**A normal clone:**

```sh
cd path/to/repo
git fetch origin
git switch -c add-agent-contract origin/main
```

**A bare repository with one worktree folder per branch** (a `.bare/` directory
next to folders like `main/`):

```sh
cd path/to/repo-root                # the folder that holds .bare/
git -C .bare fetch origin
git -C .bare worktree add --no-track -b add-agent-contract ../add-agent-contract origin/main
cd add-agent-contract
```

`--no-track` keeps the new branch from pushing to `main` by accident.

If git says `invalid reference: origin/main`, the bare repository was cloned
without a fetch refspec (a plain `git clone --bare` doesn't set one). Set it
once, then fetch and run the `worktree add` line again:

```sh
git -C .bare config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git -C .bare fetch origin
```

### 2. Mark where the rules go

Open `AGENTS.md` (create it with a `# AGENTS.md` title if the repository has
none). Add these two lines right after the project summary, or right under the
title if there is no summary:

```
<!-- ord-ai-n:core:begin -->
<!-- ord-ai-n:core:end -->
```

The installer fills the space between them and never guesses where to put it.

### 3. Run the installer

From the repository's root:

```sh
# while the kit repository is private
curl -fsSL -H "Authorization: Bearer $(gh auth token)" \
  https://raw.githubusercontent.com/kolchurinvv/ordain/main/install.sh | bash

# once it is public
curl -fsSL https://raw.githubusercontent.com/kolchurinvv/ordain/main/install.sh | bash
```

It downloads the kit at one exact commit, copies `ai/`, records that commit and
a hash of every file in `ai/.kit-manifest`, and writes the core rules between
the markers.

To read the script before running it, download it first:
`curl -fsSL … -o /tmp/install.sh`, read it, then `bash /tmp/install.sh`.

Options go after `bash -s --`:

| Option | Does |
|---|---|
| `--ref <tag-or-sha>` | Install a specific kit version instead of `main`. |
| `--force` | Overwrite an existing `ai/` the installer didn't create. Only when you mean to replace it. |
| `<path>` | Install into that repository instead of the current directory. |

### 4. Write the Bindings

Directly after the end marker, add a `## Bindings` table. It maps the kit's
generic rules onto this repository. Fill every row; `none: <why>` is a valid
value, a blank is not.

```markdown
## Bindings

| Binding | Here |
|---|---|
| `<gate-command>` | The command that runs the checks before a commit, and what to do where it can't run. |
| `<base>` branch | |
| Branches and commits | The repository's naming and message format. |
| Decision records | Where architecture and stack decisions are written down. |
| Status docs (rule 5) | The README or roadmap that must stay current. |
| Generated baselines (rule 3) | Snapshots, fixtures, migrations, lockfiles: files agents must never rewrite unasked. |
| Quality gates (rule 4) | The checks that may only get stricter. |
| CI (rule 6) | What runs on which event, and how to watch it. |
| Adversarial review (core 10) | How independent review is run here. |
| Agent definitions | Where agent and skill files live. |
| Memory root | Where shared agent memory lives, or none. |
| Autonomy | What agents may do without asking. |
| `Feedback (star-pupil)` | off |
| The kit itself | Vendored from ord-ai-n (version in `ai/.kit-manifest`). Update by re-running the installer; never edit `ai/` or the block above. |
```

**Reconcile, don't stack.** Where the repository already has rules (a
constitution, a CONTRIBUTING file, a commit convention, its own review skill),
point at them in Bindings and say which document wins. Don't copy them in.

### 5. Wire the tools that don't read `AGENTS.md`

- **Claude Code.** With no `CLAUDE.md`: `printf '@AGENTS.md\n' > CLAUDE.md`.
  With one: add `@AGENTS.md` as its first line.
- **Other tools:** see `providers.md`.

### 6. Check, commit, open the PR

```sh
ai/sync.sh --check .
git add ai AGENTS.md CLAUDE.md
git commit        # the repository's message format; name the source line from ai/.kit-manifest
```

Open the pull request the way the repository usually does.

Then, as a separate change, make CI fail when someone edits the kit in place.
Do this once the kit repository is public, so whoever maintains the repository
can see where a fix belongs. GitHub Actions:

```yaml
  agent-contract:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ai/sync.sh --check .
```

## Update

1. Branch first, as in Install step 1.
2. Re-run the install line from step 3.
3. Commit the result on its own. Its diff is exactly what changed in the kit;
   the source line in `ai/.kit-manifest` shows which version you moved to.

If the installer refuses because `ai/` has uncommitted changes, someone edited
the kit in place. Move what they meant into Bindings, drop the edit
(`git checkout -- ai`), and run it again.

## Remove

```sh
git rm -r ai
```

Then delete the marked block and the Bindings section from `AGENTS.md`, the
`@AGENTS.md` line from `CLAUDE.md` if you added it, and the CI job if you added
one. Commit.

## Sending lessons back (optional)

The kit ships an agent, the star-pupil (`agents/star-pupil.md`), that turns what
agents learned in this repository into lessons for the kit. It is off until the
`Feedback (star-pupil)` row in Bindings says `on` and names what it may read.

To run it in any tool, ask the agent to act as the agent defined in
`ai/agents/star-pupil.md`. In Claude Code you can also copy that file into
`.claude/agents/`.

1. **It shows its disclosure first.** Before reading anything, it prints a
   table of what it will read, never read, write, send, and strip out, and
   waits for your go-ahead.
2. **Lessons stay local.** It writes them to a local outbox, and nothing leaves
   the machine at this point.
3. **Sending is one pull request.** If you choose to send, it prepares one pull
   request to the kit repository that adds the lesson files under `lessons/`.
   It shows you every file and the PR text, and opens the PR only when you
   approve. The PR is visible to everyone who can see the kit repository. You
   need a GitHub account that can fork the kit, or access to it while it is
   private.
4. **The kit's maintainer reviews the PR.** Merging accepts the lessons as
   candidates. Moving one into the kit's rules is a separate, later commit, and
   the improved rule reaches your repository with your next update.
