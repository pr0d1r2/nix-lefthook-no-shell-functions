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
HEREDOC_DELIM_RE=$'^(-?)[[:space:]]*(\\\\|[\'"])?([a-zA-Z_][a-zA-Z_0-9]*)'

failed=0
for file in "$@"; do
  [ -f "$file" ] || continue
  case "$file" in
    *.bats) continue ;;
  esac

  state=normal
  heredoc_delim=""
  heredoc_strip=0
  lineno=0
  while IFS= read -r raw || [ -n "$raw" ]; do
    lineno=$((lineno + 1))

    if [ "$state" = heredoc ]; then
      end_line="$raw"
      if [ "$heredoc_strip" -eq 1 ]; then
        while [[ "$end_line" == $'\t'* ]]; do
          end_line="${end_line#$'\t'}"
        done
      fi
      if [ "$end_line" = "$heredoc_delim" ]; then
        state=normal
      fi
      continue
    fi

    check_func=1
    if [ "$state" != normal ]; then
      check_func=0
    fi

    i=0
    while [ "$i" -lt "${#raw}" ]; do
      ch="${raw:$i:1}"
      case "$state" in
        normal)
          case "$ch" in
            \') state=single_quote ;;
            \") state=double_quote ;;
            \#) break ;;
            \<)
              if [ "${raw:$((i + 1)):1}" = '<' ]; then
                rest="${raw:$((i + 2))}"
                if [[ "$rest" =~ $HEREDOC_DELIM_RE ]]; then
                  heredoc_strip=0
                  [[ "${BASH_REMATCH[1]}" = "-" ]] && heredoc_strip=1
                  heredoc_delim="${BASH_REMATCH[3]}"
                  state=heredoc
                  break
                fi
              fi
              ;;
          esac
          ;;
        single_quote)
          [ "$ch" = "'" ] && state=normal
          ;;
        double_quote)
          if [ "$ch" = "\\" ]; then
            i=$((i + 1))
          elif [ "$ch" = '"' ]; then
            state=normal
          fi
          ;;
      esac
      i=$((i + 1))
    done

    if [ "$check_func" -eq 1 ] && [[ "$raw" =~ $FUNC_RE ]]; then
      name="${BASH_REMATCH[0]}"
      printf '%s:%d: shell function definition: %s\n' "$file" "$lineno" "$name" >&2
      failed=1
    fi
  done <"$file"
done

exit "$failed"
