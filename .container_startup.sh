#!/bin/zsh
yes | mackup restore 
exec /usr/local/bin/tmuxinator start default
