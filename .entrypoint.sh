#!/bin/zsh
yes | mackup restore 
exec /usr/local/bin/tmuxinator start go-ide
