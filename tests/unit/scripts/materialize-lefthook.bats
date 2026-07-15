#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$TMP"
    git init "$TMP" >/dev/null 2>&1

    SCRIPT="$BATS_TEST_DIRNAME/../../../scripts/materialize-lefthook.sh"
}

@test "generates valid YAML starting with document separator" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run head -1 lefthook.yml
    assert_output "---"
}

@test "generates pre-commit and pre-push sections" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "^pre-commit:" lefthook.yml
    assert_success
    run grep "^pre-push:" lefthook.yml
    assert_success
}

@test "wires shellcheck when sh files exist" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "shellcheck:" lefthook.yml
    assert_success
    run grep -A2 "shellcheck:" lefthook.yml
    assert_output --partial 'glob: "*.sh"'
}

@test "wires shfmt when sh files exist" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "shfmt:" lefthook.yml
    assert_success
}

@test "wires no-shell-functions when sh files exist" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "no-shell-functions:" lefthook.yml
    assert_success
}

@test "wires nixfmt when nix files exist" {
    cd "$TMP"
    touch file.nix
    git add file.nix
    run bash "$SCRIPT"
    assert_success
    run grep "nixfmt:" lefthook.yml
    assert_success
}

@test "wires statix when nix files exist" {
    cd "$TMP"
    touch file.nix
    git add file.nix
    run bash "$SCRIPT"
    assert_success
    run grep "statix:" lefthook.yml
    assert_success
}

@test "wires deadnix when nix files exist" {
    cd "$TMP"
    touch file.nix
    git add file.nix
    run bash "$SCRIPT"
    assert_success
    run grep "deadnix:" lefthook.yml
    assert_success
}

@test "wires nix-no-embedded-shell when nix files exist" {
    cd "$TMP"
    touch file.nix
    git add file.nix
    run bash "$SCRIPT"
    assert_success
    run grep "nix-no-embedded-shell:" lefthook.yml
    assert_success
}

@test "wires git-no-local-paths when nix files exist" {
    cd "$TMP"
    touch file.nix
    git add file.nix
    run bash "$SCRIPT"
    assert_success
    run grep "git-no-local-paths:" lefthook.yml
    assert_success
}

@test "wires markdownlint when md files exist" {
    cd "$TMP"
    touch file.md
    git add file.md
    run bash "$SCRIPT"
    assert_success
    run grep "markdownlint:" lefthook.yml
    assert_success
}

@test "wires markdownlint-agentic when md files exist" {
    cd "$TMP"
    touch file.md
    git add file.md
    run bash "$SCRIPT"
    assert_success
    run grep "markdownlint-agentic:" lefthook.yml
    assert_success
}

@test "wires yamllint when yml files exist" {
    cd "$TMP"
    touch file.yml
    git add file.yml
    run bash "$SCRIPT"
    assert_success
    run grep "yamllint:" lefthook.yml
    assert_success
}

@test "wires bats-unit when bats files exist" {
    cd "$TMP"
    touch file.bats
    git add file.bats
    run bash "$SCRIPT"
    assert_success
    run grep "bats-unit:" lefthook.yml
    assert_success
}

@test "omits shellcheck when no sh files exist" {
    cd "$TMP"
    touch file.nix
    git add file.nix
    run bash "$SCRIPT"
    assert_success
    run grep "shellcheck:" lefthook.yml
    assert_failure
}

@test "omits nixfmt when no nix files exist" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "nixfmt:" lefthook.yml
    assert_failure
}

@test "omits markdownlint when no md files exist" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "markdownlint:" lefthook.yml
    assert_failure
}

@test "omits yamllint when no yml files exist" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "yamllint:" lefthook.yml
    assert_failure
}

@test "omits bats-unit when no bats files exist" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "bats-unit:" lefthook.yml
    assert_failure
}

@test "always wires editorconfig-checker" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "editorconfig-checker:" lefthook.yml
    assert_success
}

@test "always wires trailing-whitespace" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "trailing-whitespace:" lefthook.yml
    assert_success
}

@test "always wires missing-final-newline" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "missing-final-newline:" lefthook.yml
    assert_success
}

@test "always wires typos" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "typos:" lefthook.yml
    assert_success
}

@test "always wires file-size-check" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "file-size-check:" lefthook.yml
    assert_success
}

@test "always wires git-conflict-markers" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep "git-conflict-markers:" lefthook.yml
    assert_success
}

@test "pre-commit uses staged_files" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep -A10 "^pre-commit:" lefthook.yml
    assert_output --partial "{staged_files}"
}

@test "pre-push uses push_files" {
    cd "$TMP"
    touch file.sh
    git add file.sh
    run bash "$SCRIPT"
    assert_success
    run grep -A10 "^pre-push:" lefthook.yml
    assert_output --partial "{push_files}"
}

@test "every command has a timeout wrapper" {
    cd "$TMP"
    touch file.sh file.nix file.md file.yml file.bats
    git add file.sh file.nix file.md file.yml file.bats
    run bash "$SCRIPT"
    assert_success
    run grep "run:" lefthook.yml
    assert_success
    while IFS= read -r line; do
        [[ "$line" == *"timeout"* ]] || {
            echo "missing timeout in: $line"
            return 1
        }
    done < <(grep "run:" lefthook.yml)
}

@test "markdownlint excludes .claude/skills" {
    cd "$TMP"
    touch file.md
    git add file.md
    run bash "$SCRIPT"
    assert_success
    run grep -A3 "markdownlint:" lefthook.yml
    assert_output --partial '.claude/skills/'
}

@test "markdownlint-agentic excludes standard docs" {
    cd "$TMP"
    touch file.md
    git add file.md
    run bash "$SCRIPT"
    assert_success
    run grep -A3 "markdownlint-agentic:" lefthook.yml
    assert_output --partial 'README'
    assert_output --partial 'SPEC'
}

@test "is idempotent — running twice produces same output" {
    cd "$TMP"
    touch file.sh file.md
    git add file.sh file.md
    run bash "$SCRIPT"
    assert_success
    cp lefthook.yml first.yml
    run bash "$SCRIPT"
    assert_success
    run diff first.yml lefthook.yml
    assert_success
}
