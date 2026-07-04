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

@test "multiple files with some passing and some failing" {
    cat > "$TMP/clean.sh" <<'SH'
#!/usr/bin/env bash
echo "no functions here"
SH
    cat > "$TMP/dirty.sh" <<'SH'
#!/usr/bin/env bash
bad_func() {
    echo "has function"
}
SH
    run lefthook-no-shell-functions "$TMP/clean.sh" "$TMP/dirty.sh"
    assert_failure
    assert_output --partial "dirty.sh:2: shell function definition: bad_func()"
    refute_output --partial "clean.sh"
}

@test "space-indented posix-style function fails" {
    cat > "$TMP/indent.sh" <<'SH'
#!/usr/bin/env bash
  myfunc() {
    echo "hello"
  }
SH
    run lefthook-no-shell-functions "$TMP/indent.sh"
    assert_failure
    assert_output --partial "indent.sh:2: shell function definition:"
    assert_output --partial "myfunc()"
}

@test "tab-indented posix-style function fails" {
    printf '#!/usr/bin/env bash\n\tmyfunc() {\n\t\techo "hello"\n\t}\n' > "$TMP/indent.sh"
    run lefthook-no-shell-functions "$TMP/indent.sh"
    assert_failure
    assert_output --partial "indent.sh:2: shell function definition:"
    assert_output --partial "myfunc()"
}

@test "space-indented function keyword fails" {
    cat > "$TMP/indent.sh" <<'SH'
#!/usr/bin/env bash
    function myfunc {
        echo "hello"
    }
SH
    run lefthook-no-shell-functions "$TMP/indent.sh"
    assert_failure
    assert_output --partial "indent.sh:2: shell function definition:"
    assert_output --partial "function myfunc"
}

@test "tab-indented function keyword fails" {
    printf '#!/usr/bin/env bash\n\tfunction myfunc {\n\t\techo "hello"\n\t}\n' > "$TMP/indent.sh"
    run lefthook-no-shell-functions "$TMP/indent.sh"
    assert_failure
    assert_output --partial "indent.sh:2: shell function definition:"
    assert_output --partial "function myfunc"
}

@test "space-indented function keyword with parens fails" {
    cat > "$TMP/indent.sh" <<'SH'
#!/usr/bin/env bash
  function myfunc() {
      echo "hello"
  }
SH
    run lefthook-no-shell-functions "$TMP/indent.sh"
    assert_failure
    assert_output --partial "indent.sh:2: shell function definition:"
    assert_output --partial "function myfunc()"
}

@test "tab-indented function keyword with parens fails" {
    printf '#!/usr/bin/env bash\n\tfunction myfunc() {\n\t\techo "hello"\n\t}\n' > "$TMP/indent.sh"
    run lefthook-no-shell-functions "$TMP/indent.sh"
    assert_failure
    assert_output --partial "indent.sh:2: shell function definition:"
    assert_output --partial "function myfunc()"
}
