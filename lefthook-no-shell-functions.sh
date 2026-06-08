# shellcheck shell=bash
# Lefthook-compatible shell function detector.
# Flags function definitions in .sh files.
# .bats files are skipped (bats uses setup/teardown as framework primitives).
# Usage: lefthook-no-shell-functions file1.sh [file2.sh ...]
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ $# -eq 0 ]; then
  exit 0
fi

FUNC_RE='^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)|function[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*([[:space:]]*\(\))?)'

failed=0
for file in "$@"; do
  [ -f "$file" ] || continue
  case "$file" in
    *.bats) continue ;;
  esac

  lineno=0
  while IFS= read -r raw || [ -n "$raw" ]; do
    lineno=$((lineno + 1))
    if [[ "$raw" =~ $FUNC_RE ]]; then
      name="${BASH_REMATCH[0]}"
      printf '%s:%d: shell function definition: %s\n' "$file" "$lineno" "$name" >&2
      failed=1
    fi
  done <"$file"
done

exit "$failed"
