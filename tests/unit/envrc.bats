#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMPDIR="$(mktemp -d)"
    cp .envrc "$TMPDIR/.envrc"
    export WATCH_LOG="$TMPDIR/watch_log"

    mkdir -p "$TMPDIR/bin"
    printf '#!/usr/bin/env bash\n:\n' > "$TMPDIR/bin/use"
    chmod +x "$TMPDIR/bin/use"
    # shellcheck disable=SC2016
    printf '#!/usr/bin/env bash\necho "$1" >> "$WATCH_LOG"\n' > "$TMPDIR/bin/watch_file"
    chmod +x "$TMPDIR/bin/watch_file"
}

teardown() {
    rm -rf "$TMPDIR"
}

@test "watches flake.nix for changes" {
    # shellcheck disable=SC2030
    export PATH="$TMPDIR/bin:$PATH"
    run bash "$TMPDIR/.envrc"
    assert_success
    run grep -x "flake.nix" "$WATCH_LOG"
    assert_success
}

@test "watches flake.lock for changes" {
    # shellcheck disable=SC2030,SC2031
    export PATH="$TMPDIR/bin:$PATH"
    run bash "$TMPDIR/.envrc"
    assert_success
    run grep -x "flake.lock" "$WATCH_LOG"
    assert_success
}

@test "watches nix/dev/shell.sh for changes" {
    # shellcheck disable=SC2031
    export PATH="$TMPDIR/bin:$PATH"
    run bash "$TMPDIR/.envrc"
    assert_success
    run grep -x "nix/dev/shell.sh" "$WATCH_LOG"
    assert_success
}
