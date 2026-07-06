# SPEC

## §D — Description

`nix-lefthook-no-shell-functions` is a Nix-flake-packaged lefthook linter that detects shell function definitions in `.sh` files, enforcing a modularity convention where scripts must delegate to separate scripts invoked in-place rather than contain functions. It scans for POSIX-style (`name()`), keyword-style (`function name`), and combined (`function name()`) declarations, skips `.bats` files (functions are framework primitives there), and exits 0 with no arguments or no matching files. It ships both as a standalone Nix package and as a lefthook remote config, targeting Nix dev environments on Linux and macOS (arm64/x86_64).

## §V — Invariants

1. The detector must exit 0 when invoked with no arguments.
2. Non-existent file arguments must be silently skipped (exit 0 if no other failures).
3. Files ending in `.bats` must always be skipped regardless of content.
4. Any `.sh` file with a POSIX-style (`name()`), keyword-style (`function name`), or combined (`function name()`) definition must cause a non-zero exit.
5. Violations must be reported to stderr as `file:line: shell function definition: <match>`.
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

- **Arguments**: Zero or more file paths, typically from lefthook via `{staged_files}`/`{push_files}`.
- **Exit 0**: No arguments, all files skipped (`.bats`/non-existent), or no definitions found.
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
| `BATS_LIB_PATH` | Set by `nix/dev/shell.sh` | bats helper libs (bats-support, bats-assert, bats-file) |

### Configuration files

| File | Format | Purpose |
| --- | --- | --- |
| `lefthook.yml` | YAML | Local lefthook config with remote imports and the `no-shell-functions` command |
| `lefthook-remote.yml` | YAML | Minimal config for consumers using lefthook remote integration |
| `config/lefthook/file_size_limits.yml` | YAML | Per-extension file size limits (default 4096) |
| `.envrc` | direnv | Loads the Nix flake dev shell |
| `.yamllint.yml` | YAML | yamllint config (disables line-length, relaxes truthy) |
| `.markdownlint.yml` | YAML | markdownlint config (disables MD013 line length) |
| `.editorconfig` | INI | Editor formatting (UTF-8, LF, 2-space indent, trim trailing) |

### Lefthook remotes

18 remote linters are imported from `pr0d1r2/nix-lefthook-*`: nixfmt, shellcheck, shfmt, statix, deadnix, nix-no-embedded-shell, bats-parse, bats-unit, yamllint, nix-flake-check, typos, trailing-whitespace, missing-final-newline, git-conflict-markers, editorconfig-checker, git-no-local-paths, file-size-check, markdownlint.

## §T — Tasks

| status | id | goal |
| --- | --- | --- |
| `x` | T1 | Add `watch_file` entries to `.envrc` for `flake.nix`, `flake.lock`, `dev.sh` per direnv skill |
| `x` | T2 | Add test for mixed-result scenario (some files pass, some fail) |
| `x` | T3 | Add test for indented function definitions (leading tabs/spaces) |
| `x` | T11 | Add bats tests confirming comment-prefixed lines (`# myfunc() {`, `# function name {`, indented variants) are not false positives — GREEN against current code [§V.9, §B.1] |
| `x` | T12 | Correct §B.1 — `#` never matches `FUNC_RE` (requires `[a-zA-Z_]`/`function`); narrow description to heredoc and quoted-string cases only [§B.1] |
| `d` | T4 | ~~Add test for function definitions inside comments (should not false-positive, currently does)~~ decomposed → T11, T12 |
| `x` | T5 | Align `actions/checkout` version in `update-pins.yml` (v4) with `ci.yml` (v6) |
| `x` | T6 | Extract `nix/dev/shell.sh` from `dev.sh` per flake skill for flake modularity |
| `x` | T7 | Add markdownlint lefthook remote or local command for `.md` files |
| `x` | T8 | Add test for function definition on the last line without trailing newline |
| `x` | T9 | Add test verifying stderr format includes correct file path and line number |
| `x` | T10 | Filter out function-like patterns inside heredocs and quoted strings |
| | T13 | Mark §B.2 fixed — `.envrc` already watches `flake.nix`, `flake.lock`, `nix/dev/shell.sh` [§B.2] |
| | T14 | Add bats test for symlink pre-commit hook detection in `nix/dev/shell.sh` — symlink `.git/hooks/pre-commit`, verify `lefthook install` is skipped (confirms `-f` follows symlinks) [§V.9, §B.5] |
| | T15 | Fix fragile hook check: RED bats test for `core.hooksPath`, then query `git config core.hooksPath` with `.git/hooks` fallback [§B.5, §V.9] |
| | T16 | Resolve undifferentiated `ci` devShell: drop the `ci = default` alias or differentiate it; update §B.4 [§B.4, §V.8] |

## §B — Bugs / Known Issues

1. ~~**False positives on heredocs and quoted strings**: `FUNC_RE` matched function-like lines inside heredoc bodies and multi-line quoted strings.~~ Fixed: a character-by-character state machine tracks heredoc bodies (including `<<-` tab-stripping and quoted/escaped delimiters) and multi-line quoted strings, skipping `FUNC_RE` inside them.

2. **`.envrc` missing `watch_file` directives**: The `.envrc` contains only `use flake` and does not watch `flake.nix`, `flake.lock`, or `nix/dev/shell.sh`. Changes to these files will not automatically trigger a direnv reload.

3. ~~**Checkout version inconsistency**: `ci.yml` used `@v6` while `update-pins.yml` used `@v4`.~~ Fixed: `update-pins.yml` now uses `@v6`.

4. **`ci` devShell is an undifferentiated alias**: `devShells.<system>.ci` is defined as `ci = default;` with no CI-specific changes, making it a no-op alias that could confuse consumers.

5. **Hook presence check is fragile**: `nix/dev/shell.sh` checks `[ -f .git/hooks/pre-commit ]` to decide whether to run `lefthook install`. If lefthook uses core.hooksPath or the hook file is a symlink, this check may not detect the correct state.

6. ~~**No markdownlint in lefthook**: `.markdownlint.yml` existed but no markdownlint linter was configured, violating the linter skill rule.~~ Fixed: markdownlint remote added to `lefthook.yml` and wrapper to `flake.nix`.

7. ~~**`file-size-check` fails on `SPEC.md`**: `SPEC.md` (6429 bytes) exceeded the default 4096-byte limit (no `md` override defined).~~ Fixed by adding `md: 8192` to `config/lefthook/file_size_limits.yml`. See §B.9 for recurrence.

8. **Orphaned `update-pins.bats` after workflow removal**: The commit that dropped `update-pins.yml` (cron workflow) left its test file `tests/unit/.github/workflows/update-pins.bats` in place, causing 8 CI failures. Fixed by removing the orphaned test file.

9. ~~**`file-size-check` fails on `SPEC.md` again**: `SPEC.md` grew to 8819 bytes, exceeding the `md: 8192` limit set in §B.7. Recurrence of §B.7 as the spec accreted more §T/§B history.~~ Fixed by condensing verbose §D/§T/§B prose back under the 8192-byte limit rather than raising the threshold, keeping the size check meaningful.
