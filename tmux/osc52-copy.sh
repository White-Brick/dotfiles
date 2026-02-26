#!/bin/bash
# tmux copy-pipe 调用此脚本，stdin 是选中的文本
TTY=$(tmux display-message -p '#{client_tty}')
printf "\033]52;c;%s\007" "$(base64 -w0)" > "$TTY"
