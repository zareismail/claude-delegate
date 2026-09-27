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
when asked. Your own context re-reads, not the implementing, are what cost money here.

- **Keep:** design · debugging an unknown cause · security, auth, payments · *deciding* a
  public API contract or what the product says to a user · the review. Once that is
  decided, carrying it into files is not yours.
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
  kept task costs a stretch of this session at this session's price.
- **You need not specify the how.** Give the goal, the constraints, the traps you foresee
  and how you will know it worked; \`delegate plan\` investigates and returns a plan to
  correct. Needing to read the code first is a reason to hand it down, not to keep it. Only
  the acceptance is never vague: if you cannot name what settles it, you are not ready.

Do not sit idle while it works, and do not queue more than you can review. Load the
\`delegate\` skill for the commands, brief format and review discipline before handing off.
EOF
