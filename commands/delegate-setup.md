---
description: Put the `delegate` command on PATH and check its prerequisites.
---

Set up claude-delegate for this machine. Do all of this with Bash, then report a
short table of what passed and what did not.

1. Symlink the plugin's binary onto PATH:
   `mkdir -p ~/.local/bin && ln -sf "${CLAUDE_PLUGIN_ROOT}/bin/delegate" ~/.local/bin/delegate`
2. Confirm `~/.local/bin` is on PATH. If it is not, tell the user the line to add
   to their shell profile — do not edit their profile yourself.
3. Check `opencode --version` resolves. If not, point them at
   https://opencode.ai and stop; nothing else will work without it.
4. Check the configured model is listed: `timeout 60 opencode models | grep '^deepseek/'`
   (or whichever provider `DELEGATE_MODEL` names). This needs opencode 2.x. A provider with no API key
   configured is the most common setup failure — say so plainly if it fails.
5. Run `delegate ls` to confirm the command works end to end. An empty board is
   the correct result on a fresh install.

Do not create any worktrees or run a task as part of setup.
