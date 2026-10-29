#!/usr/bin/env bash
# Vendor the ord-ai-n agent kit into a repository, or verify a vendored copy.
#
#   ai/sync.sh <repo>          Copy this kit's ai/ into <repo>/ai/, record what was copied in
#                              <repo>/ai/.kit-manifest, and regenerate the core block in
#                              <repo>/AGENTS.md from ai/CORE.md.
#   ai/sync.sh --check <repo>  Change nothing. Exit 1 if <repo>/ai/ differs from its manifest
#                              or <repo>/AGENTS.md's core block differs from ai/CORE.md.
#                              Cheap enough for CI: the drift guard that holds whichever
#                              agent or model made the change.
#
# The core block is everything between these two lines of AGENTS.md:
#
#   <!-- ord-ai-n:core:begin -->
#   <!-- ord-ai-n:core:end -->
#
# Place them by hand once, where the block should sit; this script never guesses a placement.
# Repo-specific values go in AGENTS.md's Bindings section, never in ai/: edits there fail
# --check and are overwritten by the next sync. See ai/README.md.

set -euo pipefail
export LC_ALL=C

BEGIN='<!-- ord-ai-n:core:begin -->'
END='<!-- ord-ai-n:core:end -->'
MANIFEST=ai/.kit-manifest

die() { echo "sync: $*" >&2; exit 1; }
usage() { echo "usage: ai/sync.sh [--check] <repo>" >&2; exit 2; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }
# The file paths a manifest lists, one per line.
listed() { grep -v '^#' "$1" | sed 's/^[0-9a-f]*  //' || true; }

check=0
case "${1:-}" in
  --check) check=1; shift ;;
  -h|--help|"") usage ;;
esac
[ $# -eq 1 ] || usage

kit_ai=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
kit_root=$(dirname "$kit_ai")
target=$(cd "$1" 2>/dev/null && pwd -P) || die "no such directory: $1"
agents="$target/AGENTS.md"

[ -f "$agents" ] || die "$agents not found: create it with a title and the two marker lines (ai/README.md)"
n_begin=$(grep -cxF "$BEGIN" "$agents" || true)
n_end=$(grep -cxF "$END" "$agents" || true)
[ "$n_begin" = 1 ] && [ "$n_end" = 1 ] ||
  die "$agents needs exactly one '$BEGIN' line and one '$END' line (found $n_begin and $n_end)"
begin_line=$(grep -nxF "$BEGIN" "$agents" | cut -d: -f1)
end_line=$(grep -nxF "$END" "$agents" | cut -d: -f1)
[ "$begin_line" -lt "$end_line" ] || die "the begin marker must come before the end marker in $agents"

if [ "$check" = 1 ]; then
  cd "$target"
  [ -f ai/CORE.md ] || die "$target/ai/CORE.md not found: the kit is not vendored here"
  status=0
  if ! block_diff=$(sed -n "$((begin_line + 1)),$((end_line - 1))p" AGENTS.md |
                    diff -u -L ai/CORE.md -L 'AGENTS.md core block' ai/CORE.md -); then
    echo "sync: AGENTS.md's core block was edited in place. Put repo-specific values in Bindings;" >&2
    echo "      change the core in ord-ai-n and re-sync. Difference:" >&2
    echo "$block_diff" >&2
    status=1
  fi
  # The kit's own checkout has no manifest; a vendored copy always does.
  if [ -f "$MANIFEST" ]; then
    if ! out=$(grep -v '^#' "$MANIFEST" | sha -c --quiet - 2>&1); then
      echo "sync: vendored kit files were edited in place; change them in ord-ai-n and re-sync:" >&2
      echo "$out" >&2
      status=1
    fi
    if git rev-parse --git-dir >/dev/null 2>&1; then
      present=$(git ls-files ai | grep -vxF "$MANIFEST" || true)
    else
      present=$(find ai -type f ! -path "$MANIFEST" | sort)
    fi
    extra=$(comm -13 <(listed "$MANIFEST" | sort) <(echo "$present" | sort) | grep . || true)
    if [ -n "$extra" ]; then
      echo "sync: files under ai/ that the kit does not ship (repo-specific files belong outside ai/):" >&2
      echo "$extra" | sed 's/^/  /' >&2
      status=1
    fi
  fi
  [ "$status" = 0 ] && echo "sync: agent kit in sync"
  exit "$status"
fi

# What to copy, and from which kit version. A vendored copy re-syncs from its own manifest;
# a kit checkout ships its tracked files.
if [ -f "$kit_root/$MANIFEST" ]; then
  files=$(listed "$kit_root/$MANIFEST")
  version=$(sed -n 's/^# source: ord-ai-n //p' "$kit_root/$MANIFEST")
elif git -C "$kit_root" rev-parse --git-dir >/dev/null 2>&1; then
  # Tracked plus not-yet-added files: what the kit's next commit would ship.
  files=$(cd "$kit_root" && git ls-files --cached --others --exclude-standard ai |
          while IFS= read -r f; do if [ -f "$f" ]; then echo "$f"; fi; done | sort -u)
  version=$(git -C "$kit_root" describe --always)
  [ -z "$(git -C "$kit_root" status --porcelain -- ai)" ] || version="$version-dirty"
else
  files=$(cd "$kit_root" && find ai -type f | sort)
  version=unknown
fi
[ -n "$files" ] || die "no kit files found under $kit_ai"

if [ "$target" != "$kit_root" ]; then
  if [ -f "$target/$MANIFEST" ]; then
    # Drop files an earlier sync copied that the kit no longer ships.
    comm -23 <(listed "$target/$MANIFEST" | sort) <(echo "$files" | sort) |
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        rm -f "$target/$f" && echo "sync: removed $f (no longer in the kit)"
      done
  fi
  while IFS= read -r f; do
    mkdir -p "$target/$(dirname "$f")"
    cp -p "$kit_root/$f" "$target/$f"
  done <<<"$files"
  {
    echo "# ord-ai-n agent kit, vendored by ai/sync.sh. Do not edit the files listed here:"
    echo "# change them in ord-ai-n and re-sync. Verify with: ai/sync.sh --check ."
    echo "# source: ord-ai-n $version"
    (cd "$target" && while IFS= read -r f; do sha "$f"; done <<<"$files")
  } >"$target/$MANIFEST"
fi

# Regenerate the core block. Write through the existing file to keep its permissions.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
{
  head -n "$begin_line" "$agents"
  cat "$kit_ai/CORE.md"
  tail -n "+$end_line" "$agents"
} >"$tmp"
cat "$tmp" >"$agents"

echo "sync: $target now carries ord-ai-n $version"
case "$version" in
  *-dirty) echo "sync: the kit has uncommitted changes; commit them and re-sync before committing $target" >&2 ;;
esac
