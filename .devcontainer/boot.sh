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
  ./.devcontainer/install-ansible.sh
fi

echo -e "👋 Welcome to the MaMpf DevContainer.
- To get started, use the command 'Run Task' in VSCode.
  First, select 'Seed MaMpf database', followed by 'Start MaMpf app'.
  For the latter, you can also use the shortcut 'Ctrl+Shift+B'.
- This devcontainer is the preferred Ansible control machine for infra work.
- For infra work here, run 'cd /workspaces/mampf-infra && . .venv/bin/activate'.
- If you use a WSL-hosted YubiKey for infra secrets, start 'sops keyservice'
  in WSL before reopening or rebuilding the devcontainer.
- See '/workspaces/mampf-infra/README.md' for the devcontainer and manual
  Ansible setup plus the SSH quickstart.
- Do NOT use any 'just docker' commands in a DevContainer."
