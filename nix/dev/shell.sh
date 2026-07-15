# shellcheck shell=bash
export BATS_LIB_PATH="@BATS_LIB_PATH@/share/bats"
bash scripts/materialize-lefthook.sh
hooks_path="$(git config --path core.hooksPath 2>/dev/null || true)"
[ -n "$hooks_path" ] || hooks_path=".git/hooks"
[ -f "$hooks_path/pre-commit" ] || lefthook install
