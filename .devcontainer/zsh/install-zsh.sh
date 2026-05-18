#!/bin/bash
set -e

# zsh
if ! command -v zsh &> /dev/null; then
    sudo apt update \
        && DEBIAN_FRONTEND=noninteractive sudo apt install -y \
           -o Dpkg::Options::="--force-confnew" zsh
fi

# zsh history
# adapted from https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
mkdir -p "/workspaces/commandhistory"
sudo touch "/workspaces/commandhistory/.zsh_history"
sudo chown -R "$(id -un):$(id -gn)" "/workspaces/commandhistory"

# initial zsh config
cp .devcontainer/zsh/.zshrc ~/.zshrc

# Powerline fonts
# https://github.com/powerline/fonts?tab=readme-ov-file#quick-installation
if [ ! -d ~/.local/share/fonts ] || [ -z "$(find ~/.local/share/fonts -name '*Powerline*' 2>/dev/null)" ]; then
    git clone --depth=1 https://github.com/powerline/fonts.git
    cd fonts
    ./install.sh
    cd .. && rm -rf fonts
fi

# Powerlevel10k
# https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#manual
if [ ! -d ~/powerlevel10k ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
fi
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
cp .devcontainer/zsh/.p10k.zsh ~/.p10k.zsh
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc

# zsh autosuggestion
# https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#manual-git-clone
if [ ! -d ~/.zsh/zsh-autosuggestions ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
fi
echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc

# zsh syntax highlighting
# https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md#in-your-zshrc
if [ ! -d ~/.zsh/zsh-syntax-highlighting ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
fi
echo "source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc

# zsh history substring search (install AFTER syntax highlighting)
# https://github.com/zsh-users/zsh-history-substring-search
if [ ! -d ~/.zsh/zsh-history-substring-search ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git ~/.zsh/zsh-history-substring-search
fi
echo "source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh" >> ~/.zshrc
