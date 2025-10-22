#!/bin/bash
set -e

# zsh
sudo apt update \
    && DEBIAN_FRONTEND=noninteractive sudo apt install -y \
       -o Dpkg::Options::="--force-confnew" zsh

# zsh history (~/commandhistory/ is preserved as a volume in docker-compose)
# Persist bash history
# adapted from https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
mkdir -p "$HOME/commandhistory"
touch "$HOME/commandhistory/.zsh_history"
chown -R "$(id -un):$(id -gn)" "$HOME/commandhistory" || true

# initial zsh config
cp .devcontainer/zsh/.zshrc ~/.zshrc

# Powerline fonts
# https://github.com/powerline/fonts?tab=readme-ov-file#quick-installation
git clone --depth=1 https://github.com/powerline/fonts.git
cd fonts
./install.sh
cd .. && rm -rf fonts

# Powerlevel10k
# https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#manual
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
cp .devcontainer/zsh/.p10k.zsh ~/.p10k.zsh
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc

# zsh autosuggestion
# https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#manual-git-clone
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc

# zsh syntax highlighting
# https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md#in-your-zshrc
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
echo "source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc

# zsh history substring search (install AFTER syntax highlighting)
# https://github.com/zsh-users/zsh-history-substring-search
git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git ~/.zsh/zsh-history-substring-search
echo "source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh" >> ~/.zshrc
