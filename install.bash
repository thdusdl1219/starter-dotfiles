#! /bin/bash

# Author: Brian Cain
# Installs your dotfiles

# Function to determine package manager
function determine_package_manager() {
  which yum > /dev/null && {
    echo "yum"
    export OSPACKMAN="yum"
    return;
  }
  which apt-get > /dev/null && {
    echo "apt-get"
    export OSPACKMAN="aptget"
    return;
  }
  which brew > /dev/null && {
    echo "homebrew"
    export OSPACKMAN="homebrew"
    return;
  }
}

# function setup_bash() {
#   # TODO: Bash customization
# }

function setup_zsh() {
  echo 'Adding oh-my-zsh to dotfiles...'
  OMZDIR=~/.dotfiles/oh-my-zsh

  if [ -d "$OMZDIR" ] ; then
    echo 'Updating oh-my-zsh to latest version'
    cd ~/.dotfiles/oh-my-zsh
    git pull origin master
    cd -
  else
    echo 'Adding oh-my-zsh to dotfiles...'
    git clone https://www.github.com/robbyrussell/oh-my-zsh.git
  fi
}

function setup_gdb() {
  echo 'Adding pwndbg to dotfiles...'
  DBGDIR=~/.dotfiles/pwndbg

  if [ -d "$DBGDIR" ] ; then
    echo 'Already exist pwndbg'
  else
    echo 'Adding pwndbg to dotfiles...'
    git clone https://github.com/pwndbg/pwndbg.git
    cd $DBGDIR
    ./setup.sh
    cd -
  fi
}

function determine_shell() {
  echo 'Please pick your favorite shell:'
  echo '(1) Bash'
  echo '(2) Zsh'
  read -p 'Enter a number: ' SHELL_CHOICE
  if [[ $SHELL_CHOICE == '1' ]] ; then
    export LOGIN_SHELL="bash"
  elif [[ $SHELL_CHOICE == '2' ]] ; then
    export LOGIN_SHELL="zsh"
  else
    echo 'Could not determine choice.'
    exit 1
  fi
}


function setup_editor() {
  echo 'setup vim...'
  EDIDIR=~/.dotfiles/vim

  if [ -d "$EDIDIR" ] ; then
    echo 'Updating vimrc to latest version'
    cd ~/.dotfiles/vim
    git pull origin master
    cd -
  else
    echo 'Adding vimrc to vim'
    git clone https://github.com/posquit0/vimrc $EDIDIR
  fi
}

function setup_tmux() {
  echo 'setup tmux...'
  TMUXDIR=~/.dotfiles/tmux

  if [ -d "$TMUXDIR" ] ; then
    echo 'Updating tmuxdir to latest version'
    cd $TMUXDIR
    git pull origin master
    cd -
  else
    echo 'Adding tmuxdir to tmux'
    git clone --recursive https://github.com/posquit0/tmux-conf.git $TMUXDIR
  fi
}

function setup_vim() {
  echo "Setting up vim...ignore any vim errors post install"
  vim +PlugInstall +qall now
}

function setup_git() {
  echo 'Setting up git config...'
  read -p 'Enter Github username: ' GIT_USER
  git config --global user.name "$GIT_USER"
  read -p 'Enter email: ' GIT_EMAIL
  git config --global user.email $GIT_EMAIL
  git config --global core.editor vim
  git config --global color.ui true
  git config --global color.diff auto
  git config --global color.status auto
  git config --global color.branch auto
  git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
}

# Adds a symbolic link to files in ~/.dotfiles
# to your home directory.
function symlink_files() {
  ignoredfiles=(LICENSE README.md install.bash update-zsh.sh pwndbg)

  for f in $(ls -d *); do
    if [[ ${ignoredfiles[@]} =~ $f ]]; then
      echo "Skipping $f ..."
    elif [[ $f =~ 'bashrc' ]]; then
      if [[ $LOGIN_SHELL == 'bash' ]] ; then
        link_file $f
      fi
    elif [[ $f =~ 'bash_logout' ]]; then
      if [[ $LOGIN_SHELL == 'bash' ]] ; then
        link_file $f
      fi
    elif [[ $f =~ 'zshrc' || $f =~ 'oh-my-zsh' ]]; then
      if [[ $LOGIN_SHELL == 'zsh' ]] ; then
        link_file $f
      fi
    elif [[ $f =~ 'oh-my-zsh' ]]; then
      if [[ $LOGIN_SHELL == 'zsh' ]] ; then
        link_file $f
      fi
    elif [[ $f =~ 'vim' ]] ; then
      link_file $f
      if ! $(ln -Ts "$PWD/vim/vimrc" "$HOME/.vimrc"); then
        echo "Replace file '~/.vimrc'?"
        read -p "[Y/n]?: " Q_REPLACE_FILE
        if [[ $Q_REPLACE_FILE != 'n' ]]; then
          echo "replacing ~/.vimrc"
          ln -sf "$PWD/vim/vimrc" "$HOME/.vimrc"
        fi
      fi
    elif [[ $f =~ 'tmux' ]] ; then
      link_file $f
      if ! $(ln -Ts "$PWD/tmux/tmux.conf" "$HOME/.tmux.conf"); then
        echo "Replace file '~/.tmux.conf'?"
        read -p "[Y/n]?: " Q_REPLACE_FILE
        if [[ $Q_REPLACE_FILE != 'n' ]]; then
          echo 'replacing ~/.tmux.conf'
          ln -sf "$PWD/tmux/tmux.conf" "$HOME/.tmux.conf"
        fi
      fi
    else
        link_file $f
    fi
  done
}

# symlink a file
# arguments: filename
function link_file(){
  echo "linking ~/.$1"
  if ! $(ln -sT "$PWD/$1" "$HOME/.$1");  then
    echo "Replace file '~/.$1'?"
    read -p "[Y/n]?: " Q_REPLACE_FILE
    if [[ $Q_REPLACE_FILE != 'n' ]]; then
      replace_file $1
    fi
  fi
}

# replace file
# arguments: filename
function replace_file() {
  echo "replacing ~/.$1"
  ln -sfT "$PWD/$1" "$HOME/.$1"
}

set -e
(
  determine_package_manager
  # general package array
  declare -a packages=('vim' 'git' 'tree' 'htop' 'wget' 'curl')

  determine_shell
  if [[ $LOGIN_SHELL == 'bash' ]] ; then
    packages=(${packages[@]} 'bash')
  elif [[ $LOGIN_SHELL == 'zsh' ]] ; then
    packages=(${packages[@]} 'zsh')
  fi

  if [[ $OSPACKMAN == "homebrew" ]]; then
    echo "You are running homebrew."
    echo "Using Homebrew to install packages..."
    brew update
    declare -a macpackages=('findutils' 'macvim' 'the_silver_searcher')
    brew install "${packages[@]}" "${macpackages[@]}"
    brew cleanup
  elif [[ "$OSPACKMAN" == "yum" ]]; then
    echo "You are running yum."
    echo "Using yum to install packages...."
    sudo yum update
    sudo yum install "${packages[@]}"
  elif [[ "$OSPACKMAN" == "aptget" ]]; then
    echo "You are running apt-get"
    echo "Using apt-get to install packages...."
    sudo apt-get update
    sudo apt-get install "${packages[@]}"
  else
    echo "Could not determine OS. Exiting..."
    exit 1
  fi

  if [[ $LOGIN_SHELL == 'bash' ]] ; then
    # setup_bash
    echo 'No extra bash configs yet...'
  elif [[ $LOGIN_SHELL == 'zsh' ]] ; then
    setup_zsh
  fi

  #setup_git
  setup_editor
  setup_gdb
  setup_tmux
  symlink_files
  setup_vim
  ./tmux/plugins/tpm/scripts/install_plugins.sh


  if [[ $LOGIN_SHELL == 'bash' ]] ; then
    echo "Operating System setup complete."
    echo "Reloading session"

    source ~/.bashrc
  elif [[ $LOGIN_SHELL == 'zsh' ]] ; then
    echo "Changing shells to ZSH"
    chsh -s /bin/zsh

    echo "Operating System setup complete."
    echo "Reloading session"
    exec zsh
  fi

)
