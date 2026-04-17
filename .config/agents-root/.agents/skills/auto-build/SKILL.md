---
name: auto-build
description: >-
  Fully autonomous end-to-end implementation from a Linear ticket or plain
  description — creates a worktree, implements the feature, runs a self-review,
  pushes a PR with Graphite, writes the PR description, and babysits CI and
  review comments until everything is green. Use this skill whenever the user
  says "build this", "implement this ticket", "auto-build", "work on KNO-123",
  "take this Linear issue and build it", "here's a description, just build it",
  or anything that implies fully autonomous implementation through to a merged
  PR. Also use when the user drops a Linear ticket ID or URL and asks the agent
  to handle it.
allowed-tools:
  - "Bash(git *)"
  - "Bash(gt *)"
  - "Bash(gh *)"
  - "Bash(bash ~/.agents/skills/worktree/scripts/*)"
  - "Bash(jq *)"
  - "Bash(find *)"
  - "Bash(cat *)"
---

# Auto-Build Skill

Fully autonomous implementation from a Linear ticket or description through to
a green, reviewed PR. The agent does the whole thing — worktree, code, review,
PR, CI babysitting — without needing the user to drive each step.

## Two entry points

### Path A — Linear ticket

The user provides a ticket ID (e.g. `KNO-123`) or a Linear URL. Fetch the full
ticket via the Linear MCP, then proceed to [Build](#build).

```
Linear_get_issue(id: "KNO-123")
```

Extract from the ticket:
- **Title** — use as the branch name base (slugify it)
- **Description** — the spec to implement
- **Team** — needed for any sub-issues or comments
- **Labels / priority** — context for how carefully to proceed

If the description is thin or ambiguous, read the comments thread too
(`Linear_list_comments`) before starting — comments often contain the real
spec.

Ensure the ticket is assigned to you and set to "In Progress":
```
Linear_save_issue(id: "<ticket-id>", assignee: "me", state: "In Progress")
```

### Path B — Plain description

The user provides a description of what to build. Before writing any code:

1. Ask the user which Linear team to file the ticket under (always ask — do not
   guess from repo name alone).
2. Create the ticket via Linear MCP, always assigned to the current user:
   ```
   Linear_save_issue(title: "...", description: "...", team: "...", state: "In Progress", assignee: "me")
   ```
3. Proceed with the ticket ID you just created — treat it identically to Path A
   from here.

---

## Build

This is the main sequence. Run each phase in order; do not skip or reorder.

### 1. Worktree

Load the **worktree** skill. Create a worktree for this ticket:

```bash
git worktree add -b <branch-name> ~/.local/worktree/<repo-name>/<branch-name> main
bash ~/.agents/skills/worktree/scripts/setup-worktree.sh <repo-root> <worktree-path>
bash ~/.agents/skills/worktree/scripts/memory.sh set-tool <worktree-path> graphite
```

Branch naming: use the ticket ID + slugified title, e.g.
`kno-123-add-user-avatar-upload`.

All subsequent commands run with `workdir=<worktree-path>`.

### 2. Understand the codebase

Before writing any code, orient yourself:

- Read `AGENTS.md` (repo root and any relevant subdirectory) — it tells you
  which project skills to load and what conventions apply.
- Read any project skills the AGENTS.md points to for the kind of change you're
  making (React, Elixir, TypeScript, etc.). Load them before touching code.
- Read the relevant existing files. Understand the patterns before adding new
  ones.

This step is not optional — blindly writing code without understanding the
codebase produces low-quality output that will fail review.

### 3. Implement

Implement the ticket. Follow the conventions from AGENTS.md and project skills
exactly. Run the project's validation commands as you go (lint, typecheck,
tests) — don't wait until the end to discover failures.

Use `gt modify` to amend commits as you iterate. Don't create multiple commits
per logical change — keep the branch clean.

### 4. UI verification (frontend changes only)

If the ticket involves any frontend changes (React components, CSS, layout,
UI interactions), load the **agent-browser** skill and visually verify the
changes in the browser before self-review. Don't wait for the user to ask —
take a screenshot and confirm the UI looks correct. Fix any visual issues
before moving on.

### 5. Self-review

Look for a project skill whose description mentions "review", "self-review",
"quality", or "best practices check". OpenCode discovers skills from three
locations — search all of them:

```bash
find .opencode/skills .claude/skills .agents/skills -name "SKILL.md" 2>/dev/null \
  | xargs grep -l -i "review\|quality check\|best practices" 2>/dev/null
```

Also walk up from the current working directory to the repo root — skills may
live in subdirectory-specific locations (e.g. `backend/.agents/skills/`). If
working in a subdirectory, search there too:

```bash
find . -path "*/skills/*/SKILL.md" -not -path "*/node_modules/*" 2>/dev/null \
  | xargs grep -l -i "review\|quality check\|best practices" 2>/dev/null
```

Load the most relevant one for the type of change made. If multiple match,
prefer the most specific one (e.g. `dashboard-self-review` over a generic
`code-review` for a dashboard change).

Fix any issues the review surfaces before moving on. The goal is to catch what
a human reviewer would catch before they see it.

If no review skill is found, run the project's standard validation commands
from AGENTS.md instead (lint, test, typecheck).

### 6. Commit and push

Load the **graphite** skill. Stage and commit:

```bash
git add -A
gt modify -m "<type>(<scope>): <description>"
```

Then submit the PR:

```bash
gt submit --no-interactive
```

### 7. Write the PR description

Load the **write-pr-description** skill. Run it against the current branch to
produce a PR description, then apply it:

```bash
gh pr edit <pr-number> --title "<ticket-id>: <title>" --body-file /tmp/pr-body.md
```

Include in the description:
- A link to the Linear ticket
- What was changed and why
- Any notable decisions or tradeoffs

### 8. Update Linear ticket

Move the ticket to "In Review" and link the PR:

```
Linear_save_issue(id: "<ticket-id>", state: "In Review")
Linear_save_issue(id: "<ticket-id>", links: [{url: "<pr-url>", title: "PR #<number>"}])
```

### 9. Babysit the PR

Load the **fix-pr-comments** skill in **watch mode**. Use a 60-second poll
interval — when the skill asks how often to poll, select 60 seconds without
prompting the user.

Keep polling until all CI checks are green and all review threads are resolved.
Do not stop early. When BugBot or CI failures appear, fix them using the
fix-pr-comments workflow, push with `gt ss`, and restart the watch loop.

Tell the user you're watching and how to interrupt: "I'm watching PR #<n>.
Send a message at any time to stop."

---

## Guardrails

**Scope creep** — implement only what the ticket describes. If you notice
adjacent issues while exploring the codebase, note them as comments on the
Linear ticket but do not fix them in this branch.

**Ambiguous spec** — if the ticket description leaves a decision genuinely
open (not just implementation detail), ask before writing code. One clarifying
question upfront is better than a wrong implementation that requires a full
rewrite.

**Large tickets** — if the ticket appears to require changes across many
unrelated areas, surface this to the user before starting. It may be worth
splitting into a stack of smaller PRs.

**Failing validation** — if lint/test/typecheck failures cannot be fixed
within a reasonable number of attempts, stop and report to the user rather
than pushing broken code.
