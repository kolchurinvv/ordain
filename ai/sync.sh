#!/usr/bin/env bash
# Vendor the ord-ai-n agent kit into a repository, or verify a vendored copy.
#
#   ai/sync.sh [--force] <repo>
#                              Copy this kit's ai/ into <repo>/ai/, record what was copied in
#                              <repo>/ai/.kit-manifest, and regenerate the core block in
#                              <repo>/AGENTS.md from ai/CORE.md. AGENTS.md is created if it is
#                              missing, and gets the markers and the Bindings skeleton if it
#                              lacks them.
#                              Run it from an ord-ai-n checkout. It refuses to overwrite what
#                              it didn't write (an ai/ with no manifest, uncommitted edits
#                              under ai/) unless --force is given.
#   ai/sync.sh --check <repo>  Change nothing. Exit 1 if <repo>/ai/ differs from its manifest or
#                              <repo>/AGENTS.md's core block differs from ai/CORE.md. Exit 3 if
#                              only the Bindings are unfinished: a placeholder in the skeleton
#                              (ai/INSTALL.md) has no row, or a row is blank or still says TODO.
#                              Cheap enough for CI: the drift guard that holds whichever
#                              agent or model made the change.
#                              This is the only mode a vendored copy runs.
#
# The core block is everything between these two lines of AGENTS.md:
#
#   <!-- ord-ai-n:core:begin -->
#   <!-- ord-ai-n:core:end -->
#
# A sync adds them if AGENTS.md has neither: before the first heading after the title, or at
# the end. Move them if the block belongs elsewhere; later syncs leave them where they are.
# Repo-specific values go in AGENTS.md's Bindings section, never in ai/: edits there fail
# --check and are overwritten by the next sync. See ai/README.md.

set -euo pipefail
export LC_ALL=C

BEGIN='<!-- ord-ai-n:core:begin -->'
END='<!-- ord-ai-n:core:end -->'
MANIFEST=ai/.kit-manifest

die() { echo "sync: $*" >&2; exit 1; }
usage() { echo "usage: ai/sync.sh [--check | --force] <repo>" >&2; exit 2; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }
# The file paths a manifest lists, one per line.
listed() { grep -v '^#' "$1" | sed 's/^[0-9a-f]*  //' || true; }
# The Bindings skeleton in ai/INSTALL.md: what follows its heading, up to the closing fence.
skeleton() {
  [ -f "$1" ] || return 0
  # shellcheck disable=SC2016  # the backticks are literal Markdown, not expansions
  awk '/^## Bindings$/{s=1; next} s && /^```/{exit} s' "$1"
}
# Placeholders that skeleton asks every repository to bind.
skeleton_placeholders() {
  # shellcheck disable=SC2016  # the backticks are literal Markdown, not expansions
  skeleton "$1" | grep -o '^| `<[a-z0-9-]*>`' | sed 's/^| `//; s/`$//' | sort -u || true
}
# Of those, the ones AGENTS.md never mentions after the core block, i.e. in its Bindings.
unbound() {  # $1 = AGENTS.md, $2 = ai/INSTALL.md, $3 = line of the end marker
  skeleton_placeholders "$2" | while IFS= read -r p; do
    [ -n "$p" ] || continue
    tail -n "+$(($3 + 1))" "$1" | grep -qF "\`$p\`" || echo "$p"
  done
}
# Bindings rows still to fill in: their value is blank or starts with the skeleton's TODO.
unfilled() {  # $1 = AGENTS.md, $2 = line of the end marker
  awk -F'|' -v from="$2" '
    NR <= from { next }
    /^#+[ \t]/ { s = ($0 ~ /^#+[ \t]+Bindings([ \t\r]|$)/); next }
    s && /^\|/ && $3 ~ /^[ \t]*(TODO|$)/ { print $2 }' "$1" | sed 's/^ *//; s/ *$//'
}
# Give AGENTS.md what a sync needs: create it if it is missing, and add the markers if it has
# neither. Markers that differ only by surrounding whitespace are straightened. Anything else
# is left for locate_markers to refuse.
place_markers() {
  local counts content
  if [ ! -f "$agents" ]; then
    printf '# AGENTS.md\n\n%s\n%s\n' "$BEGIN" "$END" >"$agents"
    return 0
  fi
  counts=$(awk -v b="$BEGIN" -v e="$END" '
    { t = $0; gsub(/^[ \t]+|[ \t\r]+$/, "", t); if (t == b) nb++; if (t == e) ne++ }
    END { print nb + 0, ne + 0 }' "$agents")
  case "$counts" in
    "1 1")
      content=$(awk -v b="$BEGIN" -v e="$END" '
        { t = $0; gsub(/^[ \t]+|[ \t\r]+$/, "", t); if (t == b || t == e) print t; else print }
      ' "$agents") ;;
    "0 0")
      # Before the first heading that isn't the opening title; "# x" in a code fence is no heading.
      content=$(awk -v b="$BEGIN" -v e="$END" '
        function put() { if (prev != "") print ""; print b; print e }
        /^[ \t]*(```|~~~)/ { fence = !fence }
        !fence && /^#+[ \t]/ {
          if (!done && (seen || !/^#[ \t]/)) { put(); print ""; done = 1 }
          seen = 1
        }
        { print; prev = $0 }
        END { if (!done) put() }' "$agents") ;;
    *) return 0 ;;
  esac
  # Write through the existing file to keep its permissions.
  [ "$content" = "$(cat "$agents")" ] || printf '%s\n' "$content" >"$agents"
}
# Find the two markers, which must be exact, single and in order.
locate_markers() {
  [ -f "$agents" ] || die "$agents not found: the kit is not installed here (ai/INSTALL.md)"
  n_begin=$(grep -cxF "$BEGIN" "$agents" || true)
  n_end=$(grep -cxF "$END" "$agents" || true)
  [ "$n_begin" = 1 ] && [ "$n_end" = 1 ] ||
    die "$agents needs exactly one '$BEGIN' line and one '$END' line, unindented (found $n_begin and $n_end)"
  begin_line=$(grep -nxF "$BEGIN" "$agents" | cut -d: -f1)
  end_line=$(grep -nxF "$END" "$agents" | cut -d: -f1)
  [ "$begin_line" -lt "$end_line" ] || die "the begin marker must come before the end marker in $agents"
}
# Whether AGENTS.md has a Bindings section outside the core block.
has_bindings() {
  awk -v b="$begin_line" -v e="$end_line" '
    (NR < b || NR > e) && /^#+[ \t]+Bindings([ \t\r]|$)/ { found = 1 }
    END { exit !found }' "$agents"
}

check=0
force=0
while [ $# -gt 0 ]; do
  case "$1" in
    --check) check=1 ;;
    --force) force=1 ;;
    -*) usage ;;
    *) break ;;
  esac
  shift
done
[ $# -eq 1 ] || usage

kit_ai=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
kit_root=$(dirname "$kit_ai")
target=$(cd "$1" 2>/dev/null && pwd -P) || die "no such directory: $1"
agents="$target/AGENTS.md"

if [ "$check" = 1 ]; then
  locate_markers
  cd "$target"
  [ -f ai/CORE.md ] || die "$target/ai/CORE.md not found: the kit is not vendored here"
  status=0
  unfinished=0
  if ! block_diff=$(sed -n "$((begin_line + 1)),$((end_line - 1))p" AGENTS.md |
                    diff -u -L ai/CORE.md -L 'AGENTS.md core block' ai/CORE.md -); then
    echo "sync: AGENTS.md's core block was edited in place. Put repo-specific values in Bindings;" >&2
    echo "      change the core in ord-ai-n and re-sync. Difference:" >&2
    echo "$block_diff" >&2
    status=1
  fi
  missing=$(unbound AGENTS.md ai/INSTALL.md "$end_line")
  if [ -n "$missing" ]; then
    echo "sync: AGENTS.md's Bindings have no row for (see ai/INSTALL.md step 3):" >&2
    echo "$missing" | sed 's/^/  /' >&2
    unfinished=1
  fi
  todo=$(unfilled AGENTS.md "$end_line")
  if [ -n "$todo" ]; then
    echo "sync: AGENTS.md's Bindings still have rows to fill in (see ai/INSTALL.md step 3):" >&2
    echo "$todo" | sed 's/^/  /' >&2
    unfinished=1
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
  [ "$status" = 0 ] || exit "$status"
  [ "$unfinished" = 0 ] || exit 3
  echo "sync: agent kit in sync"
  exit 0
fi

# Refuse to overwrite what this script didn't write. A vendored copy (it has a manifest) only
# checks: syncing from it would copy a stale kit over the target, and dropping a manifest into
# a kit checkout would freeze its file list.
[ ! -f "$kit_root/$MANIFEST" ] ||
  die "$kit_ai is a vendored copy; it only runs --check. Sync from an ord-ai-n checkout."
if [ "$target" != "$kit_root" ] && [ "$force" = 0 ]; then
  [ ! -d "$target/ai" ] || [ -f "$target/$MANIFEST" ] ||
    die "$target/ai exists but sync.sh didn't write it, and syncing would overwrite it. Move it, or pass --force."
  if [ -d "$target/ai" ] && git -C "$target" rev-parse --git-dir >/dev/null 2>&1 &&
     [ -n "$(git -C "$target" status --porcelain -- ai)" ]; then
    die "$target/ai has uncommitted changes that syncing would overwrite. Commit or drop them, or pass --force."
  fi
fi

# What to copy, and which kit version it is. install.sh names a downloaded kit through
# ORD_AI_N_SOURCE; a local checkout is named by its commit.
if git -C "$kit_root" rev-parse --git-dir >/dev/null 2>&1; then
  # Tracked plus not-yet-added files: what the kit's next commit would ship.
  files=$(cd "$kit_root" && git ls-files --cached --others --exclude-standard ai |
          while IFS= read -r f; do if [ -f "$f" ]; then echo "$f"; fi; done | sort -u)
  version="ord-ai-n@$(git -C "$kit_root" describe --always)"
  [ -z "$(git -C "$kit_root" status --porcelain -- ai)" ] || version="$version-dirty"
else
  files=$(cd "$kit_root" && find ai -type f | sort)
  version=unknown
fi
version=${ORD_AI_N_SOURCE:-$version}
[ -n "$files" ] || die "no kit files found under $kit_ai"

# Past every refusal: nothing above has written to the target.
place_markers
locate_markers
bindings=
if ! has_bindings; then
  bindings=$(skeleton "$kit_ai/INSTALL.md")
  [ -n "$bindings" ] || die "no Bindings skeleton in $kit_ai/INSTALL.md"
fi

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
    echo "# change them in ord-ai-n and re-run its installer (ai/INSTALL.md). Verify: ai/sync.sh --check ."
    echo "# source: $version"
    (cd "$target" && while IFS= read -r f; do sha "$f"; done <<<"$files")
  } >"$target/$MANIFEST"
fi

# Regenerate the core block. Write through the existing file to keep its permissions.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
{
  head -n "$begin_line" "$agents"
  cat "$kit_ai/CORE.md"
  sed -n "${end_line}p" "$agents"
  if [ -n "$bindings" ]; then
    printf '\n## Bindings\n%s\n' "$bindings"
    # Keep text that follows the end marker directly out of the table.
    [ -z "$(sed -n "$((end_line + 1))p" "$agents")" ] || echo
  fi
  tail -n "+$((end_line + 1))" "$agents"
} >"$tmp"
cat "$tmp" >"$agents"

echo "sync: $target now carries $version"
end_line=$(grep -nxF "$END" "$agents" | cut -d: -f1)
missing=$(unbound "$agents" "$target/ai/INSTALL.md" "$end_line")
if [ -n "$missing" ]; then
  echo "sync: add Bindings rows for these, or --check fails (ai/INSTALL.md step 3):" >&2
  echo "$missing" | sed 's/^/  /' >&2
fi
case "$version" in
  *-dirty) echo "sync: the kit has uncommitted changes; commit them and re-sync before committing $target" >&2 ;;
esac
