#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TEST_TMPDIR="$(mktemp -d)"
    cp .envrc "$TEST_TMPDIR/.envrc"
    export WATCH_LOG="$TEST_TMPDIR/watch_log"

    mkdir -p "$TEST_TMPDIR/bin"
    printf '#!/usr/bin/env bash\n:\n' > "$TEST_TMPDIR/bin/use"
    chmod +x "$TEST_TMPDIR/bin/use"
    # shellcheck disable=SC2016
    printf '#!/usr/bin/env bash\necho "$1" >> "$WATCH_LOG"\n' > "$TEST_TMPDIR/bin/watch_file"
    chmod +x "$TEST_TMPDIR/bin/watch_file"
}

teardown() {
    rm -rf "$TEST_TMPDIR"
}

@test "watches flake.nix for changes" {
    # shellcheck disable=SC2030
    export PATH="$TEST_TMPDIR/bin:$PATH"
    run bash "$TEST_TMPDIR/.envrc"
    assert_success
    run grep -x "flake.nix" "$WATCH_LOG"
    assert_success
}

@test "watches flake.lock for changes" {
    # shellcheck disable=SC2030,SC2031
    export PATH="$TEST_TMPDIR/bin:$PATH"
    run bash "$TEST_TMPDIR/.envrc"
    assert_success
    run grep -x "flake.lock" "$WATCH_LOG"
    assert_success
}

@test "watches nix/dev/shell.sh for changes" {
    # shellcheck disable=SC2031
    export PATH="$TEST_TMPDIR/bin:$PATH"
    run bash "$TEST_TMPDIR/.envrc"
    assert_success
    run grep -x "nix/dev/shell.sh" "$WATCH_LOG"
    assert_success
}

@test "watches scripts/materialize-lefthook.sh for changes" {
    # shellcheck disable=SC2031
    export PATH="$TEST_TMPDIR/bin:$PATH"
    run bash "$TEST_TMPDIR/.envrc"
    assert_success
    run grep -x "scripts/materialize-lefthook.sh" "$WATCH_LOG"
    assert_success
}
