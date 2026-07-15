# SPEC

## §D — Description

`nix-lefthook-no-shell-functions` is a Nix-flake-packaged lefthook linter that
detects shell function definitions in `.sh` files, enforcing a modularity
convention where scripts must delegate to separate scripts invoked in-place
rather than contain functions. It scans for POSIX-style (`name()`),
keyword-style (`function name`), and combined (`function name()`) declarations,
skips `.bats` files (functions are framework primitives there), and exits 0 with
no arguments or no matching files. It ships both as a standalone Nix package and
as a lefthook remote config, targeting Nix dev environments on Linux and macOS
(arm64/x86_64).

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
| `devShells.<system>.ci` | CI shell with the default toolset and no interactive shell hook |

### Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `LEFTHOOK_NO_SHELL_FUNCTIONS_TIMEOUT` | `30` | Timeout in seconds for the lefthook command |
| `BATS_LIB_PATH` | Set by `nix/dev/shell.sh` | bats helper libs (bats-support, bats-assert, bats-file) |

### Configuration files

| File | Format | Purpose |
| --- | --- | --- |
| `lefthook.yml` | YAML | Local lefthook config and `no-shell-functions` command |
| `lefthook-remote.yml` | YAML | Minimal config for lefthook remote consumers |
| `config/lefthook/file_size_limits.yml` | YAML | Per-extension file size limits |
| `.envrc` | direnv | Loads the Nix flake dev shell |
| `.yamllint.yml` | YAML | yamllint config (line-length off, truthy relaxed) |
| `.markdownlint.yml` | YAML | markdownlint config (`MD013` at 300 chars) |
| `.editorconfig` | INI | Editor formatting (UTF-8, LF, 2-space, trim) |

### Lefthook linters

The dev shell packages wrapper binaries from `pr0d1r2/nix-lefthook-*` for bats,
Nix, shell, Markdown, YAML, spelling, whitespace, Git, EditorConfig, and file-size
checks. See §B.12 for the wrappers not currently wired into `lefthook.yml`.

## §T — Tasks

| status | id | goal |
| --- | --- | --- |
| `x` | T1 | Add `watch_file` entries to `.envrc` for `flake.nix`, `flake.lock`, `dev.sh` per direnv skill |
| `x` | T2 | Add test for mixed-result scenario (some files pass, some fail) |
| `x` | T3 | Add test for indented function definitions (leading tabs/spaces) |
| `x` | T11 | Add bats tests confirming comment-prefixed lines are not false positives [§V.9, §B.1] |
| `x` | T12 | Correct §B.1 — narrow description to heredoc and quoted-string cases only [§B.1] |
| `d` | T4 | ~~Add test for function definitions inside comments (should not false-positive, currently does)~~ decomposed → T11, T12 |
| `x` | T5 | Align `actions/checkout` version in `update-pins.yml` (v4) with `ci.yml` (v6) |
| `x` | T6 | Extract `nix/dev/shell.sh` from `dev.sh` per flake skill for flake modularity |
| `x` | T7 | Add markdownlint lefthook remote or local command for `.md` files |
| `x` | T8 | Add test for function definition on the last line without trailing newline |
| `x` | T9 | Add test verifying stderr format includes correct file path and line number |
| `x` | T10 | Filter out function-like patterns inside heredocs and quoted strings |
| `x` | T13 | Mark §B.2 fixed — `.envrc` watches all three dev-shell inputs |
| `x` | T14 | Test symlink pre-commit hook detection in `nix/dev/shell.sh` [§V.9] |
| `x` | T15 | Respect `core.hooksPath` with a `.git/hooks` fallback [§V.9] |
| `x` | T16 | Differentiate the `ci` devShell by removing interactive hook setup [§V.8] |
| | T17 | HUMAN-GATED — do NOT hand-wire the vendored `lefthook.yml`; superseded by vendored→referenced migration (set-and-setting materialization, issue #30). The content-aware standard lefthook wires every applicable linter, resolving §B.12 wholesale [§V.13, §B.12] |

## §B — Bugs / Known Issues

1. ~~**False positives on heredocs and quoted strings**: `FUNC_RE` matched
   function-like lines inside heredoc bodies and multi-line quoted strings.~~
   Fixed: a character-by-character state machine tracks heredoc bodies
   (including `<<-` tab-stripping and quoted/escaped delimiters) and multi-line
   quoted strings, skipping `FUNC_RE` inside them.

2. ~~**`.envrc` missing `watch_file` directives**.~~ Fixed: it watches
   `flake.nix`, `flake.lock`, and `nix/dev/shell.sh`.

3. ~~**Checkout version inconsistency**: `ci.yml` used `@v6` while `update-pins.yml` used `@v4`.~~ Fixed: `update-pins.yml` now uses `@v6`.

4. ~~**`ci` devShell was an undifferentiated alias**.~~ Fixed: it retains the
   default toolset without the interactive shell hook.

5. ~~**Hook presence check was fragile**.~~ Fixed: it respects
   `core.hooksPath`, falls back to `.git/hooks`, and follows hook symlinks.

6. ~~**No markdownlint in lefthook**: `.markdownlint.yml` existed but no linter ran, violating the linter skill.~~ Fixed: markdownlint added to `lefthook.yml` with a wrapper in `flake.nix`.

7. ~~**`file-size-check` fails on `SPEC.md`**: `SPEC.md` (6429 bytes) exceeded the default 4096-byte limit.~~ Fixed by adding `md: 8192` to `config/lefthook/file_size_limits.yml`. See §B.9 for recurrence.

8. **Orphaned `update-pins.bats` after workflow removal**: dropping `update-pins.yml` (cron workflow) left `tests/unit/.github/workflows/update-pins.bats` behind, causing 8 CI failures. Fixed by removing the orphaned test file.

9. ~~**`file-size-check` fails on `SPEC.md` again**: `SPEC.md` grew to 8819
   bytes, exceeding the `md: 8192` limit set in §B.7.~~ Fixed by condensing
   verbose §D/§T/§B prose back under the limit rather than raising the threshold.

10. ~~**`markdownlint` fails on over-long `SPEC.md` lines**: §D/§I/§B prose ran
    up to 633 chars, over the `MD013` 300-char limit enforced by the regular
    `markdownlint` check.~~ Fixed by reflowing the paragraphs and list items
    under 300 chars.

11. ~~**`lefthook-markdownlint-agentic` missing from the flake**: `lefthook.yml`
    ran it, but `flake.nix` shipped no such wrapper (no input, no
    `lefthookWrappersFor` entry), so CI failed with `exit 127` (`No such file
    or directory`).~~ Fixed by adding the `nix-lefthook-markdownlint-agentic`
    flake input and a wrapper that substitutes the bundled
    `.markdownlint-agentic.yml` config path.

12. **Packaged linters are not wired into lefthook**: `lefthook.yml` currently
    runs only Markdown and YAML checks. Other tracked file types therefore lack
    pre-commit and pre-push checks, violating §V.13, even though most wrapper
    binaries are already present in the dev shell. **Resolution: migrate
    vendored→referenced (set-and-setting materialization, issue #30) — the
    content-aware standard lefthook wires every applicable linter. Do NOT
    hand-wire the vendored `lefthook.yml` (throwaway); T17 is HUMAN-GATED.**
