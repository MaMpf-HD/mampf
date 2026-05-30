#!/bin/bash
set -e

echo "🚀 Install Just"
./bin/just-install install

echo "🚀 Install zsh"
./.devcontainer/zsh/install-zsh.sh

echo "🚀 Install MdBook"
./.devcontainer/install-mdbook.sh

if [ -d /workspaces/mampf-infra ]; then
  echo "🚀 Set up Ansible for mampf-infra"
  if ! python3 -m venv --help >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y python3-venv
  fi
  python3 -m venv /workspaces/mampf-infra/.venv
  . /workspaces/mampf-infra/.venv/bin/activate
  pip install --upgrade pip
  pip install ansible
  ansible-galaxy collection install \
    -r /workspaces/mampf-infra/collections/requirements.yml \
    -p /workspaces/mampf-infra/collections
fi

echo -e "👋 Welcome to the MaMpf DevContainer.
- To get started, use the command 'Run Task' in VSCode.
  First, select 'Seed MaMpf database', followed by 'Start MaMpf app'.
  For the latter, you can also use the shortcut 'Ctrl+Shift+B'.
- For infra work, run 'cd /workspaces/mampf-infra && . .venv/bin/activate'.
- See '/workspaces/mampf-infra/README.md' for the Ansible/SSH quickstart.
- Do NOT use any 'just docker' commands in a DevContainer."
