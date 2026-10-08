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
# AKIA…EXAMPLE is ignored by the default aws-access-token allowlist.
# gitleaks:allow applies only to this source line, not to the file it writes.
echo 'AWS_SECRET_ACCESS_KEY=AKIAIOSFODNN7EXAMPLX' > leak-test.txt  # gitleaks:allow
git add leak-test.txt
git commit -m test           # should be rejected by gitleaks
rm -f leak-test.txt
```

Shared allowlist: uncomment the `[[allowlists]]` template in `dot_config/gitleaks/gitleaks.toml` and add at least one check (`commits`, `paths`, `regexes`, or `stopwords`), then `chezmoi apply`. An allowlist with no checks is a gitleaks configuration error.
