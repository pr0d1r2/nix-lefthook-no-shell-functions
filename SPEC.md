# SPEC

## §D — Description

`nix-lefthook-no-shell-functions` is a Nix-flake-packaged lefthook linter that detects shell function definitions in `.sh` files, enforcing a modularity convention where scripts must not contain functions but instead delegate to separate scripts invoked in-place. It scans for POSIX-style (`name()`), keyword-style (`function name`), and combined (`function name()`) declarations, skips `.bats` files (which use functions as framework primitives), and exits 0 when given no arguments or no matching files. The tool is distributed both as a standalone Nix package and as a lefthook remote configuration, targeting Nix-based development environments on Linux and macOS (arm64 and x86_64).

## §V — Invariants

1. The detector must exit 0 when invoked with no arguments.
2. Non-existent files passed as arguments must be silently skipped (exit 0 if no other failures).
3. Files ending in `.bats` must always be skipped regardless of content.
4. Any `.sh` file containing a POSIX-style (`name()`), keyword-style (`function name`), or combined (`function name()`) function definition must cause a non-zero exit.
5. All function violations must be reported to stderr with format `file:line: shell function definition: <match>`.
6. Every lefthook command must have a `timeout` wrapper with a configurable environment variable default.
7. Every check must appear in both `pre-commit` (operating on `{staged_files}`) and `pre-push` (operating on `{push_files}`).
8. The Nix flake must build on all four supported systems: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`.
9. All shell scripts must have 1-to-1 bats unit test coverage under `tests/unit/`.
10. No shell functions are permitted in any `.sh` file in the repo (the project enforces this on itself).
11. No embedded shell scripts in Nix files; shell logic must be extracted to `.sh` files.
12. CI must run on both Linux and macOS.
13. Every file type tracked in git must have an assigned linter in `lefthook.yml`.

## §I — Interfaces

### CLI

```text
lefthook-no-shell-functions [file1.sh file2.sh ...]
```

- **Arguments**: Zero or more file paths. Typically supplied by lefthook via `{staged_files}` or `{push_files}`.
- **Exit 0**: No arguments, all files skipped (`.bats` / non-existent), or no function definitions found.
- **Exit 1**: At least one function definition detected. Violations printed to stderr.

### Nix flake outputs

| Output | Description |
| --- | --- |
| `packages.<system>.default` | `writeShellApplication` wrapping `lefthook-no-shell-functions.sh` |
| `devShells.<system>.default` | Dev shell with the tool, bats, lefthook, and all remote linter wrappers |
| `devShells.<system>.ci` | Alias for `default` |

### Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `LEFTHOOK_NO_SHELL_FUNCTIONS_TIMEOUT` | `30` | Timeout in seconds for the lefthook command |
| `BATS_LIB_PATH` | Set by `nix/dev/shell.sh` | Path to bats helper libraries (bats-support, bats-assert, bats-file) |

### Configuration files

| File | Format | Purpose |
| --- | --- | --- |
| `lefthook.yml` | YAML | Local lefthook config with remote imports and the `no-shell-functions` command |
| `lefthook-remote.yml` | YAML | Minimal config for consumers using lefthook remote integration |
| `config/lefthook/file_size_limits.yml` | YAML | Per-extension file size limits (default 4096, lock 65536, nix 10240) |
| `.envrc` | direnv | Loads the Nix flake dev shell |
| `.yamllint.yml` | YAML | yamllint configuration (disables line-length, relaxes truthy) |
| `.markdownlint.yml` | YAML | markdownlint configuration (disables MD013 line length) |
| `.editorconfig` | INI | Editor formatting (UTF-8, LF, 2-space indent, trim trailing whitespace) |

### Lefthook remotes

18 remote linter configurations are imported from `pr0d1r2/nix-lefthook-*` repos: nixfmt, shellcheck, shfmt, statix, deadnix, nix-no-embedded-shell, bats-parse, bats-unit, yamllint, nix-flake-check, typos, trailing-whitespace, missing-final-newline, git-conflict-markers, editorconfig-checker, git-no-local-paths, file-size-check, markdownlint.

## §T — Tasks

| status | id | goal |
| --- | --- | --- |
| `x` | T1 | Add `watch_file` entries to `.envrc` for `flake.nix`, `flake.lock`, and `dev.sh` per direnv skill |
| `x` | T2 | Add test for multiple files where some pass and some fail (mixed-result scenario) |
| `x` | T3 | Add test for indented function definitions (leading tabs/spaces) |
| `x` | T11 | Add bats tests confirming comment-prefixed lines are not false positives — `# myfunc() {`, `# function name {`, `# function name() {`, and indented variants all exit 0; regex already rejects `#` (not `[a-zA-Z_]` or `function`) so tests are GREEN against current code [§V.9, §B.1] |
| `x` | T12 | Correct §B.1 — remove false claim that `# myfunc() {` triggers a match; the `FUNC_RE` regex requires `[a-zA-Z_]` or `function` after optional whitespace so `#` never matches; narrow description to heredoc and quoted-string cases only [§B.1] |
| `d` | T4 | ~~Add test for function definitions inside comments (should not false-positive, currently does)~~ decomposed → T11, T12 |
| `x` | T5 | Align `actions/checkout` version in `update-pins.yml` (v4) with `ci.yml` (v6) |
| `x` | T6 | Extract `nix/dev/shell.sh` from `dev.sh` per flake skill for flake modularity |
| `x` | T7 | Add markdownlint lefthook remote or local command for `.md` files |
| `x` | T8 | Add test for function definition on the last line without trailing newline |
| `.` | T9 | Add test verifying stderr output format includes correct file path and line number |
| `.` | T10 | Consider filtering out function-like patterns inside heredocs and quoted strings |

## §B — Bugs / Known Issues

1. **False positives on heredocs and quoted strings**: The regex `FUNC_RE` matches function-definition-like lines inside heredoc bodies and multi-line quoted strings. Text inside `<<'EOF'...EOF` or a multi-line `"..."` that resembles a function definition will trigger a false positive. Comments are not affected — the regex requires `[a-zA-Z_]` or `function` after optional whitespace, so `#`-prefixed lines never match. This is a known trade-off for simplicity.

2. **`.envrc` missing `watch_file` directives**: The `.envrc` contains only `use flake` and does not watch `flake.nix`, `flake.lock`, or `nix/dev/shell.sh`. Changes to these files will not automatically trigger a direnv reload.

3. ~~**Checkout version inconsistency**: `ci.yml` uses `actions/checkout@v6` while `update-pins.yml` uses `actions/checkout@v4`.~~ Fixed: `update-pins.yml` now uses `actions/checkout@v6`.

4. **`ci` devShell is an undifferentiated alias**: `devShells.<system>.ci` is defined as `ci = default;` with no CI-specific changes, making it a no-op alias that could confuse consumers.

5. **Hook presence check is fragile**: `nix/dev/shell.sh` checks `[ -f .git/hooks/pre-commit ]` to decide whether to run `lefthook install`. If lefthook uses core.hooksPath or the hook file is a symlink, this check may not detect the correct state.

6. ~~**No markdownlint in lefthook**: `.markdownlint.yml` exists but no markdownlint linter is configured in `lefthook.yml`, violating the project's own linter skill rule that every file type must have an assigned linter.~~ Fixed: markdownlint remote added to `lefthook.yml` and wrapper added to `flake.nix`.

7. **`file-size-check` fails on `SPEC.md`**: `SPEC.md` (6429 bytes) exceeds the default 4096-byte limit in `config/lefthook/file_size_limits.yml` because no `md` extension override was defined. Fixed by adding `md: 8192` to the extensions map.

8. **Orphaned `update-pins.bats` after workflow removal**: The commit that dropped `update-pins.yml` (cron workflow) left its test file `tests/unit/.github/workflows/update-pins.bats` in place, causing 8 CI failures. Fixed by removing the orphaned test file.
