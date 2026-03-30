#!/usr/bin/env bash
# 用法: pane_label.sh <pane_pid>
PID=$1
[ -z "$PID" ] && exit 1

# 获取 pane shell 的前台进程组 ID（TPGID）
TPGID=$(ps -p "$PID" -o tpgid= 2>/dev/null | tr -d ' ')

# 若 TPGID == PID 或无效，说明 shell 本身是前台（空闲状态）
if [ -z "$TPGID" ] || [ "$TPGID" = "$PID" ] || [ "$TPGID" = "-1" ]; then
    CMD=$(ps -p "$PID" -o command= 2>/dev/null)
else
    # 取前台进程组中 PID 最小的进程（主进程）
    CMD=$(ps -g "$TPGID" -o pid=,command= 2>/dev/null | sort -n | head -1 | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
    [ -z "$CMD" ] && CMD=$(ps -p "$PID" -o command= 2>/dev/null)
fi

case "$CMD" in
  *claude*)  echo "claude"  ;;
  *codex*)   echo "codex"   ;;
  *gemini*)  echo "gemini"  ;;
  *nvim*)    echo "nvim"    ;;
  *vim*)     echo "vim"     ;;
  *python*)  echo "python"  ;;
  *node*)    echo "node"    ;;
  *)
    commandName=${CMD%% *}
    commandName=${commandName##*/}
    commandName=${commandName#-}
    echo "$commandName"
    ;;
esac
