# Changelog

All notable changes to this project are documented here.

## Unreleased

- Refresh `nixpkgs-lock` in `flake.lock`. ruby CVE-2026-97229 (#99) is not
  yet fixed upstream (nixos-26.05 still ships ruby 3.4.11, backport tracked in
  pr0d1r2/nixpkgs-lock#94); this repo does not use ruby, so no override.
  Re-run `nix flake update nixpkgs-lock` once the backport lands.
- Pin the CI guardrails reusable workflow to a full commit SHA (`ci-lint-sha`).
- Add a quiet `.coderabbit.yaml`; list `.yaml` (yamllint) in the linter
  extension table.
- Describe this repo's `SPEC.md` notation (three-field §T rows, numbered §B
  list) in the `.coderabbit.yaml` path instructions.
