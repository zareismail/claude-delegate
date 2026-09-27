#!/usr/bin/env bash
# UserPromptSubmit. Silent until the session has written enough by hand that the
# next slice should have gone down, then says so once and resets.
#
# The SessionStart rule is stated once and decays: observed in real use, the
# routing line was given for the first task of a session and then never again
# across dozens of later asks. Re-injecting a reminder on every prompt would fix
# that by paying for it on every prompt, which is the cost this package exists to
# avoid. So it speaks only when there is something to say, and what it says is a
# measurement rather than a reminder.
set -u

ROOT="${DELEGATE_HOME:-$HOME/.delegate}"
MAXL="${DELEGATE_DRIFT_LINES:-120}"
MAXF="${DELEGATE_DRIFT_FILES:-4}"
command -v jq >/dev/null 2>&1 || exit 0

sid=$(cat | jq -r '.session_id // "none"' 2>/dev/null) || exit 0
[ "$sid" = none ] && exit 0
d="$ROOT/.drift/$sid"
[ -d "$d" ] || exit 0

lines=$(cat "$d/lines" 2>/dev/null || echo 0)
files=$(sort -u "$d/files" 2>/dev/null | wc -l)
[ "$lines" -ge "$MAXL" ] || [ "$files" -ge "$MAXF" ] || exit 0

cat <<EOF
## Drift check (claude-delegate)

Since the last handoff this session has written **$lines lines across $files files** itself.
Each of those passed the size gate on its own; together they are a slice that did not go
down. That is the failure mode this package was built to prevent, and it does not announce
itself — every individual ask looked small.

Before doing more of it: is there a slice here to hand over now? The settled part of this
work — the pages, the tests, the repetitive edits against interfaces that already exist —
is what \`delegate new\` is for. Say your routing decision in one line either way, then
carry on.
EOF
rm -rf "$d"
exit 0
