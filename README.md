<p align="center">
  <img src="assets/logo.png" alt="zsh-ai: a green gecko curled around a retro terminal" width="200">
</p>

<h1 align="center">zsh-ai</h1>

Type `# ` and describe a command. Press Enter to get it at your prompt.

```console
$ # find files larger than 100mb changed this week
$ find . -type f -size +100M -mtime -7
```

Read it, edit it if needed, then press Enter again to run it.

<img src="assets/demo.gif" alt="Demo: typing # list all files and waiting for zsh-ai to suggest ls -la" width="520">

You can also ask directly:

```zsh
zsh-ai "show what is using port 3000"
```

Your request includes the directory path, a two-level tree of the working
directory, project type, git branch/status, the commands this shell has already
run, and OS. Choose a hosted provider, or run a local model with Ollama or
Apfel. Apfel uses Apple's on-device model on supported Macs.

Attach files by prefixing a word with `@`, and press Tab to complete the path:

```console
$ # why does @src/main.py exit 1 when --verbose is set
```

The file is read at query time and sent with the request, so the model sees the
code and not just its name. Attachments are capped at 8192 bytes per file and
32768 bytes per query.

Ask about what just happened without repeating it:

```console
$ npm test
  exit 1
$ # why did that fail
```

Every command run in the shell is recorded with its exit status, up to the most
recent 48, so the model has the prior attempt in view. The list is in memory
only, never written to disk, and credential-shaped arguments are redacted before
it is sent. See [Fork changes](#fork-changes) for the limits and how to turn it
off.

## Install

This is a fork. Install from source so you are running this code rather than the
upstream release:

```zsh
git clone https://github.com/venus-fire/zsh-ai ~/Projects/zsh-ai
```

For the upstream plugin instead, use its Homebrew tap:
`brew install matheusml/zsh-ai/zsh-ai`.

Needs zsh 5.0+, `curl`, and `perl`. `jq` is optional.

Add this to `~/.zshrc` (keep your key out of public dotfiles):

```zsh
export ANTHROPIC_API_KEY="your-key-here"
source "$HOME/Projects/zsh-ai/zsh-ai.plugin.zsh"
```

Run `source ~/.zshrc`, then try `# show current date`.

See the [install guide](INSTALL.md) for Oh My Zsh, Antigen, manual installs,
[other providers](INSTALL.md#providers), and local models.

### Free local Apfel on supported Macs

On Apple Silicon with macOS 26+, Apple Intelligence, and the on-device model
available, Apfel generates commands locally without an API key or hosted
provider. See the [Apfel setup](INSTALL.md#apfel).

## Make it yours

Add command preferences before the plugin loads in `~/.zshrc`:

```zsh
export ZSH_AI_PROMPT_EXTEND="Prefer rg over grep and fd over find."
```

You can also [change the comment trigger or turn it off](INSTALL.md#inline-trigger).

## Fork changes

This repository is a fork of [matheusml/zsh-ai](https://github.com/matheusml/zsh-ai),
which remains the upstream. Knowing which half of the code came from where
matters if you plan to send a patch upstream or to read this fork's history.

### Original work, upstream

Everything the plugin fundamentally is: the `# ` trigger and the Enter widget,
the guarantee that a generated command lands in the prompt for review and is
never executed for you, the provider modules for Anthropic, OpenAI, Gemini,
Mistral, Grok, Qwen, Ollama, Apfel and custom endpoints, the JSON escaping, the
test harness and runner, and the original README, INSTALL and TROUBLESHOOTING
guides. Written and maintained by matheusml and upstream contributors.

### Added in this fork

Written by Hermes Agent, an AI coding agent, running the `deepseek-flash-latest`
router model at low reasoning effort, working from Venus Fire's instructions and
reviewing its own test output. Not upstream, not reviewed by matheusml, and not
a claim on his design.

- A two-level directory tree in the request, capped at 48 entries, with VCS
  metadata, dependency directories and caches pruned before the cap applies.
  This replaced the flat `ls` listing, which named only ten files and only in
  directories holding twenty or fewer. `ZSH_AI_TREE_DEPTH=0` restores the old
  file-count line.
- `@file` attachments: any query word prefixed with `@` is resolved against the
  working directory and inlined into the request, with Tab completion, `@@`
  escaping, binary detection, per-file and per-query byte caps, and a note in
  the request when a file was truncated.
- Session command history: every command run in the shell, with its exit status,
  up to the most recent 48, plus a redaction pass for credential-shaped
  arguments. Off with `ZSH_AI_SESSION_HISTORY=false`, cap with
  `ZSH_AI_SESSION_HISTORY_MAX`.
- `lib/attach.zsh` and `lib/history.zsh` as new modules, 33 new tests, and the
  docs describing the above.

The fork's commits are `cc64205` and `eece5bf` on `main`, which sits directly on
top of upstream `629d46d`. Everything before that is upstream history, unchanged.

[Troubleshooting](TROUBLESHOOTING.md) · [Contributing](CONTRIBUTING.md) · [MIT license](LICENSE)
