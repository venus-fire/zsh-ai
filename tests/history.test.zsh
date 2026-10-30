#!/usr/bin/env zsh

# Load test helper
source "${0:A:h}/test_helper.zsh"

# Load the session history module
source "$PLUGIN_DIR/lib/history.zsh"

# Recording tests
test_records_command_and_status() {
    setup_test_env
    _zsh_ai_session_history_clear

    _zsh_ai_preexec_capture "echo hello"
    false
    _zsh_ai_precmd_capture

    assert_equals "${_ZSH_AI_SESSION_CMDS[1]}" "echo hello [1]"

    _zsh_ai_session_history_clear
    teardown_test_env
}

test_records_zero_status() {
    setup_test_env
    _zsh_ai_session_history_clear

    _zsh_ai_preexec_capture "true"
    true
    _zsh_ai_precmd_capture

    assert_equals "${_ZSH_AI_SESSION_CMDS[1]}" "true [0]"

    _zsh_ai_session_history_clear
    teardown_test_env
}

test_ignores_empty_command() {
    setup_test_env
    _zsh_ai_session_history_clear

    _zsh_ai_preexec_capture ""
    _zsh_ai_precmd_capture
    assert_equals "${#_ZSH_AI_SESSION_CMDS}" "0"

    _zsh_ai_preexec_capture "   "
    _zsh_ai_precmd_capture
    assert_equals "${#_ZSH_AI_SESSION_CMDS}" "0"

    _zsh_ai_session_history_clear
    teardown_test_env
}

test_collapses_multiline_command() {
    setup_test_env
    _zsh_ai_session_history_clear

    _zsh_ai_preexec_capture $'for i in 1 2\ndo echo $i\ndone'
    true
    _zsh_ai_precmd_capture

    assert_contains "${_ZSH_AI_SESSION_CMDS[1]}" " ; "
    assert_not_contains "${_ZSH_AI_SESSION_CMDS[1]}" $'\n'

    _zsh_ai_session_history_clear
    teardown_test_env
}

test_caps_at_configured_max() {
    setup_test_env
    _zsh_ai_session_history_clear

    local i
    for i in {1..5}; do
        _zsh_ai_preexec_capture "cmd$i"
        true
        ZSH_AI_SESSION_HISTORY_MAX=3 _zsh_ai_precmd_capture
    done

    assert_equals "${#_ZSH_AI_SESSION_CMDS}" "3"
    assert_equals "${_ZSH_AI_SESSION_CMDS[1]}" "cmd3 [0]"
    assert_equals "${_ZSH_AI_SESSION_CMDS[3]}" "cmd5 [0]"

    unset ZSH_AI_SESSION_HISTORY_MAX
    _zsh_ai_session_history_clear
    teardown_test_env
}

test_truncates_long_command() {
    setup_test_env
    _zsh_ai_session_history_clear

    local long=$(printf 'a%.0s' {1..300})
    _zsh_ai_preexec_capture "$long"
    true
    ZSH_AI_SESSION_HISTORY_CMD_MAX=50 _zsh_ai_precmd_capture

    local recorded="${_ZSH_AI_SESSION_CMDS[1]}"
    assert_contains "$recorded" "..."
    assert_greater_than 60 "${#recorded}"

    unset ZSH_AI_SESSION_HISTORY_CMD_MAX
    _zsh_ai_session_history_clear
    teardown_test_env
}

# Redaction tests
test_redacts_api_key_shapes() {
    setup_test_env

    local output=$(_zsh_ai_redact_command "export GITHUB_TOKEN=ghp_abcdefghijklmnopqrstuvwx")
    assert_contains "$output" "[REDACTED]"
    assert_not_contains "$output" "ghp_abcdefghijklmnopqrstuvwx"

    output=$(_zsh_ai_redact_command "curl -H 'x-api-key: sk-live-abcdefghijklmnop'")
    assert_contains "$output" "[REDACTED]"

    output=$(_zsh_ai_redact_command "aws configure set aws_access_key_id AKIAIOSFODNN7EXAMPLE")
    assert_contains "$output" "[REDACTED]"
    assert_not_contains "$output" "AKIAIOSFODNN7EXAMPLE"

    teardown_test_env
}

test_redacts_password_argument() {
    setup_test_env

    local output=$(_zsh_ai_redact_command "mysql --password=hunter2 -u root")
    assert_contains "$output" "[REDACTED]"
    assert_not_contains "$output" "hunter2"

    teardown_test_env
}

test_keeps_git_hashes() {
    setup_test_env

    local sha="531b4b807ccb8af1a009f8c94adc2e67b9be861a"
    local output=$(_zsh_ai_redact_command "git checkout $sha")
    assert_contains "$output" "$sha"

    teardown_test_env
}

test_redaction_can_be_disabled() {
    setup_test_env

    local output=$(ZSH_AI_SESSION_HISTORY_REDACT=false _zsh_ai_redact_command "export GITHUB_TOKEN=ghp_abcdefghijklmnopqrstuvwx")
    assert_contains "$output" "ghp_abcdefghijklmnopqrstuvwx"

    unset ZSH_AI_SESSION_HISTORY_REDACT
    teardown_test_env
}

# Context tests
test_context_is_empty_before_any_command() {
    setup_test_env
    _zsh_ai_session_history_clear

    local output=$(_zsh_ai_session_history_context)
    assert_equals "$output" ""

    teardown_test_env
}

test_context_reports_last_command() {
    setup_test_env
    _zsh_ai_session_history_clear

    _zsh_ai_preexec_capture "make test"
    false
    _zsh_ai_precmd_capture

    local output=$(_zsh_ai_session_history_context)
    assert_contains "$output" "Last command: make test [1]"
    assert_contains "$output" "Commands run in this shell (1"

    _zsh_ai_session_history_clear
    teardown_test_env
}

test_context_lists_all_commands_oldest_first() {
    setup_test_env
    _zsh_ai_session_history_clear

    _zsh_ai_preexec_capture "first"
    true
    _zsh_ai_precmd_capture
    _zsh_ai_preexec_capture "second"
    true
    _zsh_ai_precmd_capture

    local output=$(_zsh_ai_session_history_context)
    assert_contains "$output" "- first [0]"
    assert_contains "$output" "- second [0]"

    local first_line=$(print -r -- "$output" | grep -n -- '- first \[0\]' | cut -d: -f1)
    local second_line=$(print -r -- "$output" | grep -n -- '- second \[0\]' | cut -d: -f1)
    assert_greater_than "$second_line" "$first_line"

    _zsh_ai_session_history_clear
    teardown_test_env
}

test_context_empty_when_disabled() {
    setup_test_env
    _zsh_ai_session_history_clear

    _zsh_ai_preexec_capture "secret-command"
    true
    _zsh_ai_precmd_capture

    local output=$(ZSH_AI_SESSION_HISTORY=false _zsh_ai_session_history_context)
    assert_equals "$output" ""

    unset ZSH_AI_SESSION_HISTORY
    _zsh_ai_session_history_clear
    teardown_test_env
}

run_test "Records a command with its exit status" test_records_command_and_status
run_test "Records a zero exit status" test_records_zero_status
run_test "Ignores an empty command" test_ignores_empty_command
run_test "Collapses a multi-line command" test_collapses_multiline_command
run_test "Caps the list at the configured max" test_caps_at_configured_max
run_test "Truncates an overlong command" test_truncates_long_command
run_test "Redacts API key shapes" test_redacts_api_key_shapes
run_test "Redacts a password argument" test_redacts_password_argument
run_test "Keeps git commit hashes" test_keeps_git_hashes
run_test "Redaction can be disabled" test_redaction_can_be_disabled
run_test "Context is empty before any command" test_context_is_empty_before_any_command
run_test "Context reports the last command" test_context_reports_last_command
run_test "Context lists commands oldest first" test_context_lists_all_commands_oldest_first
run_test "Context is empty when disabled" test_context_empty_when_disabled

finish_tests
