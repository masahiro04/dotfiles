#!/bin/zsh
# set tmux panes for ide

tmux split-window -v
tmux split-window -h
tmux resize-pane -D 10
tmux select-pane -t 1
