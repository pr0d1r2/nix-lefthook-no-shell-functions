#!/usr/bin/env bats

setup() {
    export BATS_LIB_PATH="${BATS_LIB_PATH:-$(dirname "$(dirname "$(readlink -f "$(command -v bats)")")")/share/bats}"
    bats_load_library bats-support
    bats_load_library bats-assert

    run bash scripts/materialize-lefthook.sh
    assert_success
}

@test "materialized lefthook.yml runs markdownlint for staged Markdown files" {
    run grep -A4 "markdownlint:" lefthook.yml
    assert_success
    assert_output --partial 'glob: "*.md"'
    assert_output --partial "lefthook-markdownlint {staged_files}"
}

@test "materialized lefthook.yml runs markdownlint for pushed Markdown files" {
    run grep -A20 "pre-push:" lefthook.yml
    assert_success
    assert_output --partial 'glob: "*.md"'
    assert_output --partial "lefthook-markdownlint {push_files}"
}

@test "materialized lefthook.yml applies configurable timeouts to markdownlint" {
    run grep "lefthook-markdownlint " lefthook.yml
    assert_success
    assert_line --index 0 --partial 'timeout ${LEFTHOOK_MARKDOWNLINT_TIMEOUT:-30}'
    assert_line --index 1 --partial 'timeout ${LEFTHOOK_MARKDOWNLINT_TIMEOUT:-30}'
}

@test "lefthook.yml is gitignored" {
    run grep -x "lefthook.yml" .gitignore
    assert_success
}
