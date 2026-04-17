#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR"
}

@test "no args exits 0" {
    run lefthook-no-shell-functions
    assert_success
}

@test "non-existent file is skipped" {
    run lefthook-no-shell-functions /nonexistent/file.sh
    assert_success
}

@test "script without functions passes" {
    cat > "$TMP/good.sh" <<'SH'
#!/usr/bin/env bash
echo "hello"
SH
    run lefthook-no-shell-functions "$TMP/good.sh"
    assert_success
}

@test "posix-style function declaration fails" {
    cat > "$TMP/bad.sh" <<'SH'
#!/usr/bin/env bash
myfunc() {
    echo "hello"
}
SH
    run lefthook-no-shell-functions "$TMP/bad.sh"
    assert_failure
}

@test "function keyword declaration fails" {
    cat > "$TMP/bad.sh" <<'SH'
#!/usr/bin/env bash
function myfunc {
    echo "hello"
}
SH
    run lefthook-no-shell-functions "$TMP/bad.sh"
    assert_failure
}

@test "function keyword with parens fails" {
    cat > "$TMP/bad.sh" <<'SH'
#!/usr/bin/env bash
function myfunc() {
    echo "hello"
}
SH
    run lefthook-no-shell-functions "$TMP/bad.sh"
    assert_failure
}

@test ".bats files are skipped" {
    cat > "$TMP/test.bats" <<'SH'
setup() {
    true
}
SH
    run lefthook-no-shell-functions "$TMP/test.bats"
    assert_success
}

@test "reports all function definitions in one file" {
    cat > "$TMP/multi.sh" <<'SH'
#!/usr/bin/env bash
foo() { true; }
bar() { true; }
SH
    run lefthook-no-shell-functions "$TMP/multi.sh"
    assert_failure
    assert_output --partial "foo()"
    assert_output --partial "bar()"
}
