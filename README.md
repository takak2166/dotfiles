# dotfiles
my dotfiles managed with [chezmoi](https://www.chezmoi.io/)

## Install
```bash
chezmoi init https://github.com/takak2166/dotfiles.git
chezmoi apply
```

## Secret scanning (gitleaks)

All git repositories on this machine use a **global** `pre-commit` hook (`core.hooksPath = ~/.config/git/hooks`) that runs [gitleaks](https://github.com/gitleaks/gitleaks) on **staged** changes before each commit.

Existing `~/.gitconfig` is **not replaced**: `chezmoi apply` adds an `[include]` entry pointing at `~/.config/git/config.d/chezmoi-hooks.ini` (see `modify_dot_gitconfig` in this repo).

The global hook runs a repository’s `.git/hooks/pre-commit` first (when present and executable), then gitleaks. Other hook types (e.g. `commit-msg`, `pre-push`) are still only invoked from the global hooks directory while `core.hooksPath` is set.

### Prerequisites

Install `gitleaks` yourself (not installed by chezmoi). Examples:

```bash
# Debian/Ubuntu
sudo apt install gitleaks

# Or official release binary → ~/.local/bin
```

If `gitleaks` is missing, **commits fail** (fail-closed).

### Apply hook files

```bash
chezmoi apply   # hooks, gitleaks config, git include fragment, ~/.gitconfig include
```

### Smoke test (any repo)

```bash
cd /path/to/any/git/repo
echo 'AWS_SECRET_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE' > leak-test.txt
git add leak-test.txt
git commit -m test           # should be rejected by gitleaks
rm -f leak-test.txt
```

Shared allowlist: edit `dot_config/gitleaks/gitleaks.toml` in this repo, then `chezmoi apply`.

## APM CLI (user install + daily self-update)

Chezmoi deploys a **user-local** APM under `~/.local` and a **systemd user timer** that runs at **04:00 Asia/Tokyo** (`apm-self-update.timer` → `apm-self-update.service` → `~/.local/bin/apm-self-update-daily`). The helper runs `apm self-update --check` and calls `apm self-update` only when an update is reported.

`chezmoi apply` runs `run_onchange_after-apm-self-update-systemd.sh.tmpl` to `daemon-reload` and `enable --now` the timer.

### One-time migration (manual; owner approval before production)

Move off a root-level `/usr/local` install if present:

```bash
# 1) User-local install (no sudo) — defaults: ~/.local/bin, ~/.local/lib/apm
curl -sSL https://aka.ms/apm-unix | sh -s -- --prefix "$HOME/.local"

# 2) Pin self-update target and PATH (same paths install.sh uses by default)
apm config set self-update.install-dir "$HOME/.local/bin"
# Ensure login shells prefer ~/.local/bin before /usr/local/bin

# 3) Verify
command -v apm && apm --version   # should resolve to ~/.local/bin/apm

# 4) After verification — remove old system install (sudo once)
sudo rm -f /usr/local/bin/apm
sudo rm -rf /usr/local/lib/apm

# 5) User timers without a login session (e.g. headless workers)
loginctl show-user "$USER" -p Linger   # if Linger=no:
sudo loginctl enable-linger "$USER"

# 6) chezmoi apply on this machine (enables the timer)
chezmoi apply
```

`apm self-update` reuses the [official install script](https://github.com/microsoft/apm/blob/main/install.sh); it does not invoke `sudo`. With `self-update.install-dir` set, updates stay under `~/.local` ([installer env](https://github.com/microsoft/apm/blob/v0.24.0/src/apm_cli/commands/self_update.py), `APM_INSTALL_DIR` / `get_self_update_install_dir()`).
