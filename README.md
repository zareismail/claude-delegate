# claude-delegate

Claude plans and reviews. A cheaper model implements, in an isolated git worktree.
You get a reviewable diff back — and the expensive model never spends tokens typing.

## Why

On a real five-task run, the implementer cost **$0.09** and the orchestrating Claude
session cost **$16**. 20.7M of that $16 was cache reads: the session's own context,
re-read across 173 API calls. The implementation was never the expensive part —
**the orchestrator's own tool calls are.**

So this plugin is built around one rule: keep context off the expensive model.
The cheap model reads the code, writes the plan, writes the code, runs the tests.
Claude reads a diff, a plan summary, and a fifteen-line verdict.

## Install

```
/plugin marketplace add zareismail/claude-delegate
/plugin install claude-delegate@claude-delegate
/delegate-setup
```

You need [opencode](https://opencode.ai) with a provider configured. Default is
`deepseek/deepseek-flash` at effort `low`; `DELEGATE_MODEL` and `DELEGATE_VARIANT`
override it. Reaching for a bigger model is usually a sign the brief is too vague,
or that the task is not one to delegate — see [What not to do](#what-not-to-do).

Check your opencode config too: a global `"model"` in `~/.config/opencode/opencode.json(c)`
is what a bare `opencode run` falls back to, and it is easy to leave pointed at an
expensive model.

## Routing happens without being asked

The decision of who implements a change gets made in the first seconds of a task —
before any skill description has matched anything. A skill therefore cannot be what
carries it, which is why installing this plugin also installs a `SessionStart` hook.
It prints a short routing rule into every session, along with a live count of what the
implementer is already holding, so the choice is in front of Claude at the moment the
choice is made rather than only when you remember to ask for it.

It is one small block of text per session. If you do not want it, delete
`hooks/hooks.json` from the installed plugin; nothing else depends on it.

## The loop

```
delegate plan <repo-path> <slug>    # question on stdin → the cheap model investigates,
                                    #   writes PLAN.md, writes no code
   ↓ read PLAN.md, correct it
delegate rework <slug>              # notes on stdin → implement it
   ↓
delegate review <slug>              # commit bodies + diffstat. Small on purpose
delegate check <slug>               # re-run the implementer's own VERIFY, 15 lines
   ↓
delegate drop <slug>                # the ds/<slug> branch stays in your repo
```

`delegate ls` is the board. `delegate new <repo> <slug> [base]` skips the plan round
when you already know exactly what you want; the optional `base` stacks a slice on
another task's branch, which is how one big job splits across worktrees.

Launch `plan`, `new` and `rework` in the background — the script runs opencode in the
foreground on purpose, so the harness owns the process and tells Claude when it exits.

## Design

**The worktree is the task record.** It knows its repo (it is a worktree of it), its
name (the directory), its brief (`TASK.md`) and its state (branch + git log). There is
no database and no MCP server — an MCP server's tool schemas would sit in every request
of every session, which is the cost this plugin exists to avoid.

**The implementer writes no report.** The diff is the report. Its judgement calls go in
the commit body, which is what `delegate review` prints. Nothing else crosses back.

**Bounded repair is enforced, not remembered.** `check` hashes every failed verify run.
`rework` refuses on an identical repeat — it is not making progress — or after
`DELEGATE_MAX_ROUNDS` (default 4). `DELEGATE_FORCE=1` overrides when you know better.

**Fresh worktrees are hydrated.** `node_modules` is symlinked and `.env*` copied from
the parent repo, because a cheap model does not diagnose a missing gitignored env file;
it spins.

## Environment

| Variable | Default | |
|---|---|---|
| `DELEGATE_MODEL` | `deepseek/deepseek-flash` | any `provider/model` opencode knows. Raising it defeats the point of the tool |
| `DELEGATE_VARIANT` | `low` | reasoning effort. Measured on an identical brief: low 37s/$0.0040, high 56s/$0.0047, both passing |
| `DELEGATE_MAX_ROUNDS` | `4` | runaway backstop for repair rounds |
| `DELEGATE_FORCE` | unset | bypass the repair guards |
| `DELEGATE_HOME` | `~/.delegate` | where worktrees and logs live |
| `DELEGATE_TIMEOUT` | `3600` | seconds per run |

## What not to do

Do not read `$DELEGATE_HOME/logs/*`. That log is the one thing that can blow up the
orchestrator's context, and the whole design exists to keep it out.

Do not delegate anything genuinely small. Under ~25 lines in one file, writing the brief
costs more than the change — delegating it *raises* total spend. Above that the
arithmetic stops being obvious, and on a close call the handoff is the cheaper mistake.

Do not delegate architecture, unknown-cause debugging, security, auth or payments, and do
not delegate *deciding* a public API contract or what the product says to a user. Those
are why you are paying for the expensive model. Carrying a decision you have already made
into a pile of files is a different thing, and it belongs downstairs.

## License

MIT
