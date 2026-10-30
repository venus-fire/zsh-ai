#!/usr/bin/env zsh

# Session command history for zsh-ai.
#
# Records every command run in the current shell, with its exit status, so a
# query can refer to "that" and mean the thing that just failed. The record
# starts when the shell starts and is capped at the most recent
# ZSH_AI_SESSION_HISTORY_MAX commands (default 48).
#
# Nothing here is written to disk. The list lives in this shell's memory and is
# only ever sent as part of a request.
#
# Recording is done with a preexec/precmd pair:
#   preexec - remembers the command line about to run
#   precmd  - reads $? for that command and appends "command [status]"
# The precmd hook must be registered before any other precmd hook, because later
# hooks overwrite $? before a later-registered function sees it.

: ${ZSH_AI_SESSION_HISTORY:=true}
: ${ZSH_AI_SESSION_HISTORY_MAX:=48}
: ${ZSH_AI_SESSION_HISTORY_REDACT:=true}
: ${ZSH_AI_SESSION_HISTORY_CMD_MAX:=200}

typeset -ga _ZSH_AI_SESSION_CMDS=()
typeset -g _ZSH_AI_PENDING_CMD=""

_zsh_ai_session_history_enabled() {
    case "${ZSH_AI_SESSION_HISTORY:l}" in
        false|off|no|0|disabled) return 1 ;;
        *) return 0 ;;
    esac
}

# Redact things that look like credentials before a command leaves the machine.
# Git-style 40-character hashes are deliberately left alone: they are ordinary
# arguments to ordinary commands, and 32-character hex plus UUIDs are the shapes
# that actually show up in keys.
_zsh_ai_redact_command() {
    local cmd="$1"

    case "${ZSH_AI_SESSION_HISTORY_REDACT:l}" in
        false|off|no|0) print -r -- "$cmd"; return 0 ;;
    esac

    print -r -- "$cmd" | perl -pe '
        s/\b(?:sk|rk|ghp|gho|ghs|ghu)_[A-Za-z0-9_-]{12,}/[REDACTED]/g;
        s/\bsk-[A-Za-z0-9_-]{16,}/[REDACTED]/g;
        s/\bAKIA[0-9A-Z]{16}\b/[REDACTED]/g;
        s/\bxox[baprs]-[A-Za-z0-9-]{10,}/[REDACTED]/g;
        s/(?i)((?:password|passwd|secret|token|api[_-]?key|authorization)[=:]\s*)(\S+)/${1}[REDACTED]/g;
        s/\b[0-9a-fA-F]{32}\b/[REDACTED]/g;
        s/\b[0-9a-fA-F]{48,}\b/[REDACTED]/g;
    '
}

_zsh_ai_preexec_capture() {
    _zsh_ai_session_history_enabled || return 0
    _ZSH_AI_PENDING_CMD="$1"
}

_zsh_ai_precmd_capture() {
    local last_status=$?

    _zsh_ai_session_history_enabled || return 0

    local cmd="$_ZSH_AI_PENDING_CMD"
    _ZSH_AI_PENDING_CMD=""

    [[ -z "${cmd//[[:space:]]/}" ]] && return 0

    # A multi-line command becomes a single line so the list stays scannable.
    cmd="${cmd//$'\n'/ ; }"

    local cmd_max="${ZSH_AI_SESSION_HISTORY_CMD_MAX:-200}"
    [[ "$cmd_max" == <1-> ]] || cmd_max=200
    if (( ${#cmd} > cmd_max )); then
        cmd="${cmd[1,$cmd_max]}..."
    fi

    cmd=$(_zsh_ai_redact_command "$cmd")

    _ZSH_AI_SESSION_CMDS+=("$cmd [$last_status]")

    local cap="${ZSH_AI_SESSION_HISTORY_MAX:-48}"
    [[ "$cap" == <1-> ]] || cap=48
    if (( ${#_ZSH_AI_SESSION_CMDS} > cap )); then
        _ZSH_AI_SESSION_CMDS=("${(@)_ZSH_AI_SESSION_CMDS[-$cap,-1]}")
    fi

    return 0
}

# Context block for the system prompt. Empty until the first command has run.
_zsh_ai_session_history_context() {
    _zsh_ai_session_history_enabled || return 0

    local count=${#_ZSH_AI_SESSION_CMDS}
    (( count == 0 )) && return 0

    print -r -- "Last command: ${_ZSH_AI_SESSION_CMDS[-1]}"
    print -r -- "Commands run in this shell ($count, oldest first, format: command [exit status]):"

    local entry
    for entry in "${_ZSH_AI_SESSION_CMDS[@]}"; do
        print -r -- "- $entry"
    done
}

# Register the hooks. Call this before any other precmd hook is added, so the
# status this file records is the status of the command the user actually ran.
_zsh_ai_init_session_history() {
    [[ -o interactive ]] || return 0
    _zsh_ai_session_history_enabled || return 0

    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _zsh_ai_preexec_capture
    add-zsh-hook precmd _zsh_ai_precmd_capture
}

# Test helpers and manual inspection
_zsh_ai_session_history_clear() {
    _ZSH_AI_SESSION_CMDS=()
    _ZSH_AI_PENDING_CMD=""
}
