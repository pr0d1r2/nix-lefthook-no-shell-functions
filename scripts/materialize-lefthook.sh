# shellcheck shell=bash
# Materialize lefthook.yml from repo content.
# Content-aware: only wires linters for tracked file types.

set -euo pipefail

has_sh="$(git ls-files '*.sh' | head -1)"
has_bats="$(git ls-files '*.bats' | head -1)"
has_nix="$(git ls-files '*.nix' | head -1)"
has_md="$(git ls-files '*.md' | head -1)"
has_yml="$(git ls-files -- '*.yml' '*.yaml' | head -1)"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

cat >"$tmp" <<'YAML'
---

pre-commit:
  commands:
YAML

if [ -n "$has_bats" ]; then
  cat >>"$tmp" <<'YAML'
    bats-unit:
      glob: "*.bats"
      run: timeout ${LEFTHOOK_BATS_UNIT_TIMEOUT:-60} lefthook-bats-unit {staged_files}
YAML
fi

cat >>"$tmp" <<'YAML'
    editorconfig-checker:
      run: timeout ${LEFTHOOK_EDITORCONFIG_CHECKER_TIMEOUT:-30} lefthook-editorconfig-checker {staged_files}
    file-size-check:
      run: timeout ${LEFTHOOK_FILE_SIZE_CHECK_TIMEOUT:-30} lefthook-file-size-check {staged_files}
    git-conflict-markers:
      run: timeout ${LEFTHOOK_GIT_CONFLICT_MARKERS_TIMEOUT:-30} lefthook-git-conflict-markers {staged_files}
YAML

if [ -n "$has_nix" ]; then
  cat >>"$tmp" <<'YAML'
    git-no-local-paths:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_GIT_NO_LOCAL_PATHS_TIMEOUT:-30} lefthook-git-no-local-paths {staged_files}
YAML
fi

if [ -n "$has_md" ]; then
  cat >>"$tmp" <<'YAML'
    markdownlint:
      glob: "*.md"
      exclude:
        - "^(\\.claude/skills/)"
      run: timeout ${LEFTHOOK_MARKDOWNLINT_TIMEOUT:-30} lefthook-markdownlint {staged_files}
    markdownlint-agentic:
      glob: "*.md"
      exclude:
        - "^(README|CHANGELOG|SPEC|CONTRIBUTING)\\.md$"
      run: timeout ${LEFTHOOK_MARKDOWNLINT_AGENTIC_TIMEOUT:-30} lefthook-markdownlint-agentic {staged_files}
YAML
fi

cat >>"$tmp" <<'YAML'
    missing-final-newline:
      run: timeout ${LEFTHOOK_MISSING_FINAL_NEWLINE_TIMEOUT:-30} lefthook-missing-final-newline {staged_files}
YAML

if [ -n "$has_nix" ]; then
  cat >>"$tmp" <<'YAML'
    nix-no-embedded-shell:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_NIX_NO_EMBEDDED_SHELL_TIMEOUT:-30} lefthook-nix-no-embedded-shell {staged_files}
    nixfmt:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_NIXFMT_TIMEOUT:-30} lefthook-nixfmt {staged_files}
YAML
fi

if [ -n "$has_sh" ]; then
  cat >>"$tmp" <<'YAML'
    no-shell-functions:
      glob: "*.sh"
      run: timeout ${LEFTHOOK_NO_SHELL_FUNCTIONS_TIMEOUT:-30} lefthook-no-shell-functions {staged_files}
    shellcheck:
      glob: "*.sh"
      run: timeout ${LEFTHOOK_SHELLCHECK_TIMEOUT:-30} lefthook-shellcheck {staged_files}
    shfmt:
      glob: "*.sh"
      run: timeout ${LEFTHOOK_SHFMT_TIMEOUT:-30} lefthook-shfmt {staged_files}
YAML
fi

if [ -n "$has_nix" ]; then
  cat >>"$tmp" <<'YAML'
    statix:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_STATIX_TIMEOUT:-30} lefthook-statix {staged_files}
    deadnix:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_DEADNIX_TIMEOUT:-30} lefthook-deadnix {staged_files}
YAML
fi

cat >>"$tmp" <<'YAML'
    trailing-whitespace:
      run: timeout ${LEFTHOOK_TRAILING_WHITESPACE_TIMEOUT:-30} lefthook-trailing-whitespace {staged_files}
    typos:
      run: timeout ${LEFTHOOK_TYPOS_TIMEOUT:-30} lefthook-typos {staged_files}
YAML

if [ -n "$has_yml" ]; then
  cat >>"$tmp" <<'YAML'
    yamllint:
      glob: "*.{yml,yaml}"
      run: timeout ${LEFTHOOK_YAMLLINT_TIMEOUT:-30} lefthook-yamllint {staged_files}
YAML
fi

cat >>"$tmp" <<'YAML'

pre-push:
  commands:
YAML

if [ -n "$has_bats" ]; then
  cat >>"$tmp" <<'YAML'
    bats-unit:
      glob: "*.bats"
      run: timeout ${LEFTHOOK_BATS_UNIT_TIMEOUT:-60} lefthook-bats-unit {push_files}
YAML
fi

cat >>"$tmp" <<'YAML'
    editorconfig-checker:
      run: timeout ${LEFTHOOK_EDITORCONFIG_CHECKER_TIMEOUT:-30} lefthook-editorconfig-checker {push_files}
    file-size-check:
      run: timeout ${LEFTHOOK_FILE_SIZE_CHECK_TIMEOUT:-30} lefthook-file-size-check {push_files}
    git-conflict-markers:
      run: timeout ${LEFTHOOK_GIT_CONFLICT_MARKERS_TIMEOUT:-30} lefthook-git-conflict-markers {push_files}
YAML

if [ -n "$has_nix" ]; then
  cat >>"$tmp" <<'YAML'
    git-no-local-paths:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_GIT_NO_LOCAL_PATHS_TIMEOUT:-30} lefthook-git-no-local-paths {push_files}
YAML
fi

if [ -n "$has_md" ]; then
  cat >>"$tmp" <<'YAML'
    markdownlint:
      glob: "*.md"
      exclude:
        - "^(\\.claude/skills/)"
      run: timeout ${LEFTHOOK_MARKDOWNLINT_TIMEOUT:-30} lefthook-markdownlint {push_files}
    markdownlint-agentic:
      glob: "*.md"
      exclude:
        - "^(README|CHANGELOG|SPEC|CONTRIBUTING)\\.md$"
      run: timeout ${LEFTHOOK_MARKDOWNLINT_AGENTIC_TIMEOUT:-30} lefthook-markdownlint-agentic {push_files}
YAML
fi

cat >>"$tmp" <<'YAML'
    missing-final-newline:
      run: timeout ${LEFTHOOK_MISSING_FINAL_NEWLINE_TIMEOUT:-30} lefthook-missing-final-newline {push_files}
YAML

if [ -n "$has_nix" ]; then
  cat >>"$tmp" <<'YAML'
    nix-no-embedded-shell:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_NIX_NO_EMBEDDED_SHELL_TIMEOUT:-30} lefthook-nix-no-embedded-shell {push_files}
    nixfmt:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_NIXFMT_TIMEOUT:-30} lefthook-nixfmt {push_files}
YAML
fi

if [ -n "$has_sh" ]; then
  cat >>"$tmp" <<'YAML'
    no-shell-functions:
      glob: "*.sh"
      run: timeout ${LEFTHOOK_NO_SHELL_FUNCTIONS_TIMEOUT:-30} lefthook-no-shell-functions {push_files}
    shellcheck:
      glob: "*.sh"
      run: timeout ${LEFTHOOK_SHELLCHECK_TIMEOUT:-30} lefthook-shellcheck {push_files}
    shfmt:
      glob: "*.sh"
      run: timeout ${LEFTHOOK_SHFMT_TIMEOUT:-30} lefthook-shfmt {push_files}
YAML
fi

if [ -n "$has_nix" ]; then
  cat >>"$tmp" <<'YAML'
    statix:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_STATIX_TIMEOUT:-30} lefthook-statix {push_files}
    deadnix:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_DEADNIX_TIMEOUT:-30} lefthook-deadnix {push_files}
YAML
fi

cat >>"$tmp" <<'YAML'
    trailing-whitespace:
      run: timeout ${LEFTHOOK_TRAILING_WHITESPACE_TIMEOUT:-30} lefthook-trailing-whitespace {push_files}
    typos:
      run: timeout ${LEFTHOOK_TYPOS_TIMEOUT:-30} lefthook-typos {push_files}
YAML

if [ -n "$has_yml" ]; then
  cat >>"$tmp" <<'YAML'
    yamllint:
      glob: "*.{yml,yaml}"
      run: timeout ${LEFTHOOK_YAMLLINT_TIMEOUT:-30} lefthook-yamllint {push_files}
YAML
fi

mv "$tmp" lefthook.yml
