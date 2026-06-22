#!/bin/bash
set -e

echo "🚀 Fix bundle cache ownership"
sudo mkdir -p /usr/local/bundle
sudo chown -R "$(id -u):$(id -g)" /usr/local/bundle

echo "🚀 Configure Git for Bundler git caches"
sudo git config --system safe.bareRepository all

echo "🚀 Install OR-Tools for Bundler on Debian 13"
if [ ! -d /opt/or-tools/lib ]; then
  wget -O /tmp/or-tools.tar.gz https://github.com/MaMpf-HD/build-artifacts/releases/download/or-tools-9.15-trixie/or-tools-9.15-trixie-amd64.tar.gz
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

if [ -d /workspaces/mampf-infra ]; then
  echo "🚀 Install sops and age for mampf-infra"
  sudo apt-get update && sudo apt-get install -y age
  wget -O /tmp/sops https://github.com/getsops/sops/releases/download/v3.13.1/sops-v3.13.1.linux.amd64
  chmod +x /tmp/sops
  sudo mv /tmp/sops /usr/local/bin/sops

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
