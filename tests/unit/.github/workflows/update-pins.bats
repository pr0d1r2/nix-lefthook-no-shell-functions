#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    WORKFLOW=".github/workflows/update-pins.yml"
}

@test "update-pins.yml exists" {
    assert [ -f "$WORKFLOW" ]
}

@test "uses actions/checkout@v6" {
    run grep "uses: actions/checkout@v6" "$WORKFLOW"
    assert_success
}

@test "checkout version matches ci.yml" {
    ci_version=$(grep -oP 'actions/checkout@\S+' .github/workflows/ci.yml | head -1)
    pins_version=$(grep -oP 'actions/checkout@\S+' "$WORKFLOW" | head -1)
    assert_equal "$ci_version" "$pins_version"
}

@test "runs on schedule" {
    run grep "schedule:" "$WORKFLOW"
    assert_success
}

@test "supports workflow_dispatch" {
    run grep "workflow_dispatch" "$WORKFLOW"
    assert_success
}

@test "uses cachix/install-nix-action" {
    run grep "cachix/install-nix-action" "$WORKFLOW"
    assert_success
}

@test "runs nix flake update" {
    run grep "nix flake update" "$WORKFLOW"
    assert_success
}

@test "creates pull request" {
    run grep "peter-evans/create-pull-request" "$WORKFLOW"
    assert_success
}
