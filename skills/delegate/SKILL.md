---
name: delegate
description: Hand mechanical implementation work to a cheaper model (DeepSeek via opencode) running in an isolated git worktree, then review what comes back. Use when the user says "delegate this", "give it to deepseek", "farm this out", "run it in a worktree", or when a task is large but mechanical — repetitive edits across many files, applying an existing pattern, a settled migration or rename, tests against behaviour already specified. Also use when planning a big task that should be split into slices for a cheaper implementer. Works in any repository, and on a brand-new project with no git repo yet. If the `delegate` command is not found, run /delegate-setup once.
---

# Delegating implementation work

The `delegate` command runs a cheaper implementer (DeepSeek via `opencode`) inside a
git worktree. **The worktree is the task record** — it knows its repo, its name, its
brief (`TASK.md`) and its state (branch + git log). There is no database and no server.

## Commands

```bash
delegate plan <repo-path> <slug>         # question on stdin; investigates, writes PLAN.md, no code
delegate new <repo-path> <slug> [base]   # brief on stdin; [base] stacks on another task's branch
delegate check <slug>                    # re-run the implementer's own VERIFY, bounded output
delegate review <slug>                   # commit bodies + diffstat. Small on purpose
delegate rework <slug>                   # review notes on stdin; continues the same session
delegate ls                              # the board
delegate drop <slug>                     # remove the worktree; the ds/<slug> branch survives
```

Default model is `deepseek/deepseek-v4-flash` at effort `low`; override per run with
`DELEGATE_MODEL=deepseek/deepseek-v4-pro` or `DELEGATE_VARIANT=high`. Low effort was
measured on an identical brief: 37s vs 56s and $0.0040 vs $0.0047, both passing the
same verify — effort buys little on mechanical work. Reach for `high` when the round
is genuinely reasoning-heavy (a `plan` round on unfamiliar code), not by default; one
extra rework round costs far more than the seconds low effort saves.

**Always launch `new` and `rework` with `run_in_background: true`.** The script runs
opencode in the foreground so the harness owns the process and notifies you when it
exits. Never background it inside the script — the notification is the whole point.

## Routing

**Delegate:** repetitive edits across files · applying a pattern that already exists in
the repo · mechanical migrations and renames · tests against behaviour you have already
specified · CRUD against a settled schema · scaffolding and boilerplate.

**Keep:** architecture · debugging anything whose cause is unknown · security, auth,
payments · performance work needing measurement · anything touching a public API
contract · **the words the product says to a user** · the review itself.

User-facing wording looks cosmetic and is not. A label is a claim, and a claim can be
false in a way no test and no reviewer of a diff will catch — «فروش» on a buyer's file
reads fine to anyone who does not know the domain. If the change is «what should this
say?», that is a judgement about the user's business, and it is yours.

**Keep anything small.** Under roughly 40 lines in one file, writing the brief costs
more than the change. Delegating a small task *raises* total cost — do it yourself.

**The size gate needs a fact, not a guess, and you usually already have one.** Before
writing any brief, ask: *can I already name the exact lines to change?* If yes — the
file is in context, the edit is a class name, a condition, a string — the investigation
is already paid for and the brief is now strictly more expensive than the edit. Make the
edit. This is the rule that actually fails in practice, because writing a brief feels
like progress: it produces a page of text and a running task, and neither is the work.
Delegating is for the investigation you have *not* done yet.

## Route again whenever the shape changes

**The routing decision is not made once per task.** Deciding at the first line and then
living with it for two hours produces both mistakes, and has produced both: a whole
feature handed down because it looked mechanical from outside, and a whole feature kept
because the first twenty minutes of it were architecture. The task did not have one
nature — you only asked once.

Re-check at every boundary you cross. Three are worth naming:

- **The shape just settled.** The interface exists, the schema is decided, the hard call
  is made. Everything downstream of that line is now «apply a pattern that already
  exists in the repo», which is the first entry under Delegate. Commit the foundation
  and hand the slices down — that is what `delegate new <repo> <slice> ds/foundation`
  is for, and the brief is short precisely because the design is already in the branch.
- **It is bigger than you thought.** The moment a change turns out to span six files
  instead of one, the size gate was answered with a number that is no longer true. Ask
  it again with the real one.
- **You just finished a piece.** Judge the next piece on what it is, not on the task it
  belongs to. A driver against an external API you cannot verify is yours; the test file
  beside it is not, and they arrive in the same breath.

**Look at the board before you keep something.** `delegate ls` is one call. An idle
implementer is capacity that costs nothing while it sits there, and «I am already here
with the files open» is a reason to finish an edit, never a reason to start one.

**The one thing not to re-route: work already underway.** Once you have read the files
and begun the edit, the investigation is spent. Finish it. Re-routing mid-edit throws
away the half you already paid for and buys a brief on top of it.

## The brief

The implementer cannot see your conversation and will not ask before guessing. Each
brief stands alone: goal in one line · exact files and symbols · expected behaviour and
the edge cases that matter · an existing file to imitate · what must not change · the
traps a cheaper model gets wrong · the exact verify command · the commit message.

The plugin's `PROMPT.md` is prepended automatically — do not restate its rules. It already
tells the implementer to read the repo's own `AGENTS.md`/`CLAUDE.md`, to make its own
judgement calls, and to record every one of them in the commit body.

## Keep the token burn on the cheap model

This is the point of the whole thing, and the measured numbers say it is where the
design actually leaks. On a real five-task run the implementer cost $0.09 while the
orchestrating session cost $16 — 20.7M of that was cache reads, the session's own
context re-read across 173 API calls. The implementation was never the expensive part.
**Your own tool calls are.** So:

- **Do not read the codebase to write a brief.** That investigation is the single
  biggest hidden cost, and it is exactly the kind of work to hand down. Run
  `delegate plan` first: the cheap model reads the code and writes `PLAN.md`; you read
  only that, correct it, then `delegate rework` to implement. Two cheap rounds beat one
  expensive one.
- **Verify through `delegate check`, not by composing commands yourself.** It runs the
  implementer's own `VERIFY` and prints 15 lines. Never run a full test suite whose
  output lands in your context.
- **Never look at a screenshot you can get as text.** Visual checks belong in the
  brief; ask for a described result, not an image. An image is re-read on every
  subsequent API call for the rest of the session.
- **Batch your shell calls.** Each round trip re-reads the whole conversation. Three
  commands in one Bash call cost a fraction of three calls.
- Engage directly only where judgement is actually load-bearing: the design, the
  security-sensitive code, the review verdict.

## Reviewing

Never take "done" on trust, and **never read the run logs under `$DELEGATE_HOME/logs/`** — that log is the one
thing that can blow up your context. The diff is the report.

```
delegate review <slug>     # what changed, and every decision, from the commit bodies
<re-run the brief's verify command yourself>
git -C <worktree> diff <base>...HEAD -- <file>   # only if the stat or the tests look wrong
```

Judge the recorded decisions: a package the implementer chose to install may well be
right. Reversing a recorded decision is normal. Then `delegate rework <slug>` with notes,
or accept.

**Bounded repair is enforced, not remembered.** `delegate check` records a hash of each
failed verify run, and `delegate rework` refuses in two cases: the same failure hash
twice in a row (it is not making progress — take the task back), or `DELEGATE_MAX_ROUNDS`
failed rounds, default 4 (the briefing cost has eaten the saving). A round that fails
*differently* is progress and is allowed through. `DELEGATE_FORCE=1` overrides both —
use it when you know why the failure repeated and your new notes address it.

The hash is of raw verify output, so a non-deterministic verify (timestamps, random temp
paths) hides a repeat from the guard; the round cap is the backstop for that.

## Big tasks

Build the foundation yourself — architecture, interfaces, the risky parts — and commit a
`PLAN.md` describing the whole job alongside it. Every slice then branches off that
foundation and **already contains the plan**, so each brief is ten lines pointing at a
section instead of restating the design. That is what keeps the orchestration cheap.

```bash
delegate new <repo> slice-a ds/foundation    # file-disjoint slices: launch together
delegate new <repo> slice-b ds/foundation
delegate new <repo> slice-c ds/slice-a       # dependent: stack it
```

Split by file ownership, not by feature — two parallel slices touching one file conflict
at merge and eat the saving. Fan out only once the foundation's tests pass; a wrong
foundation makes every slice wrong. Review each slice as it lands, not at the end.

While a slice runs you are not blocked: pick up the next piece of work.
