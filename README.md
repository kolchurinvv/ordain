# ord-ai-n

A contract for how AI coding agents work in a repository: small commits, gates
that only get stricter, CI watched to green, code that fails loudly on its own
bugs, and adversarial review before a change lands. It drops into any repository
and works with any coding agent, harness or model.

## Install

You need `bash`, `curl`, `tar` and `git`. No GitHub account or token.

On a new branch, from the root of the repository you're adopting it in:

```sh
curl -fsSL https://raw.githubusercontent.com/kolchurinvv/ordain/main/install.sh | bash
```

It downloads the kit at one exact commit, copies it to `ai/`, records the version
in `ai/.kit-manifest`, and writes the core rules and a `## Bindings` table into
`AGENTS.md`, creating the file if it's missing. It changes nothing else, and it
refuses to overwrite an `ai/` it didn't create or one with uncommitted changes.

What's left takes someone who knows the repository:

1. **Fill in the Bindings.** The table maps the kit's rules onto your repository.
   Replace every `TODO`; `none: <why>` is a valid value, a blank is not.
   [`ai/INSTALL.md`](ai/INSTALL.md#3-fill-in-the-bindings) says how.

2. **Point your other tools at it.** Most coding agents read `AGENTS.md` by
   themselves. Some don't, or stop once their own file exists, and then the rules
   are silently inactive. [`ai/providers.md`](ai/providers.md#wire-the-entrypoints)
   says what to add, per tool.

3. **Check and commit:**

   ```sh
   ai/sync.sh --check .
   git add ai AGENTS.md   # plus any entrypoint files from step 2
   git commit
   ```

To read the script before running it, download it first and run your copy:

```sh
curl -fsSL https://raw.githubusercontent.com/kolchurinvv/ordain/main/install.sh -o /tmp/install.sh
bash /tmp/install.sh
```

[`ai/INSTALL.md`](ai/INSTALL.md) has the full procedure: worktree layouts,
installer options such as pinning a version with `--ref`, opening the pull
request, and removing the kit. To hand the adoption to an agent instead, paste
the prompt in [§ Adopting with an agent](ai/INSTALL.md#adopting-with-an-agent).

## Update

On a new branch, re-run the install line and commit the result on its own. Its
diff is exactly what changed in the kit.

## What's in the kit

[`ai/README.md`](ai/README.md) lists every module and explains the design.
