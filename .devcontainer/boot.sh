#!/bin/bash
set -e

git submodule update --init --recursive

yarn run just-install
.devcontainer/zsh/install-zsh.sh

echo -e "👋 Welcome to the MaMpf DevContainer.
- To get started, use the command 'Run Task' in VSCode.
  First, select 'Seed MaMpf database', followed by 'Start MaMpf app'.
  For the latter, you can also use the shortcut 'Ctrl+Shift+B'.
- Do NOT use any 'just docker' commands in a DevContainer."
