#!/usr/bin/env zsh

# File attachment support for zsh-ai.
#
# A query can reference files by prefixing a word with @:
#
#   # why does @src/main.py fail when I pass --verbose
#   # compare @package.json and @package-lock.json
#
# Every @reference that resolves to a readable regular file is read at query
# time and inlined into the user message, so the model sees the request and the
# file contents together. Tokens that do not resolve are left alone, so an
# unrelated @ in the query costs nothing.
#
# Limits are configurable (see config.zsh). @@ escapes a literal @ and is never
# treated as an attachment.

# Strip punctuation a sentence leaves attached to a path, without touching dots,
# which are part of ordinary filenames.
_zsh_ai_strip_token_punctuation() {
    local token="$1"
    local -a trailing
    trailing=(',' ';' ':' '?' '!' ')' '}' "'" '"')
    local last

    while (( ${#token} > 0 )); do
        last="${token[-1]}"
        (( ${trailing[(Ie)$last]} )) || break
        token="${token[1,-2]}"
    done

    print -r -- "$token"
}

# Expand a leading ~ without enabling globbing on the rest of the path.
# NOTE: do not name this variable `path`. In zsh `path` is a special array tied
# to PATH, so `local path=...` silently rewrites PATH inside the function and
# every external command after it fails to resolve.
_zsh_ai_expand_home() {
    local home_path="$1"

    if [[ "$home_path" == '~' ]]; then
        print -r -- "$HOME"
    elif [[ "$home_path" == '~/'* ]]; then
        print -r -- "$HOME/${home_path#\~/}"
    else
        print -r -- "$home_path"
    fi
}

# Return 0 when the file looks binary, 1 otherwise. NUL bytes in the head of the
# file are the test, which is what git and diff use.
_zsh_ai_is_binary_file() {
    perl -e '
        open(my $fh, "<", $ARGV[0]) or exit 2;
        binmode $fh;
        my $buf = "";
        read($fh, $buf, 8192);
        exit(($buf =~ /\0/) ? 0 : 1);
    ' "$1"
}

# Resolve the @references in a query to absolute paths, one per line.
# Unresolvable tokens are dropped silently. Order follows the query, duplicates
# collapse, and the count is capped at ZSH_AI_ATTACH_MAX_FILES.
_zsh_ai_attach_paths() {
    local query="$1"
    local -a tokens paths
    local token candidate

    [[ "$query" == *@* ]] || return 0

    tokens=("${(@z)query}")

    for token in "${tokens[@]}"; do
        [[ "$token" == @* ]] || continue
        [[ "$token" == @@* ]] && continue

        candidate=$(_zsh_ai_strip_token_punctuation "${token#@}")
        [[ -z "$candidate" ]] && continue
        candidate=$(_zsh_ai_expand_home "$candidate")
        [[ -f "$candidate" && -r "$candidate" ]] || continue

        paths+=("${candidate:A}")
    done

    (( ${#paths} == 0 )) && return 0

    paths=("${(@u)paths}")

    local max="${ZSH_AI_ATTACH_MAX_FILES:-8}"
    [[ "$max" == <1-> ]] || max=8
    if (( ${#paths} > max )); then
        paths=("${(@)paths[1,$max]}")
    fi

    print -rl -- "${paths[@]}"
}

# Build the attachment block for a query. Prints nothing when the query has no
# resolvable attachments, which keeps requests without @ unchanged.
_zsh_ai_attach_block() {
    local query="$1"
    local -a paths
    local file size take content truncated
    local block=""

    paths=("${(@f)$(_zsh_ai_attach_paths "$query")}")
    [[ -z "${paths[1]:-}" ]] && return 0

    local max_bytes="${ZSH_AI_ATTACH_MAX_BYTES:-8192}"
    local remaining="${ZSH_AI_ATTACH_TOTAL_BYTES:-32768}"
    [[ "$max_bytes" == <1-> ]] || max_bytes=8192
    [[ "$remaining" == <1-> ]] || remaining=32768

    for file in "${paths[@]}"; do
        [[ -f "$file" ]] || continue

        if _zsh_ai_is_binary_file "$file"; then
            block+="### $file (skipped, binary file)"$'\n'
            continue
        fi

        size=$(wc -c < "$file" 2>/dev/null | tr -d ' ')
        [[ "$size" == <0-> ]] || size=0

        take=$max_bytes
        if (( remaining < take )); then
            take=$remaining
        fi
        if (( take <= 0 )); then
            block+="### $file (skipped, attachment budget exhausted)"$'\n'
            continue
        fi

        content=$(head -c "$take" "$file" 2>/dev/null)
        remaining=$(( remaining - take ))

        truncated=""
        if (( size > take )); then
            truncated=" (truncated at $take bytes, file is $size bytes)"
        fi

        block+="### $file$truncated"$'\n```'$'\n'"$content"$'\n```'$'\n'
    done

    [[ -z "$block" ]] && return 0

    print -r -- "Attached files, read from disk when the query was sent:"$'\n'"$block"
}

# Assemble the user message: the request as typed, plus any attached files.
# The @references stay in the request text so the model can map content to path.
_zsh_ai_build_user_message() {
    local query="$1"
    local block=$(_zsh_ai_attach_block "$query")

    if [[ -n "$block" ]]; then
        print -r -- "$query"$'\n\n'"$block"
    else
        print -r -- "$query"
    fi
}

# Completion for @references: `# explain @src/ma<TAB>` completes the path with
# the @ kept in place. Falls back to ordinary file completion for plain words.
_zsh_ai_attach_complete() {
    if [[ "${words[CURRENT]}" == @* ]]; then
        compset -P '@'
    fi
    _files
}

# Register completion for the trigger line. Harmless if compinit never ran.
_zsh_ai_register_completion() {
    (( $+functions[compdef] )) || return 0

    local key="${ZSH_AI_TRIGGER:-# }"
    key="${key%% }"

    compdef _zsh_ai_attach_complete "$key"
}

_zsh_ai_register_init_completion() {
    _zsh_ai_register_completion
}
