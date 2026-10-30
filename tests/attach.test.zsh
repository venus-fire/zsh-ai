#!/usr/bin/env zsh

# Load test helper
source "${0:A:h}/test_helper.zsh"

# Load the attachment module
source "$PLUGIN_DIR/lib/attach.zsh"

# Attachment resolution tests
test_resolves_existing_file() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    printf 'hello attachment\n' > notes.txt
    local output=$(_zsh_ai_attach_paths "read @notes.txt please")
    assert_equals "$output" "${TEST_DIR:A}/notes.txt"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_ignores_missing_file() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    local output=$(_zsh_ai_attach_paths "read @ghost.txt please")
    assert_equals "$output" ""

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_strips_trailing_punctuation() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    printf 'x\n' > notes.txt
    local output=$(_zsh_ai_attach_paths "what is in @notes.txt?")
    assert_equals "$output" "${TEST_DIR:A}/notes.txt"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_keeps_dots_in_filenames() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    printf 'x\n' > app.config.js
    local output=$(_zsh_ai_attach_paths "explain @app.config.js")
    assert_equals "$output" "${TEST_DIR:A}/app.config.js"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_double_at_is_escaped() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    printf 'x\n' > notes.txt
    local output=$(_zsh_ai_attach_paths "literal @@notes.txt")
    assert_equals "$output" ""

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_caps_number_of_files() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    printf 'x\n' > a.txt
    printf 'x\n' > b.txt
    printf 'x\n' > c.txt
    local output=$(ZSH_AI_ATTACH_MAX_FILES=2 _zsh_ai_attach_paths "@a.txt @b.txt @c.txt")
    local count=$(print -r -- "$output" | grep -c .)
    assert_equals "$count" "2"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_deduplicates_repeated_reference() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    printf 'x\n' > a.txt
    local output=$(_zsh_ai_attach_paths "@a.txt and again @a.txt")
    local count=$(print -r -- "$output" | grep -c .)
    assert_equals "$count" "1"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

# Attachment block tests
test_inlines_file_contents() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    printf 'line one\nline two\n' > notes.txt
    local output=$(_zsh_ai_attach_block "read @notes.txt")
    assert_contains "$output" "Attached files"
    assert_contains "$output" "### ${TEST_DIR:A}/notes.txt"
    assert_contains "$output" "line one"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_truncates_large_file() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    print -r -- "0123456789abcdef" > big.txt
    local output=$(ZSH_AI_ATTACH_MAX_BYTES=4 _zsh_ai_attach_block "read @big.txt")
    assert_contains "$output" "truncated at 4 bytes"
    assert_contains "$output" "file is 17 bytes"
    assert_contains "$output" "0123"
    assert_not_contains "$output" "abcdef"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_skips_binary_file() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    printf 'text\0binary\0' > blob.bin
    local output=$(_zsh_ai_attach_block "read @blob.bin")
    assert_contains "$output" "skipped, binary file"
    assert_not_contains "$output" "binary\0"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_reports_exhausted_budget() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    printf 'aaaa\n' > a.txt
    printf 'bbbb\n' > b.txt
    local output=$(ZSH_AI_ATTACH_TOTAL_BYTES=2 _zsh_ai_attach_block "@a.txt @b.txt")
    assert_contains "$output" "attachment budget exhausted"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_user_message_keeps_request_text() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    printf 'payload\n' > notes.txt
    local output=$(_zsh_ai_build_user_message "explain @notes.txt")
    assert_contains "$output" "explain @notes.txt"
    assert_contains "$output" "payload"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_user_message_unchanged_without_attachments() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    local output=$(_zsh_ai_build_user_message "list files by size")
    assert_equals "$output" "list files by size"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

run_test "Resolves an existing file" test_resolves_existing_file
run_test "Ignores a missing file" test_ignores_missing_file
run_test "Strips trailing punctuation" test_strips_trailing_punctuation
run_test "Keeps dots in filenames" test_keeps_dots_in_filenames
run_test "Double @ escapes a reference" test_double_at_is_escaped
run_test "Caps the number of attached files" test_caps_number_of_files
run_test "Deduplicates repeated references" test_deduplicates_repeated_reference
run_test "Inlines file contents" test_inlines_file_contents
run_test "Truncates a large file" test_truncates_large_file
run_test "Skips a binary file" test_skips_binary_file
run_test "Reports an exhausted byte budget" test_reports_exhausted_budget
run_test "User message keeps the request text" test_user_message_keeps_request_text
run_test "User message unchanged without attachments" test_user_message_unchanged_without_attachments

finish_tests
