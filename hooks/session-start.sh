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
implementer, or both with the split named — and say why in one line. Do this for every
task, not only when the user asks for delegation. The point is to move token burn off
this session: your own context re-reads cost far more than the implementation does.

- **Keep:** design · debugging an unknown cause · security, auth, payments · public API
  contracts · user-facing wording · the review itself.
- **Hand down:** repetitive edits across files · applying a pattern already in the repo ·
  mechanical migrations and renames · tests against behaviour you have already specified ·
  CRUD on a settled schema · scaffolding.
- **Keep it if it is small.** Under ~40 lines in one file, or anything whose exact lines
  you can already name, the brief costs more than the edit.
- **Split rather than choose.** Most real tasks are a hard core plus mechanical bulk.
  Keep the core, commit it, hand the bulk down against that commit.
- **Re-decide at every boundary**, not once per task — especially once the design settles.

Do not sit idle while the implementer works, and do not queue so much that you cannot
review it. Load the \`delegate\` skill for the commands, the brief format and the review
discipline before the first handoff.
EOF
