#!/bin/sh
# Alt+hjkl: forward into vim/tmux, otherwise focus the Herdr pane.
# Usage: navigate.sh <left|down|up|right> <alt+h|alt+j|alt+k|alt+l>
set -eu

direction=$1
key=$2
pane=${HERDR_ACTIVE_PANE_ID:?}
bin=${HERDR_BIN_PATH:-herdr}

info=$("$bin" pane process-info --pane "$pane")

# Same process match as tmux.conf is_vim, plus tmux itself so a nested
# tmux keeps its own M-hjkl bindings.
if printf '%s\n' "$info" | jq -e '
  [.result.process_info.foreground_processes[]?
    | (.argv0 // ""), (.name // "")]
  | map(split("/") | last)
  | any(test("^(g?(view|l?n?vim?x?|fzf)|tmux)(diff)?$"))
' >/dev/null
then
  "$bin" pane send-keys "$pane" "$key"
else
  "$bin" pane focus --direction "$direction" --pane "$pane"
fi
