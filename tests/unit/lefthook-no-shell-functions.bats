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

@test "comment with posix-style function is not a false positive" {
    cat > "$TMP/comment.sh" <<'SH'
#!/usr/bin/env bash
# myfunc() {
echo "hello"
SH
    run lefthook-no-shell-functions "$TMP/comment.sh"
    assert_success
}

@test "comment with function keyword is not a false positive" {
    cat > "$TMP/comment.sh" <<'SH'
#!/usr/bin/env bash
# function name {
echo "hello"
SH
    run lefthook-no-shell-functions "$TMP/comment.sh"
    assert_success
}

@test "comment with function keyword and parens is not a false positive" {
    cat > "$TMP/comment.sh" <<'SH'
#!/usr/bin/env bash
# function name() {
echo "hello"
SH
    run lefthook-no-shell-functions "$TMP/comment.sh"
    assert_success
}

@test "space-indented comment with posix-style function is not a false positive" {
    cat > "$TMP/comment.sh" <<'SH'
#!/usr/bin/env bash
  # myfunc() {
echo "hello"
SH
    run lefthook-no-shell-functions "$TMP/comment.sh"
    assert_success
}

@test "tab-indented comment with posix-style function is not a false positive" {
    printf '#!/usr/bin/env bash\n\t# myfunc() {\necho "hello"\n' > "$TMP/comment.sh"
    run lefthook-no-shell-functions "$TMP/comment.sh"
    assert_success
}

@test "space-indented comment with function keyword is not a false positive" {
    cat > "$TMP/comment.sh" <<'SH'
#!/usr/bin/env bash
  # function name {
echo "hello"
SH
    run lefthook-no-shell-functions "$TMP/comment.sh"
    assert_success
}

@test "tab-indented comment with function keyword is not a false positive" {
    printf '#!/usr/bin/env bash\n\t# function name {\necho "hello"\n' > "$TMP/comment.sh"
    run lefthook-no-shell-functions "$TMP/comment.sh"
    assert_success
}

@test "space-indented comment with function keyword and parens is not a false positive" {
    cat > "$TMP/comment.sh" <<'SH'
#!/usr/bin/env bash
  # function name() {
echo "hello"
SH
    run lefthook-no-shell-functions "$TMP/comment.sh"
    assert_success
}

@test "tab-indented comment with function keyword and parens is not a false positive" {
    printf '#!/usr/bin/env bash\n\t# function name() {\necho "hello"\n' > "$TMP/comment.sh"
    run lefthook-no-shell-functions "$TMP/comment.sh"
    assert_success
}

@test "posix-style function on last line without trailing newline" {
    printf '#!/usr/bin/env bash\nmyfunc() {' > "$TMP/noeol.sh"
    run lefthook-no-shell-functions "$TMP/noeol.sh"
    assert_failure
    assert_output --partial "noeol.sh:2: shell function definition: myfunc()"
}

@test "function keyword on last line without trailing newline" {
    printf '#!/usr/bin/env bash\nfunction myfunc {' > "$TMP/noeol.sh"
    run lefthook-no-shell-functions "$TMP/noeol.sh"
    assert_failure
    assert_output --partial "noeol.sh:2: shell function definition: function myfunc"
}

@test "function keyword with parens on last line without trailing newline" {
    printf '#!/usr/bin/env bash\nfunction myfunc() {' > "$TMP/noeol.sh"
    run lefthook-no-shell-functions "$TMP/noeol.sh"
    assert_failure
    assert_output --partial "noeol.sh:2: shell function definition: function myfunc()"
}

@test "stderr format includes correct file path for posix-style function" {
    cat > "$TMP/pathcheck.sh" <<'SH'
#!/usr/bin/env bash
myfunc() {
    echo "hello"
}
SH
    run lefthook-no-shell-functions "$TMP/pathcheck.sh"
    assert_failure
    assert_line "$TMP/pathcheck.sh:2: shell function definition: myfunc()"
}

@test "stderr format includes correct file path for function keyword" {
    cat > "$TMP/pathcheck.sh" <<'SH'
#!/usr/bin/env bash
function myfunc {
    echo "hello"
}
SH
    run lefthook-no-shell-functions "$TMP/pathcheck.sh"
    assert_failure
    assert_line "$TMP/pathcheck.sh:2: shell function definition: function myfunc"
}

@test "stderr format includes correct file path for function keyword with parens" {
    cat > "$TMP/pathcheck.sh" <<'SH'
#!/usr/bin/env bash
function myfunc() {
    echo "hello"
}
SH
    run lefthook-no-shell-functions "$TMP/pathcheck.sh"
    assert_failure
    assert_line "$TMP/pathcheck.sh:2: shell function definition: function myfunc()"
}

@test "stderr format includes correct line number for function on line 5" {
    cat > "$TMP/linecheck.sh" <<'SH'
#!/usr/bin/env bash
echo "line 2"
echo "line 3"
echo "line 4"
myfunc() {
    echo "hello"
}
SH
    run lefthook-no-shell-functions "$TMP/linecheck.sh"
    assert_failure
    assert_line "$TMP/linecheck.sh:5: shell function definition: myfunc()"
}

@test "stderr format includes correct line numbers for multiple violations" {
    cat > "$TMP/multiline.sh" <<'SH'
#!/usr/bin/env bash
echo "line 2"
foo() { true; }
echo "line 4"
echo "line 5"
bar() { true; }
SH
    run lefthook-no-shell-functions "$TMP/multiline.sh"
    assert_failure
    assert_line --index 0 "$TMP/multiline.sh:3: shell function definition: foo()"
    assert_line --index 1 "$TMP/multiline.sh:6: shell function definition: bar()"
}

@test "posix-style function inside unquoted heredoc is not a false positive" {
    cat > "$TMP/heredoc.sh" <<'OUTER'
#!/usr/bin/env bash
cat <<EOF
myfunc() {
  echo "hello"
}
EOF
OUTER
    run lefthook-no-shell-functions "$TMP/heredoc.sh"
    assert_success
}

@test "function keyword inside unquoted heredoc is not a false positive" {
    cat > "$TMP/heredoc.sh" <<'OUTER'
#!/usr/bin/env bash
cat <<EOF
function myfunc {
  echo "hello"
}
EOF
OUTER
    run lefthook-no-shell-functions "$TMP/heredoc.sh"
    assert_success
}

@test "function keyword with parens inside unquoted heredoc is not a false positive" {
    cat > "$TMP/heredoc.sh" <<'OUTER'
#!/usr/bin/env bash
cat <<EOF
function myfunc() {
  echo "hello"
}
EOF
OUTER
    run lefthook-no-shell-functions "$TMP/heredoc.sh"
    assert_success
}

@test "function-like pattern inside single-quoted heredoc is not a false positive" {
    cat > "$TMP/heredoc.sh" <<'OUTER'
#!/usr/bin/env bash
cat <<'EOF'
myfunc() {
  echo "hello"
}
EOF
OUTER
    run lefthook-no-shell-functions "$TMP/heredoc.sh"
    assert_success
}

@test "function-like pattern inside double-quoted heredoc is not a false positive" {
    cat > "$TMP/heredoc.sh" <<'OUTER'
#!/usr/bin/env bash
cat <<"EOF"
myfunc() {
  echo "hello"
}
EOF
OUTER
    run lefthook-no-shell-functions "$TMP/heredoc.sh"
    assert_success
}

@test "function-like pattern inside tab-stripping heredoc is not a false positive" {
    printf '#!/usr/bin/env bash\ncat <<-EOF\n\tmyfunc() {\n\t\techo "hello"\n\t}\n\tEOF\n' > "$TMP/heredoc.sh"
    run lefthook-no-shell-functions "$TMP/heredoc.sh"
    assert_success
}

@test "real function after heredoc is still flagged" {
    cat > "$TMP/heredoc.sh" <<'OUTER'
#!/usr/bin/env bash
cat <<EOF
myfunc() {
  echo "hello"
}
EOF
real_func() {
  echo "bad"
}
OUTER
    run lefthook-no-shell-functions "$TMP/heredoc.sh"
    assert_failure
    assert_output --partial "real_func()"
    refute_output --partial "myfunc()"
}

@test "real function before heredoc is still flagged" {
    cat > "$TMP/heredoc.sh" <<'OUTER'
#!/usr/bin/env bash
real_func() {
  echo "bad"
}
cat <<EOF
myfunc() {
  echo "hello"
}
EOF
OUTER
    run lefthook-no-shell-functions "$TMP/heredoc.sh"
    assert_failure
    assert_output --partial "real_func()"
    refute_output --partial "myfunc()"
}

@test "function-like pattern inside multi-line double-quoted string is not a false positive" {
    cat > "$TMP/quote.sh" <<'OUTER'
#!/usr/bin/env bash
msg="
myfunc() {
  echo hello
}
"
OUTER
    run lefthook-no-shell-functions "$TMP/quote.sh"
    assert_success
}

@test "function-like pattern inside multi-line single-quoted string is not a false positive" {
    cat > "$TMP/quote.sh" <<'OUTER'
#!/usr/bin/env bash
msg='
myfunc() {
  echo hello
}
'
OUTER
    run lefthook-no-shell-functions "$TMP/quote.sh"
    assert_success
}

@test "real function after multi-line double-quoted string is still flagged" {
    cat > "$TMP/quote.sh" <<'OUTER'
#!/usr/bin/env bash
msg="
myfunc() {
  echo hello
}
"
real_func() {
  echo "bad"
}
OUTER
    run lefthook-no-shell-functions "$TMP/quote.sh"
    assert_failure
    assert_output --partial "real_func()"
    refute_output --partial "myfunc()"
}

@test "real function after multi-line single-quoted string is still flagged" {
    cat > "$TMP/quote.sh" <<'OUTER'
#!/usr/bin/env bash
msg='
myfunc() {
  echo hello
}
'
real_func() {
  echo "bad"
}
OUTER
    run lefthook-no-shell-functions "$TMP/quote.sh"
    assert_failure
    assert_output --partial "real_func()"
    refute_output --partial "myfunc()"
}
