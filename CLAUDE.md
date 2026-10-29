@AGENTS.md

# Claude Code notes

`AGENTS.md` (imported above) is the contract. This file holds only what is
specific to Claude Code here; Claude Code reads `AGENTS.md` on its own only when
no `CLAUDE.md` exists, which is why this file imports it (`ai/providers.md`).

## Development environment

The project uses Nix flakes (nixpkgs `nixos-unstable`) to provide a reproducible dev shell
across `x86_64`/`aarch64` Linux and Darwin.

- Enter the dev shell: `nix develop`
- The `devShells.default` currently declares no `packages`. Add tools/dependencies there
  (in `flake.nix`) rather than installing them globally, then re-enter the shell.
- After editing flake inputs, refresh the lock with `nix flake update`.
