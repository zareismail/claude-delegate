#!/usr/bin/env bash
# PostToolUse. Counts what this session has written with its own hands since the
# last handoff, and says nothing at all.
#
# Why it exists: the size gate is per task, but the bill is cumulative. A stream
# of small asks each pass the gate individually and add up to hundreds of lines
# that never got routed — observed in real use over two days, where only one task
# of many went down. Judgement cannot see that pattern, because each request looks
# small at the moment it arrives. A counter can.
#
# PostToolUse stdout is not shown to the model, so this costs zero context. The
# nudge that reads the tally is a separate hook, and it is silent until the tally
# says otherwise.
set -u
command -v jq >/dev/null 2>&1 || exit 0

ROOT="${DELEGATE_HOME:-$HOME/.delegate}"
in=$(cat)
sid=$(printf '%s' "$in" | jq -r '.session_id // "none"' 2>/dev/null) || exit 0
[ "$sid" = none ] && exit 0
d="$ROOT/.drift/$sid"

tool=$(printf '%s' "$in" | jq -r '.tool_name // ""' 2>/dev/null)

# A handoff resets the clock: that is the behaviour the counter is trying to buy.
if [ "$tool" = Bash ]; then
  cmd=$(printf '%s' "$in" | jq -r '.tool_input.command // ""' 2>/dev/null)
  case "$cmd" in *"delegate new"*|*"delegate plan"*|*"delegate rework"*) rm -rf "$d" ;; esac
  exit 0
fi

case "$tool" in Write|Edit|NotebookEdit) ;; *) exit 0 ;; esac

if [ ! -d "$d" ]; then
  mkdir -p "$d" || exit 0
  # Sessions end without telling us. Sweep anything stale while we are here.
  find "$ROOT/.drift" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} + 2>/dev/null
fi

read -r path n < <(printf '%s' "$in" | jq -r '
  [ (.tool_input.file_path // .tool_input.notebook_path // "?"),
    ((.tool_input.content // .tool_input.new_string // .tool_input.new_source // "")
       | if . == "" then 0 else (split("\n") | length) end)
  ] | @tsv' 2>/dev/null | tr '\t' ' ') || exit 0
[ -n "${n:-}" ] || exit 0

printf '%s\n' "$path" >> "$d/files"
prev=$(cat "$d/lines" 2>/dev/null || echo 0)
echo $(( prev + n )) > "$d/lines"
exit 0
