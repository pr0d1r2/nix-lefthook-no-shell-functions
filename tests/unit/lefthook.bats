#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
}

@test "lefthook.yml runs markdownlint for staged Markdown files" {
    run grep -A4 "markdownlint:" lefthook.yml
    assert_success
    assert_output --partial 'glob: "*.md"'
    assert_output --partial "lefthook-markdownlint {staged_files}"
}

@test "lefthook.yml runs markdownlint for pushed Markdown files" {
    run grep -A20 "pre-push:" lefthook.yml
    assert_success
    assert_output --partial 'glob: "*.md"'
    assert_output --partial "lefthook-markdownlint {push_files}"
}

@test "lefthook.yml applies configurable timeouts to markdownlint" {
    run grep "lefthook-markdownlint " lefthook.yml
    assert_success
    assert_line --index 0 --partial 'timeout ${LEFTHOOK_MARKDOWNLINT_TIMEOUT:-30}'
    assert_line --index 1 --partial 'timeout ${LEFTHOOK_MARKDOWNLINT_TIMEOUT:-30}'
}
