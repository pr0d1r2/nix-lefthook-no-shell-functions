#!/usr/bin/env bats

setup() {
    BATS_LIB_PATH="${BATS_LIB_PATH:-$(dirname "$(dirname "$(command -v bats)")")/share/bats}"
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TEST_DIR="$(mktemp -d)"
    cp .envrc "$TEST_DIR/.envrc"
    export WATCH_LOG="$TEST_DIR/watch_log"

    mkdir -p "$TEST_DIR/bin"
    printf '#!/usr/bin/env bash\n:\n' > "$TEST_DIR/bin/use"
    chmod +x "$TEST_DIR/bin/use"
    # shellcheck disable=SC2016
    printf '#!/usr/bin/env bash\necho "$1" >> "$WATCH_LOG"\n' > "$TEST_DIR/bin/watch_file"
    chmod +x "$TEST_DIR/bin/watch_file"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "watches flake.nix for changes" {
    # shellcheck disable=SC2030
    export PATH="$TEST_DIR/bin:$PATH"
    run bash "$TEST_DIR/.envrc"
    assert_success
    run grep -x "flake.nix" "$WATCH_LOG"
    assert_success
}

@test "watches flake.lock for changes" {
    # shellcheck disable=SC2030,SC2031
    export PATH="$TEST_DIR/bin:$PATH"
    run bash "$TEST_DIR/.envrc"
    assert_success
    run grep -x "flake.lock" "$WATCH_LOG"
    assert_success
}

@test "watches nix/dev/shell.sh for changes" {
    # shellcheck disable=SC2031
    export PATH="$TEST_DIR/bin:$PATH"
    run bash "$TEST_DIR/.envrc"
    assert_success
    run grep -x "nix/dev/shell.sh" "$WATCH_LOG"
    assert_success
}

@test "watches scripts/materialize-lefthook.sh for changes" {
    # shellcheck disable=SC2031
    export PATH="$TEST_DIR/bin:$PATH"
    run bash "$TEST_DIR/.envrc"
    assert_success
    run grep -x "scripts/materialize-lefthook.sh" "$WATCH_LOG"
    assert_success
}
