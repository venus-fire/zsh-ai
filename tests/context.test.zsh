#!/usr/bin/env zsh

# Load test helper
source "${0:A:h}/test_helper.zsh"

# Load the context module
source "$PLUGIN_DIR/lib/context.zsh"

# Test functions

# Project type detection tests
test_detects_nodejs_project() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch package.json
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "node"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_rust_project() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch Cargo.toml
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "rust"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_python_project_requirements() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch requirements.txt
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "python"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_python_project_setup() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch setup.py
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "python"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_python_project_pyproject() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch pyproject.toml
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "python"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_ruby_project() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch Gemfile
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "ruby"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_go_project() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch go.mod
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "go"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_php_project() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch composer.json
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "php"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_java_project_pom() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch pom.xml
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "java"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_java_project_gradle() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch build.gradle
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "java"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_docker_project_compose() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch docker-compose.yml
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "docker"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_docker_project_dockerfile() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch Dockerfile
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "docker"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_returns_unknown_for_unrecognized_project() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch random.txt
    local output=$(_zsh_ai_detect_project_type)
    assert_equals "$output" "unknown"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

# Git context tests
test_returns_empty_for_non_git_directory() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    local output=$(_zsh_ai_get_git_context)
    assert_equals "$output" ""
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_gets_git_context_for_repository() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    git init >/dev/null 2>&1
    git checkout -b test-branch >/dev/null 2>&1
    local output=$(_zsh_ai_get_git_context)
    assert_contains "$output" "Git: branch=test-branch"
    assert_contains "$output" "status=clean"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_detects_dirty_git_status() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    git init >/dev/null 2>&1
    touch test.txt
    git add test.txt
    local output=$(_zsh_ai_get_git_context)
    assert_contains "$output" "status=dirty"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

# Directory context tests
test_shows_current_directory_in_context() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    local output=$(_zsh_ai_get_directory_context)
    assert_contains "$output" "Current directory: $TEST_DIR"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_tree_lists_nested_entries() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    touch top.txt
    mkdir -p sub
    touch sub/inner.txt
    local output=$(_zsh_ai_get_directory_context)
    assert_contains "$output" "Tree (depth 2):"
    assert_contains "$output" "top.txt"
    assert_contains "$output" "sub/"
    assert_contains "$output" "sub/inner.txt"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_tree_lists_directory_with_trailing_slash() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    mkdir -p lib
    touch lib/a.zsh
    _zsh_ai_tree_listing
    assert_contains "$_ZSH_AI_TREE_LISTING" "lib/"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_tree_caps_entries_at_max() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    for i in {1..15}; do
        touch "file$i.txt"
    done
    local output=$(ZSH_AI_TREE_MAX=5 _zsh_ai_get_directory_context)
    assert_contains "$output" "10 of 15 entries omitted"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_tree_prunes_noise_directories() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    mkdir -p node_modules/pkg .git/objects __pycache__
    touch node_modules/pkg/index.js
    touch keep.txt
    local output=$(_zsh_ai_get_directory_context)
    assert_not_contains "$output" "node_modules"
    assert_not_contains "$output" "__pycache__"
    assert_contains "$output" "keep.txt"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_tree_depth_is_configurable() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    mkdir -p sub
    touch sub/inner.txt
    local output=$(ZSH_AI_TREE_DEPTH=1 _zsh_ai_get_directory_context)
    assert_contains "$output" "Tree (depth 1):"
    assert_contains "$output" "sub/"
    assert_not_contains "$output" "sub/inner.txt"

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_tree_disabled_falls_back_to_count() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"

    for i in {1..4}; do
        touch "file$i.txt"
    done
    local output=$(ZSH_AI_TREE_DEPTH=0 _zsh_ai_get_directory_context)
    assert_contains "$output" "Files: 4 files in directory"
    assert_not_contains "$output" "Tree ("

    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

# Context building tests
test_builds_complete_context() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch package.json
    git init >/dev/null 2>&1
    local output=$(_zsh_ai_build_context)
    assert_contains "$output" "Current directory:"
    assert_contains "$output" "Project type: node"
    assert_contains "$output" "Git:"
    assert_contains "$output" "OS:"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_builds_context_without_git() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch requirements.txt
    local output=$(_zsh_ai_build_context)
    assert_contains "$output" "Current directory:"
    assert_contains "$output" "Project type: python"
    assert_contains "$output" "OS:"
    assert_not_contains "$output" "Git:"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_builds_context_for_unknown_project() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    touch random.txt
    local output=$(_zsh_ai_build_context)
    assert_contains "$output" "Current directory:"
    assert_not_contains "$output" "Project type:"
    assert_contains "$output" "OS:"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

test_includes_os_information() {
    setup_test_env
    local TEST_DIR=$(create_test_dir)
    cd "$TEST_DIR"
    
    local output=$(_zsh_ai_build_context)
    local os_name=$(uname -s)
    assert_contains "$output" "OS: $os_name"
    
    cd - >/dev/null 2>&1
    cleanup_test_dir "$TEST_DIR"
    teardown_test_env
}

# Run tests
echo "Running context tests..."
run_test "Detects Node.js project" test_detects_nodejs_project
run_test "Detects Rust project" test_detects_rust_project
run_test "Detects Python project with requirements.txt" test_detects_python_project_requirements
run_test "Detects Python project with setup.py" test_detects_python_project_setup
run_test "Detects Python project with pyproject.toml" test_detects_python_project_pyproject
run_test "Detects Ruby project" test_detects_ruby_project
run_test "Detects Go project" test_detects_go_project
run_test "Detects PHP project" test_detects_php_project
run_test "Detects Java project with pom.xml" test_detects_java_project_pom
run_test "Detects Java project with build.gradle" test_detects_java_project_gradle
run_test "Detects Docker project with docker-compose.yml" test_detects_docker_project_compose
run_test "Detects Docker project with Dockerfile" test_detects_docker_project_dockerfile
run_test "Returns unknown for unrecognized project" test_returns_unknown_for_unrecognized_project
run_test "Returns empty string for non-git directory" test_returns_empty_for_non_git_directory
run_test "Gets git context for git repository" test_gets_git_context_for_repository
run_test "Detects dirty git status" test_detects_dirty_git_status
run_test "Shows current directory in context" test_shows_current_directory_in_context
run_test "Lists nested tree entries" test_tree_lists_nested_entries
run_test "Suffixes directories with a slash" test_tree_lists_directory_with_trailing_slash
run_test "Caps tree entries at the configured max" test_tree_caps_entries_at_max
run_test "Prunes noise directories" test_tree_prunes_noise_directories
run_test "Honours configured tree depth" test_tree_depth_is_configurable
run_test "Falls back to a count when the tree is disabled" test_tree_disabled_falls_back_to_count
run_test "Builds complete context" test_builds_complete_context
run_test "Builds context without git" test_builds_context_without_git
run_test "Builds context for unknown project" test_builds_context_for_unknown_project
run_test "Includes OS information" test_includes_os_information
finish_tests
