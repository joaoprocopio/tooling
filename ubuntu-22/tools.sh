#!/bin/env sh

#
read -p "Type here your personal username: " PERSONAL_USERNAME
read -p "Type here your personal email: " PERSONAL_EMAIL

#
read -p "Type here your work username: " WORK_USERNAME
read -p "Type here your work email: " WORK_EMAIL

#
sudo apt update

#
sudo apt install --yes \
  tmux htop \
  git tree wget curl ffmpeg net-tools \
  gimp obs-studio qbittorrent vlc \
  gnome-tweaks dconf-editor gnome-shell-extensions \
  ninja-build libtool autoconf automake cmake gcc make unzip patch gettext \
  libfuse2

#
touch ~/.gitignore
touch ~/.gitconfig

#
echo "**/.vscode/**\n" | tee ~/.gitignore >/dev/null

#
echo "[user]
  name = $PERSONAL_USERNAME
  email = $PERSONAL_EMAIL
[alias]
  st = status
  lg = log --graph --decorate --abbrev-commit --all --pretty=format:'%C(auto)%h%Creset %C(cyan)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'
[init]
  defaultBranch = main
[core]
  excludesfile = /home/$USER/.gitignore
  editor = code --wait" | tee ~/.gitconfig >/dev/null

#
echo "\n# aliases
alias ll='ls -lha'
alias dk='docker'
alias dkc='docker compose'
alias vpn='openvpn3'" | tee --append ~/.zshrc >/dev/null

#
if [ -n "$WORK_EMAIL" ] && [ -n "$WORK_USERNAME" ]; then
  echo "alias clone='git clone --config user.name=\"$WORK_EMAIL\" --config user.email=\"$WORK_USERNAME\"'" | tee --append ~/.zshrc >/dev/null
fi

#
git clone -b stable --depth 1 https://github.com/neovim/neovim ~/neovim
cd ~/neovim
make CMAKE_BUILD_TYPE=Release
sudo make install
rm -rf build
sudo ln -s /usr/local/bin/nvim /usr/local/bin/vim
mkdir ~/.config/nvim
curl -o ~/.config/nvim/init.lua https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/master/init.lua

#
git clone https://github.com/gpakosz/.tmux.git ~/.tmux
ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
cp ~/.tmux/.tmux.conf.local ~/
echo "set -g mouse on" | tee --append ~/.tmux.conf.local >/dev/null
