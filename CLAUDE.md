# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Status

This repository is in its initial scaffold stage. The only contents are a Nix flake
(`flake.nix` / `flake.lock`) defining a development shell. There is no application
source code, package manifest, build system, or tests yet. Expand this file as the
project takes shape.

## Development environment

The project uses Nix flakes (nixpkgs `nixos-unstable`) to provide a reproducible dev shell
across `x86_64`/`aarch64` Linux and Darwin.

- Enter the dev shell: `nix develop`
- The `devShells.default` currently declares no `packages`. Add tools/dependencies there
  (in `flake.nix`) rather than installing them globally, then re-enter the shell.
- After editing flake inputs, refresh the lock with `nix flake update`.

## Notes

- The project name is `ord-ai-n`.
