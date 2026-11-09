# dotfiles

This is dotfiles repo for configs and useful tools

## Installation
```bash
#Install GNU stow
sudo apt install stow # for Debian, Ubuntu Linux
#or
brew install stow #for MacOS

#get to your home directory
cd ~
git clone https://github.com/tempus-devops/dotfiles.git
cd dotfiles
#done!
#to pick needed configuration do, for example:
stow tmux
```
## Tools I frequently use
* Lazygit
* Lazydocker
* macOS Terminal.app (Catppuccin Mocha + Hack Nerd Font)

## macOS Terminal (Catppuccin Mocha)
Profile lives in `macos-terminal/` (not a stow package, import it instead):
```bash
brew install --cask font-hack-nerd-font   # icons for powerlevel10k
open macos-terminal/catppuccin-mocha.terminal
# Terminal > Settings > Profiles > catppuccin-mocha > Default
```
Theme: [catppuccin/Terminal.app](https://github.com/catppuccin/Terminal.app), font set to `HackNF-Regular 13`.
