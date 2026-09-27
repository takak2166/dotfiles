# dotfiles
my dotfiles managed with [chezmoi](https://www.chezmoi.io/)

## Install
```bash
chezmoi init https://github.com/takak2166/dotfiles.git
chezmoi apply
```

## Secret scanning (gitleaks)

All git repositories on this machine use a **global** `pre-commit` hook (`core.hooksPath = ~/.config/git/hooks`) that runs [gitleaks](https://github.com/gitleaks/gitleaks) on **staged** changes before each commit.

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
chezmoi apply   # installs ~/.config/git/hooks/pre-commit and ~/.config/gitleaks/gitleaks.toml
```

### Smoke test (any repo)

```bash
cd /path/to/any/git/repo
echo 'AWS_SECRET_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE' > /tmp/leak-test.txt
git add /tmp/leak-test.txt   # or copy into repo and stage
git commit -m test           # should be rejected by gitleaks
```

Shared allowlist: edit `dot_config/gitleaks/gitleaks.toml` in this repo, then `chezmoi apply`.

See [Linear TAK-100](https://linear.app/me-time/issue/TAK-100/pre-commit-による秘密情報webhook-url-混入防止).