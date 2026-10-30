# Troubleshooting

Try `zsh-ai "show current date"` first; errors are easier to see there.

## Missing API key

Set the [key for your provider](INSTALL.md#providers) before the plugin loads in
`~/.zshrc`, then reload it with `source ~/.zshrc`. For the default provider:

```zsh
export ANTHROPIC_API_KEY="your-key-here"
```

Keep keys out of public dotfiles. [Ollama](INSTALL.md#ollama) works without one.

## Ollama isn't reachable

Start it with `ollama serve` if it isn't running. In another terminal, run
`ollama pull llama3.2` to download the default model.

If it's already running, check the URL. It must be a base URL with no `/v1` suffix:

```zsh
export ZSH_AI_OLLAMA_URL="http://localhost:11434"
```

## Apfel is not ready

Apfel needs an Apple Silicon Mac, macOS 26 or later, Apple Intelligence, and
the downloaded on-device model. Check its state:

```zsh
apfel --model-info
```

Install and start the service when needed:

```zsh
brew install apfel
brew services start apfel
```

Apfel and Ollama both use port 11434 by default. If both services run, start
Apfel on another port and set the full endpoint before zsh-ai loads:

```zsh
apfel --serve --port 11435
export ZSH_AI_APFEL_URL="http://127.0.0.1:11435/v1/chat/completions"
```

If Apfel reports a context-limit error or incomplete output, shorten the request
or `ZSH_AI_PROMPT_EXTEND`. zsh-ai rejects incomplete output instead of offering
it as a command.

## The comment trigger doesn't work

Use `# ` with a space, or the prefix you set in `ZSH_AI_TRIGGER`. Check that
`ZSH_AI_COMMENT_HOOK` isn't disabled, then open a new terminal.

If `zsh-ai "list files"` works but the trigger doesn't, another plugin may be
replacing the Enter binding. Try loading zsh-ai after your other plugins.

## Pasted comments trigger a request

Choose a prefix you don't normally paste, such as `export ZSH_AI_TRIGGER=",,"`.
Or set `export ZSH_AI_COMMENT_HOOK=false` and use `zsh-ai "..."` directly.
Put the setting before the plugin loads, then open a new terminal.

## JSON parsing fails

Install `jq` with `brew install jq` or `sudo apt-get install jq`, then retry.

## An attached file was not sent

Check three things, in this order. The word must start with `@` and nothing
before it, so a mail address does not count. The path resolves from the current
directory, not from the query text. And the file must be readable text: files
containing NUL bytes are skipped by name, and a file larger than
`ZSH_AI_ATTACH_MAX_BYTES` is sent truncated with a note saying so.

Run `_zsh_ai_attach_paths "your query"` to see which paths resolve, and
`_zsh_ai_attach_block "your query"` to see exactly what would be sent.

## Still stuck?

Run `zsh-ai` with no arguments to check the active provider. [Open an
issue](https://github.com/matheusml/zsh-ai/issues) with your OS, `zsh --version`,
provider, model, install method, and exact error. Remove any API keys before posting.
