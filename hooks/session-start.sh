#!/usr/bin/env bash
# The routing decision gets made in the first seconds of a task, before any skill
# description has matched anything — so a skill cannot be what carries it. This
# runs on every session and puts the rule where the decision actually happens.
# Keep it short: it is paid for once per session, in every project.
set -u

if ! command -v delegate >/dev/null 2>&1; then
  echo "claude-delegate is installed but its \`delegate\` command is not on PATH."
  echo "Run /delegate-setup once; until then, do not plan around delegating."
  exit 0
fi

# A session pins its plugin version when it starts, so a long-lived one goes on
# using the rules it booted with after the package has moved on. That is invisible
# from inside the session, which makes it worth one cheap check: an old session
# quietly following superseded routing rules is the exact failure this package
# keeps being fixed for. Silent unless the versions actually disagree.
skew=""
if command -v jq >/dev/null 2>&1 && [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  mine=$(jq -r '.version // ""' "$CLAUDE_PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null)
  theirs=$(jq -r '.plugins["claude-delegate@claude-delegate"][0].version // ""' \
           "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null)
  if [ -n "$mine" ] && [ -n "$theirs" ] && [ "$mine" != "$theirs" ]; then
    skew="

**This session is running claude-delegate $mine, but $theirs is installed.** It pinned the
older copy at startup and cannot pick up the new one. Its routing rules may have been
superseded. Finish what is in flight, then start a fresh session for the current rules."
  fi
  # The \`delegate\` binary is symlinked into a versioned directory, so an update can
  # leave the command behind while the skill moves forward.
  link=$(readlink -f "$(command -v delegate 2>/dev/null)" 2>/dev/null || true)
  case "$link" in
    */claude-delegate/[0-9]*)
      lv=${link#*/claude-delegate/claude-delegate/}; lv=${lv%%/*}
      [ -n "$lv" ] && [ "$lv" != "$theirs" ] && skew="$skew

**The \`delegate\` command on PATH is from $lv while $theirs is installed.** Run
/delegate-setup to repoint it." ;;
  esac
fi

# Counted from the filesystem rather than \`delegate ls\`, which shells out to git
# once per worktree. Session start is not the place to pay for that.
root="${DELEGATE_HOME:-$HOME/.delegate}"
busy=$(find "$root/wt" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l)

cat <<EOF
## Routing implementation work (claude-delegate)

A cheaper implementer (DeepSeek) is available through \`delegate\`, running in an
isolated git worktree. It currently holds $busy task(s); \`delegate ls\` is the live board.

**Before you start implementing anything, decide out loud who does it** — you, the
implementer, or both with the split named — and say why in one line. Every task, not only
when asked. Your own context re-reads, not the implementing, are what cost money.

- **Keep:** design · debugging an unknown cause · security, auth, payments · *deciding* an
  API contract or what the product says to a user · the review. Carrying a settled decision
  into files is not yours.
- **Hand down:** repetitive edits across files · applying a pattern already in the repo ·
  mechanical migrations and renames · tests against behaviour you specified · CRUD on a
  settled schema · scaffolding.
- **Keep it only if genuinely small:** under ~25 lines in one file. Knowing the exact lines
  argues for keeping it, unless that same edit repeats across files.
- **Split rather than choose.** Most tasks are a hard core plus mechanical bulk: keep the
  core, commit it, hand the bulk down against that commit.
- **Re-decide at every boundary**, not once per task. Once an endpoint or access rule is
  committed, the page consuming it and its tests are a slice, not a follow-up you happen
  to be well placed for.
- **On a close call, hand it down.** A wrong handoff costs one cheap round; a needlessly
  kept task costs a stretch of this session.
- **You need not specify the how.** Give the goal, the constraints, the traps you foresee
  and how you will know it worked; \`delegate plan\` investigates and returns a plan to
  correct. Needing to read the code first is a reason to hand it down, not to keep it. Only
  the acceptance is never vague — name what settles it, or you are not ready.

Do not sit idle while it works, and do not queue more than you can review. Load the
\`delegate\` skill for the commands, brief format and review discipline before handing off.

**Do not copy any of this into memory.** The package is the versioned source of truth and
gets edited when a rule is wrong; a copy in memory cannot be, so it goes stale and then
overrides the live rule. Save only what the package cannot know: the user's decisions.$skew
EOF
