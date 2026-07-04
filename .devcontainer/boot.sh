#!/bin/bash
set -e

OR_TOOLS_URL="https://github.com/MaMpf-HD/build-artifacts/releases/download/or-tools-9.15-trixie/or-tools-9.15-trixie-amd64.tar.gz"
OR_TOOLS_SHA256="067e96ba57bbca8bf8e56c9b85010e223d49696cb5fe1a56ef94f5bd3647c0cf"

echo "🚀 Fix bundle cache ownership"
sudo mkdir -p /usr/local/bundle
sudo chown -R "$(id -u):$(id -g)" /usr/local/bundle

echo "🚀 Configure Git for Bundler git caches"
sudo git config --system safe.bareRepository all

echo "🚀 Install OR-Tools for Bundler on Debian 13"
if [ ! -d /opt/or-tools/lib ]; then
  wget -O /tmp/or-tools.tar.gz "$OR_TOOLS_URL"
  echo "$OR_TOOLS_SHA256  /tmp/or-tools.tar.gz" | sha256sum -c -
  sudo mkdir -p /opt/or-tools
  sudo tar xzf /tmp/or-tools.tar.gz -C /opt/or-tools
  rm -f /tmp/or-tools.tar.gz
fi

echo "🚀 Configure Bundler for OR-Tools"
bundle config set --global build.or-tools --with-or-tools-dir=/opt/or-tools

echo "🚀 Install Just"
./bin/just-install install

echo "🚀 Install zsh"
./.devcontainer/zsh/install-zsh.sh

echo "🚀 Install MdBook"
./.devcontainer/install-mdbook.sh

# Only when mampf-infra is actually cloned (its requirements.txt is present), not
# when it's the empty placeholder initializeCommand creates so the bind mount
# doesn't fail for app-only contributors.
if [ -f /workspaces/mampf-infra/requirements.txt ]; then
  echo "🚀 Install sops and age for mampf-infra"
  sudo apt-get update && sudo apt-get install -y age
  SOPS_VERSION="v3.13.1"
  sops_base="https://github.com/getsops/sops/releases/download/${SOPS_VERSION}"
  sops_artifact="sops-${SOPS_VERSION}.linux.amd64"
  sops_tmp="$(mktemp -d)"
  wget -O "${sops_tmp}/${sops_artifact}" "${sops_base}/${sops_artifact}"
  wget -O "${sops_tmp}/checksums.txt" "${sops_base}/sops-${SOPS_VERSION}.checksums.txt"
  # Verify the binary against sops' published checksums before installing it.
  grep "${sops_artifact}$" "${sops_tmp}/checksums.txt" > "${sops_tmp}/sops.sha256"
  ( cd "${sops_tmp}" && sha256sum -c sops.sha256 )
  chmod +x "${sops_tmp}/${sops_artifact}"
  sudo mv "${sops_tmp}/${sops_artifact}" /usr/local/bin/sops
  rm -rf "${sops_tmp}"

  echo "🚀 Set up Ansible for mampf-infra"
  ./.devcontainer/install-ansible.sh
fi

echo -e "👋 Welcome to the MaMpf DevContainer.
- To get started, use the command 'Run Task' in VSCode.
  First, select 'Seed MaMpf database', followed by 'Start MaMpf app'.
  For the latter, you can also use the shortcut 'Ctrl+Shift+B'.
- This devcontainer is the preferred Ansible control machine for infra work.
- For infra work here, run 'cd /workspaces/mampf-infra && . .venv/bin/activate'.
- See '/workspaces/mampf-infra/README.md' for the devcontainer and manual
  Ansible setup plus the SSH quickstart.
- Do NOT use any 'just docker' commands in a DevContainer."
