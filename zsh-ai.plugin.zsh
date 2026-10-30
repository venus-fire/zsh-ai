#!/usr/bin/env zsh

# zsh-ai - AI-powered command suggestions for zsh
# Supports hosted providers plus local Ollama and Apfel models

# Get the directory where this plugin is installed
local plugin_dir="${0:A:h}"

# Source all the module files
source "${plugin_dir}/lib/config.zsh"
source "${plugin_dir}/lib/context.zsh"
source "${plugin_dir}/lib/attach.zsh"
source "${plugin_dir}/lib/history.zsh"
source "${plugin_dir}/lib/providers/anthropic.zsh"
source "${plugin_dir}/lib/providers/ollama.zsh"
source "${plugin_dir}/lib/providers/apfel.zsh"
source "${plugin_dir}/lib/providers/gemini.zsh"
source "${plugin_dir}/lib/providers/openai.zsh"
source "${plugin_dir}/lib/providers/qwen.zsh"
source "${plugin_dir}/lib/providers/grok.zsh"
source "${plugin_dir}/lib/providers/mistral.zsh"
source "${plugin_dir}/lib/utils.zsh"
source "${plugin_dir}/lib/widget.zsh"

# Session history is registered before the widget, so this file's precmd hook
# runs first and reads the real exit status of the command the user just ran.
_zsh_ai_init_session_history

# Initialize the plugin
if _zsh_ai_validate_config; then
    _zsh_ai_init_widget
fi
