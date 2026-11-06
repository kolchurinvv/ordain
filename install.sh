#!/usr/bin/env bash
# Install or update the ord-ai-n agent kit in a repository, straight from GitHub:
#
#   curl -fsSL https://raw.githubusercontent.com/kolchurinvv/ordain/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- [--ref <branch|tag|sha>] [--force] [<repo>]
#
# <repo> defaults to the current directory. The kit is downloaded at one exact commit and its
# own ai/sync.sh does the work, so the repo's ai/.kit-manifest records exactly what was
# installed (github.com/<owner>/<name>@<sha>). Re-run the same line to update. An update that
# changes rules leaves --check at exit 3, listing them, until the repo has reconciled its own text
# (ai/AMENDMENTS.md).
#
# The kit repo is public, so this script reads it anonymously and never sends a credential.
#
# ORD_AI_N_REPO=<owner>/<name>  install from a public fork (default kolchurinvv/ordain).
# ORD_AI_N_TARBALL=<url>        install from that .tar.gz instead: a mirror, or file:// for a
#                               private fork's tarball you downloaded, or a local build to test.
#                               The manifest records it.

set -euo pipefail

repo=${ORD_AI_N_REPO:-kolchurinvv/ordain}
ref=main
target=.
force=()

die() { echo "install: $*" >&2; exit 1; }
usage() { echo "usage: install.sh [--ref <branch|tag|sha>] [--force] [<repo>]" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --ref) [ $# -ge 2 ] || usage; ref=$2; shift ;;
    --force) force=(--force) ;;
    -h|--help) usage ;;
    -*) usage ;;
    *) target=$1 ;;
  esac
  shift
done

for tool in curl tar; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool is required"
done
target=$(cd "$target" 2>/dev/null && pwd -P) || die "no such directory: $target"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ -n "${ORD_AI_N_TARBALL:-}" ]; then
  source=$ORD_AI_N_TARBALL
  curl -fsSL "$source" | tar -xzf - -C "$tmp" --strip-components=1 ||
    die "cannot download or unpack $source"
else
  # Pin the ref to a commit first, so the files and the recorded version can't disagree.
  sha=$(curl -fsSL -H "Accept: application/vnd.github.sha" \
          "https://api.github.com/repos/$repo/commits/$ref") ||
    die "cannot resolve '$ref' in github.com/$repo (wrong ref or repo, or GitHub's API rate limit)"
  source="github.com/$repo@$sha"
  curl -fsSL "https://api.github.com/repos/$repo/tarball/$sha" |
    tar -xzf - -C "$tmp" --strip-components=1 ||
    die "cannot download or unpack $source"
fi

[ -f "$tmp/ai/sync.sh" ] || die "$source has no ai/sync.sh; that kit version predates this installer"
ORD_AI_N_SOURCE=$source bash "$tmp/ai/sync.sh" ${force[@]+"${force[@]}"} "$target"
echo "install: point tools that don't read AGENTS.md at it (ai/providers.md), review the diff, and commit the result on its own"
echo "install: then reconcile any amendments listed above, in a separate commit (ai/INSTALL.md § Update)"
