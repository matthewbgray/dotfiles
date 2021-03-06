# .zshrc configuration file

# Copyright (c) 2020 Matthew B. Gray
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Locale
export LANG=en_US
export LC_CTYPE=$LANG.UTF-8

# CD from anywhere
cdpath=(~ ~/Desktop ~/code/centrapay ~/code ~/code/go/src ~/.config/nvim)

setopt CORRECT MULTIOS NO_HUP NO_CHECK_JOBS EXTENDED_GLOB

# History
export HISTSIZE=1000000
export HISTFILE=~/.zsh_history
export SAVEHIST=$HISTSIZE

# man zshoptions
setopt hist_ignore_all_dups # when running a command again, removes previous refs to it
setopt hist_save_no_dups    # kill duplicates on save
setopt hist_ignore_space    # prefixed with space doesn't store command
setopt hist_no_store        # don't store the command history in history
setopt hist_verify          # when using history expansion, reload history
setopt hist_reduce_blanks   # blanks from each command line added to the history list

setopt extended_history     # save time stamp and runtime information
setopt inc_append_history   # write after exec rather than waiting till shell exit
setopt no_hist_beep         # no terminal bell please
# setopt share_history      # all open shells see history

setopt interactivecomments # Don't execute comments in interactive shell

## Completion
setopt NO_BEEP AUTO_LIST AUTO_MENU
autoload -U compinit
compinit

# Bash-like navigation, http://stackoverflow.com/questions/10847255
autoload -U select-word-style
select-word-style bash

##############################################################################
# Misc tricks from
# http://chneukirchen.org/blog/archive/2013/03/10-fresh-zsh-tricks-you-may-not-know.html
autoload -Uz copy-earlier-word
zle -N copy-earlier-word
bindkey "^[m" copy-earlier-word

function _recover_line_or_else() {
  if [[ -z $BUFFER && $CONTEXT = start && $zsh_eval_context = shfunc
      && -n $ZLE_LINE_ABORTED
      && $ZLE_LINE_ABORTED != $history[$((HISTCMD-1))] ]]; then
    LBUFFER+=$ZLE_LINE_ABORTED
    unset ZLE_LINE_ABORTED
  else
    zle .$WIDGET
  fi
}
zle -N up-line-or-history _recover_line_or_else
function _zle_line_finish() {
  ZLE_LINE_ABORTED=$BUFFER
}
zle -N zle-line-finish _zle_line_finish

# End tricks
##############################################################################

## Prompt
cur_git_branch() {
  # TODO maybe something like... git rev-parse --abbrev-ref HEAD
  git branch --no-color 2>/dev/null|awk '/^\* ([^ ]*)/ {b=$2} END {if (b) {print "[" b "]"}}'
}

setopt PROMPT_SUBST

case $TERM in
  xterm*|rxvt*|screen|Apple_Terminal)
    # Remotes look different
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
      PROMPT=$(echo "%{\e]0;%n@%m: %~\a\e[%(?.32.31)m%}β %{\e[m%}")
    else
      PROMPT=$(echo "%{\e]0;%n@%m: %~\a\e[%(?.32.31)m%}λ %{\e[m%}")
    fi

    # Echo current process name in the xterm title bar
    preexec () {
      print -Pn "\e]0;$1\a"
    }
    ;;
  *)
    PROMPT="[%n@%m] %# "
    ;;
esac

RPROMPT=$(echo '$(cur_git_branch) %{\e[32m%}%3~ %{\e[m%}%U%T%u')

# Echo current process name in the xterm title bar
preexec () {
  print -Pn "\e]0;$1\a"
}

export LS_COLORS="exfxcxdxbxegedabagacad"
ZLS_COLORS=$LS_COLORS

# Aliases
alias ls='ls -G'                            # technicolor list
alias cdg='cd $(git rev-parse --show-cdup)' # cd to root of repo

export LESS='-R'

export GREP_COLOR='1;33'


# Checkout github pull requests locally
# https://gist.github.com/piscisaureus/3342247
function pullify() {
  git config --add remote.origin.fetch '+refs/pull/*/head:refs/remotes/origin/pr/*'
}

function randommac() {
  ruby -e 'puts ("%02x"%((rand 64)*4|2))+(0..4).inject(""){|s,x|s+":%02x"%(rand 256)}'
}

# Default working directories per-box
alias pin="pwd > ~/.pindir"                   # pin cwd as pin dir
alias cdd='cd $(cat ~/.pindir 2&> /dev/null)' # cdd nav to pin dir
if [[ $(pwd) == $HOME ]]; then                # open pin dir on term open
  cdd
fi

# Conditionally load files
[ -e ~/.config/local/env ] && source ~/.config/local/env
[ -e ~/.zshrc.local ]      && source ~/.zshrc.local
[ -f ~/.fzf.zsh ]          && source ~/.fzf.zsh

function reload() {
  source ~/.zshrc && stty sane
}

# Personal programs
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/code/go/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin/:$PATH"

export GOPATH="$HOME/code/go"
export GO111MODULE="on"

# Make ^Z toggle between ^Z and fg
# https://github.com/Julian/dotfiles/blob/master/.config/zsh/keybindings.zsh
function ctrlz() {
  if [[ $#BUFFER == 0 ]]; then
    fg >/dev/null 2>&1 && zle redisplay
  else
    zle push-input
  fi
}
zle -N ctrlz
bindkey '^Z' ctrlz

# Solarized cucumber workaround
export CUCUMBER_COLORS=comment=cyan

# Vim mode, god help me
# https://dougblack.io/words/zsh-vi-mode.html
bindkey -v
export KEYTIMEOUT=1
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word

if which fzf-history-widget > /dev/null; then
  bindkey '^r' fzf-history-widget
else
  bindkey '^r' history-incremental-search-backward
fi

 # zle -N zle-line-init
 # zle -N zle-keymap-select
export KEYTIMEOUT=1

# Homebrew flub
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/*/bin:$PATH"

# Setting default editor
if which nvim > /dev/null; then
  echo "nvim..."
  export EDITOR=nvim
  alias vim=nvim
  alias vi=nvim
elif which vim > /dev/null; then
  echo "vim..."
  export EDITOR=vim
else
  export EDITOR=vi
fi

if which nvm > /dev/null; then
  echo "node version manager..."
  export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
fi

function update() {
  cd ~/dotfiles
  make updates
}

function first() {
  git init
  git add .
  git commit -m "First!"
}

# Cludges follow
if [[ `uname` == "Darwin" ]]; then # OSX
  echo "OSX cludges..."
  # Fix GPG agent detection
  # see https://github.com/pstadler/keybase-gpg-github/issues/11
  GPG_TTY=$(tty)
  export GPG_TTY

  # Delete key fixup
  bindkey "^[[3~"  delete-char
  bindkey "^[3;5~" delete-char

  # Local IP as env variable
  export LOCAL_IP=$(ipconfig getifaddr en0)
else # Linux
  # webcam hack, this should really go into the kernel or something
  # checkout https://github.com/patjak/facetimehd-firmware
  # ubuntu target based on https://github.com/patjak/bcwc_pcie/wiki/Get-Started
  alias fixwebcam="cd /home/mbgray/code/facetimehd_camera_drivers && make ubuntu"

  # Turn off capslock
  setxkbmap -option caps:escape

  # Receiver for HP ZCentral Remote Boost Software
  export PATH="$PATH:/opt/hpremote/rgreceiver"
fi

function backup() {
  restic backup . -r sftp:matthew.nz:restic-backup
}

# hose things that match string
# e.g. fuck ruby
alias fuck='pkill -if'

# .envrc files contain secrets, if direnv exists export them on directory traversal
if which direnv > /dev/null; then
  echo "direnv..."
  eval "$(direnv hook zsh)"
fi

# If rbenv exists, init shims autocompletion
if which rbenv > /dev/null; then
  echo "rbenv..."
  eval "$(rbenv init -)";
  export PATH="~/.rbenv/bin:$PATH"
fi

# if which asdf > /dev/null; then
#   echo "asdf..."
#   $(brew --prefix asdf)/asdf.sh
# fi

# If chruby exists, init shims and hook cd
if [ -f /usr/local/share/chruby/chruby.sh ]; then
  echo "chruby..."
  source /usr/local/share/chruby/chruby.sh
  source /usr/local/share/chruby/auto.sh
fi

# If pyenv exists, init shims autocompletion
if which pyenv > /dev/null; then
  echo "pyenv..."
  eval "$(pyenv init -)"
  pyenv rehash
fi

# Advice from
# brew cask install google-cloud-sdk
if which gcloud > /dev/null; then
  echo "gcloud..."
  source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc'
  source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'
fi

# Test && Commit || Revert, pioneered by Kent Beck
# https://youtu.be/FFzHOyFeovE
function tcr() {
  which entr > /dev/null || {
    echo "brew install entr"
    return 1
  }
  projectRoot=$(git rev-parse --show-toplevel) # for monorepo
  commitedFiles=$(git diff origin/master... --name-only)
  changedFiles=$(git status --porcelain | awk '{print $2}')
  echo "$projectRoot/$commitedFiles" "$projectRoot/$changedFiles" | xargs ls | entr -c sh -c "echo && $* && git add . || git checkout ."
}

# Like tcr, but without the git integration
function t() {
  which entr > /dev/null || {
    echo "brew install entr"
    return 1
  }
  projectRoot=$(git rev-parse --show-toplevel) # for monorepo
  commitedFiles=$(git diff origin/master... --name-only)
  changedFiles=$(git status --porcelain | awk '{print $2}')
  echo "$projectRoot/$commitedFiles" "$projectRoot/$changedFiles" | xargs ls | entr -c sh -c "echo && $*"
}

# https://coderwall.com/p/s-2_nw/change-iterm2-color-profile-from-the-cli
it2prof() { echo -e "\033]50;SetProfile=$1\a" }

# Set and remember iterm colours
# [ -e ~/.config/iterm_theme ] && echo -e "\033]50;SetProfile=$(cat ~/.config/iterm_theme)\a"
alias dark='echo "dark mode..." && echo dark > ~/.config/iterm_theme && echo -e "\033]50;SetProfile=dark\a"'
alias light='echo "light mode..." && echo light > ~/.config/iterm_theme && echo -e "\033]50;SetProfile=light\a"'
appearance=$(defaults read -g AppleInterfaceStyle 2> /dev/null || echo "Light")
if [ $appearance = 'Dark' ]; then
  dark
else
  light
fi
