# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set a colorful prompt
PS1='\[\e[1;32m\]\u@\h:\w\[\e[0m\]\$ '

# Enable bash completion if available
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
elif [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

# History settings
HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# Add custom paths
export PATH="$HOME/bin:$PATH"

# Enable aliases to be sudo-able
alias sudo='sudo '

# Set default editor
export EDITOR=vim

# Load user-specific bashrc additions
if [ -f ~/.bashrc_custom ]; then
    . ~/.bashrc_custom
fi