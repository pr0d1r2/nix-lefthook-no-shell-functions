#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
}

@test "lefthook.yml contains markdownlint remote" {
    run grep -A2 "nix-lefthook-markdownlint" lefthook.yml
    assert_success
    assert_output --partial "git_url: https://github.com/pr0d1r2/nix-lefthook-markdownlint"
}

@test "lefthook.yml markdownlint remote uses main branch" {
    run grep -A3 "nix-lefthook-markdownlint" lefthook.yml
    assert_success
    assert_output --partial "ref: main"
}

@test "lefthook.yml markdownlint remote loads lefthook-remote.yml" {
    run grep -A5 "nix-lefthook-markdownlint" lefthook.yml
    assert_success
    assert_output --partial "lefthook-remote.yml"
}
