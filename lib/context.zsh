#!/usr/bin/env zsh

# Context detection functions for zsh-ai

# Function to detect project type
_zsh_ai_detect_project_type() {
    local project_type="unknown"
    
    if [[ -f "package.json" ]]; then
        project_type="node"
    elif [[ -f "Cargo.toml" ]]; then
        project_type="rust"
    elif [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
        project_type="python"
    elif [[ -f "Gemfile" ]]; then
        project_type="ruby"
    elif [[ -f "go.mod" ]]; then
        project_type="go"
    elif [[ -f "composer.json" ]]; then
        project_type="php"
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        project_type="java"
    elif [[ -f "docker-compose.yml" ]] || [[ -f "Dockerfile" ]]; then
        project_type="docker"
    fi
    
    echo "$project_type"
}

# Function to get git context
_zsh_ai_get_git_context() {
    local git_info=""
    
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch=$(git branch --show-current 2>/dev/null)
        local git_status="clean"
        
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            git_status="dirty"
        fi
        
        git_info="Git: branch=$branch, status=$git_status"
    fi
    
    echo "$git_info"
}

# Function to list the working directory as a shallow tree.
# Walks ZSH_AI_TREE_DEPTH levels (default 2), prunes VCS metadata, dependency
# trees and caches, and caps the listing at ZSH_AI_TREE_MAX entries (default 48).
# Results are written to globals rather than printed, because a command
# substitution would run in a subshell and lose them:
#   _ZSH_AI_TREE_LISTING - comma-separated entries, directories suffixed with /
#   _ZSH_AI_TREE_TOTAL   - entries found
#   _ZSH_AI_TREE_OMITTED - entries cut by the cap
_zsh_ai_tree_listing() {
    local depth="${ZSH_AI_TREE_DEPTH:-2}"
    local max="${ZSH_AI_TREE_MAX:-48}"
    local -a raw out
    local entry

    _ZSH_AI_TREE_TOTAL=0
    _ZSH_AI_TREE_OMITTED=0

    raw=("${(@f)$(find . -mindepth 1 -maxdepth "$depth" \
        \( -name '.git' -o -name '.hg' -o -name '.svn' \
           -o -name 'node_modules' -o -name '.venv' -o -name 'venv' \
           -o -name '__pycache__' -o -name '.mypy_cache' -o -name '.pytest_cache' \
           -o -name '.ruff_cache' -o -name 'target' -o -name 'dist' \
           -o -name 'build' -o -name '.next' -o -name '.cache' \
           -o -name '.idea' -o -name '.vscode' -o -name '.tox' \
           -o -name '.gradle' -o -name '.terraform' \) -prune -o -print 2>/dev/null \
        | LC_ALL=C sort)}")

    for entry in "${raw[@]}"; do
        [[ -z "$entry" ]] && continue
        entry="${entry#./}"
        [[ -d "$entry" ]] && entry="${entry%/}/"
        out+=("$entry")
    done

    _ZSH_AI_TREE_TOTAL=${#out}
    if [[ "$max" == <1-> ]] && (( ${#out} > max )); then
        _ZSH_AI_TREE_OMITTED=$(( ${#out} - max ))
        out=("${(@)out[1,$max]}")
    fi

    _ZSH_AI_TREE_LISTING="${(j:, :)out}"
}

# Function to get directory context
_zsh_ai_get_directory_context() {
    local depth="${ZSH_AI_TREE_DEPTH:-2}"
    local dir_context="Current directory: $(pwd)"
    local listing

    if [[ "$depth" == <1-> ]]; then
        _zsh_ai_tree_listing
        listing="$_ZSH_AI_TREE_LISTING"
        if (( ${_ZSH_AI_TREE_TOTAL:-0} == 0 )); then
            dir_context+=$'\n'"Tree (depth $depth): empty"
        elif (( ${_ZSH_AI_TREE_OMITTED:-0} > 0 )); then
            dir_context+=$'\n'"Tree (depth $depth, ${_ZSH_AI_TREE_OMITTED} of ${_ZSH_AI_TREE_TOTAL} entries omitted): $listing"
        else
            dir_context+=$'\n'"Tree (depth $depth): $listing"
        fi
    else
        dir_context+=$'\n'"Files: $(ls -1 2>/dev/null | wc -l | tr -d ' ') files in directory"
    fi

    print -r -- "$dir_context"
}

# Function to build context
_zsh_ai_build_context() {
    local context=""
    
    # Add directory context
    context="$(_zsh_ai_get_directory_context)"
    
    # Add project type
    local project_type=$(_zsh_ai_detect_project_type)
    if [[ "$project_type" != "unknown" ]]; then
        context="$context\nProject type: $project_type"
    fi
    
    # Add git context
    local git_context=$(_zsh_ai_get_git_context)
    if [[ -n "$git_context" ]]; then
        context="$context\n$git_context"
    fi
    
    # Add OS context
    context="$context\nOS: $(uname -s)"
    
    echo "$context"
}