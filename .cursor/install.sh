#!/usr/bin/env bash
# Idempotent Cloud Agent install for this chezmoi-managed dotfiles repo.
# Installs the tools needed to develop and test the dotfiles:
#   - chezmoi : the dotfile manager this repo is built for
#   - pass    : password-store, used by the private_*.tmpl templates
#   - gnupg   : backing store for `pass`
#   - gomplate: referenced by dot_kube/private_config.tmpl for local rendering
#   - apm     : Agent Package Manager that consumes dot_apm/apm.yml
# It also deploys the apm.yml manifest globally and runs `apm install -g` so a
# fresh agent comes up with the declared skills already integrated.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"
export PATH="${BIN_DIR}:${PATH}"

echo "==> Installing system packages (pass, gnupg)"
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    pass gnupg ca-certificates curl
fi

echo "==> Installing chezmoi -> ${BIN_DIR}"
if ! command -v chezmoi >/dev/null 2>&1; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${BIN_DIR}"
fi
chezmoi --version

echo "==> Installing gomplate -> ${BIN_DIR}"
if ! command -v gomplate >/dev/null 2>&1; then
  GOMPLATE_VERSION="v4.3.0"
  curl -fsSL -o "${BIN_DIR}/gomplate" \
    "https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64"
  chmod +x "${BIN_DIR}/gomplate"
fi
gomplate --version

echo "==> Installing apm (Agent Package Manager) -> ${BIN_DIR}"
if ! command -v apm >/dev/null 2>&1; then
  curl -sSL https://aka.ms/apm-unix | APM_INSTALL_DIR="${BIN_DIR}" sh
fi
apm --version || true

echo "==> Deploying apm manifest and installing agent packages (global scope)"
# Mirror chezmoi's target for dot_apm/apm.yml (-> ~/.apm/apm.yml), then install
# the declared skills into the user-scope agent harness (~/.agents/).
# Kept non-fatal: it fetches several external GitHub repos, so a transient
# network/registry failure must not brick the rest of the environment. The
# tooling above is already usable, and `apm install -g` can be re-run later.
if command -v apm >/dev/null 2>&1 && [ -f "${REPO_ROOT}/dot_apm/apm.yml" ]; then
  mkdir -p "${HOME}/.apm"
  cp -f "${REPO_ROOT}/dot_apm/apm.yml" "${HOME}/.apm/apm.yml"
  if ( cd "${HOME}/.apm" && apm install -g ); then
    echo "==> apm install -g complete"
  else
    echo "WARNING: 'apm install -g' failed (network/registry?); core tooling is still usable, re-run later." >&2
  fi
fi

echo "==> Ensure ~/.local/bin is on PATH for future shells"
if ! grep -qs 'HOME/.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
  printf '\n# Added by dotfiles cloud-agent install\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "${HOME}/.bashrc"
fi

echo "==> install.sh complete"
