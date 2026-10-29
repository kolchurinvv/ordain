#!/usr/bin/env bash
# Install or update the ord-ai-n agent kit in a repository, straight from GitHub:
#
#   curl -fsSL https://raw.githubusercontent.com/kolchurinvv/ordain/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- [--ref <branch|tag|sha>] [--force] [<repo>]
#
# <repo> defaults to the current directory. The kit is downloaded at one exact commit and its
# own ai/sync.sh does the work, so the repo's ai/.kit-manifest records exactly what was
# installed (github.com/<owner>/<name>@<sha>). Re-run the same line to update.
#
# While the kit repo is private, authenticate the first download too:
#   curl -fsSL -H "Authorization: Bearer $(gh auth token)" .../install.sh | bash
# This script then authenticates with $GITHUB_TOKEN, or `gh auth token` when gh is logged in.
#
# ORD_AI_N_REPO=<owner>/<name>  install from a fork (default kolchurinvv/ordain).
# ORD_AI_N_TARBALL=<url>        install from that .tar.gz instead: a mirror, or file:// to test
#                               a local build. No token is sent to it; the manifest records it.

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
  token=${GITHUB_TOKEN:-}
  if [ -z "$token" ] && command -v gh >/dev/null 2>&1; then
    token=$(gh auth token 2>/dev/null || true)
  fi
  auth=()
  [ -z "$token" ] || auth=(-H "Authorization: Bearer $token")
  # Pin the ref to a commit first, so the files and the recorded version can't disagree.
  sha=$(curl -fsSL ${auth[@]+"${auth[@]}"} -H "Accept: application/vnd.github.sha" \
          "https://api.github.com/repos/$repo/commits/$ref") ||
    die "cannot resolve '$ref' in github.com/$repo (private? set GITHUB_TOKEN or run gh auth login)"
  source="github.com/$repo@$sha"
  # GitHub answers with a redirect to a pre-signed URL; curl drops the token at that hop.
  curl -fsSL ${auth[@]+"${auth[@]}"} "https://api.github.com/repos/$repo/tarball/$sha" |
    tar -xzf - -C "$tmp" --strip-components=1 ||
    die "cannot download or unpack $source"
fi

[ -f "$tmp/ai/sync.sh" ] || die "$source has no ai/sync.sh; that kit version predates this installer"
ORD_AI_N_SOURCE=$source bash "$tmp/ai/sync.sh" ${force[@]+"${force[@]}"} "$target"
echo "install: review the diff, keep AGENTS.md's Bindings current, and commit the result on its own"
