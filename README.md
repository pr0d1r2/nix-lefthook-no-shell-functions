# nix-lefthook-no-shell-functions

<!-- hallucinogen:autonomy-disclaimer start -->
> Read [LLM-DISCLAIMER](docs/LLM-DISCLAIMER.md) first. This repository is
> tended by an autonomous loop, and that file says what the loop may do here,
> what it may not, and what to check before trusting anything in this tree.
<!-- hallucinogen:autonomy-disclaimer end -->

[![CI](https://github.com/pr0d1r2/nix-lefthook-no-shell-functions/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-no-shell-functions/actions/workflows/ci.yml) [![NixOS 26.05](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=nixos)](https://nixos.org)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible [shell function detector](https://www.shellcheck.net/) wrapper, packaged as a Nix flake.

Detects shell function definitions in staged `.sh` files to enforce script modularity. Skips `.bats` files. Exits 0 when no matching files are found.

## Architecture

```mermaid
flowchart LR
  consumer["consumer lefthook.yml"] -->|"remotes"| remote["lefthook-remote.yml"]
  remote -->|"pre-commit: *.sh → {staged_files}"| lefthook_no_shell_functions["lefthook-no-shell-functions"]
  remote -->|"pre-push: *.sh → {push_files}"| lefthook_no_shell_functions["lefthook-no-shell-functions"]
  lefthook_no_shell_functions -->|"runs"| tool["shell function detector"]
  lefthook_no_shell_functions -->|"exit status"| consumer
```

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` — no flake input needed, just the wrapper binary in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-no-shell-functions
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-no-shell-functions = {
  url = "github:pr0d1r2/nix-lefthook-no-shell-functions";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-no-shell-functions.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add to `lefthook.yml`:

```yaml
pre-commit:
  commands:
    no-shell-functions:
      glob: "*.sh"
      run: timeout ${LEFTHOOK_NO_SHELL_FUNCTIONS_TIMEOUT:-30} lefthook-no-shell-functions {staged_files}
```

### Configuring timeout

The default timeout is 30 seconds. Override per-repo via environment variable:

```bash
export LEFTHOOK_NO_SHELL_FUNCTIONS_TIMEOUT=60
```

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) — entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-no-shell-functions  # direnv loads the flake
lefthook-bats-unit tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
lefthook-bats-unit tests/unit/
```

### Development architecture

```mermaid
flowchart LR
  envrc[".envrc"] -->|"use flake"| flake["flake.nix"]
  flake -->|"mkConsumerFlake"| sas["set-and-setting"]
  flake -->|"devShell"| shell["dev shell"]
  sas -->|"assembled hooks"| lh["lefthook.yml"]
  lh -->|"pre-commit / pre-push"| checks["linters, bats, nix flake check"]
  ci[".github/workflows/ci.yml"] -->|"guardrails.yml"| checks
```

## License

MIT
