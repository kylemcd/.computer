---
name: agent-team
description: >
  Orchestrates a team of specialized AI agents under a Project Manager to tackle large, complex, or multi-faceted engineering tasks. Use this skill whenever a task is too big for a single agent pass, requires parallel work streams, spans multiple disciplines (code + tests + docs + security), or when the user says things like "this is a big task", "let's plan this out properly", "coordinate agents on this", "I need a team to work on this", or describes something that clearly has more than 3-4 distinct work streams. Also trigger when the user wants structured planning with acceptance criteria before any implementation begins. Do NOT use for small, single-pass tasks that one agent can handle in a few steps.
---

# Agent Team

A Project Manager (PM) agent coordinates a team of specialized subagents to plan, execute, and verify complex engineering work. The PM owns the planning process, delegates work in parallel waves, tracks acceptance criteria, and keeps looping until the definition of done is met.

---

## Files in This Skill

**Agent roles:**

| File | Purpose |
|---|---|
| `agents/task-tracker.md` | Runs after every wave; reconciles plan files against reality |
| `agents/scribe.md` | Writes user-facing documentation artifacts |
| `agents/software-engineer.md` | Implements code changes |
| `agents/architect.md` | Design decisions, structure, technical debt |
| `agents/code-reviewer.md` | Patterns, conventions, AGENTS.md compliance |
| `agents/qa-tester.md` | Tests and behavioral verification |
| `agents/security-auditor.md` | Vulnerabilities, auth, OWASP |
| `agents/performance-engineer.md` | Profiling, benchmarks, optimization |
| `agents/debugger.md` | Root cause analysis, error tracing |
| `agents/dependency-manager.md` | Package audits, version conflicts, licenses |
| `agents/integration-tester.md` | API contracts, interface boundaries, e2e flows |
| `agents/accessibility-auditor.md` | ARIA, keyboard nav, contrast, screen reader |
| `agents/database-specialist.md` | Schema, queries, migrations, data integrity |
| `agents/git-manager.md` | Final wave: commit split proposal, PR creation, push |
| `agents/linear-manager.md` | Linear ticket creation, state updates, PR linking |
| `agents/pr-reviewer.md` | On-demand: addresses review comments on task PRs |

**Bundled skills (all agents read `writing-style.md` before writing anything):**

| File | Purpose |
|---|---|
| `skills/writing-style.md` | Universal voice and format guide — applies to every agent |
| `skills/browser-verify.md` | UI verification: screenshots, network, console, errors via `npx agent-browser` |
| `skills/run-checks.md` | Test/build/lint/typecheck across all languages and toolchains |
| `skills/read-logs.md` | Extracting signal from dev server, test runner, build, and CI logs |
| `skills/api-test.md` | HTTP endpoint testing with `curl` — auth patterns, response verification |
| `skills/linear.md` | Linear MCP usage: create/update issues, link PRs, manage states |
| `skills/pr-description.md` | PR description writing guide — format, style, stacked PR conventions |

---

## Plan Directory Structure

When you begin a task, create a `.agent-team/` directory in the repository root. This directory is the single source of truth for every agent on every wave. It is intentionally separate from user-facing files — agents own it, not the codebase.

```
.agent-team/
├── PLAN.md           ← index: goal, criteria, wave overview, links to all other files
├── tasks.md          ← full task table with IDs, statuses, roles, assignments
├── change-log.md     ← file-level change history (Task Tracker maintains)
├── decisions.md      ← decisions log (PM writes, agents may append; architect writes design here)
├── blockers.md       ← questions & blockers (agents append here)
├── final-summary.md  ← written by Task Tracker at wrap-up
└── after-action.md   ← PM-written agent grades and role improvement notes
```

The entire `.agent-team/` directory must be in `.gitignore` — these are internal planning files, not project artifacts. Add it at task start if not already excluded.

Every agent prompt should reference these files explicitly and instruct the agent to read the ones relevant to its work before starting.

---

## File Templates

### `.agent-team/PLAN.md` — Index file (keep this short and scannable)

```markdown
# Task Plan

**Created:** [date]  
**Status:** 🔄 In Progress  
**Current Wave:** [N]

---

## Goal
[What needs to be done and why]

---

## Constraints & Context
- Tech stack: ...
- Key files/modules involved: ...
- Patterns to follow: ...
- Things to avoid: ...

---

## Risk Areas
- ...

---

## Out of Scope
- ...

---

## Acceptance Criteria
| ID | Criterion | Status | Evidence | Wave Verified |
|----|-----------|--------|----------|---------------|
| AC-001 | [verifiable criterion] | ⏳ pending | — | — |
| AC-002 | [verifiable criterion] | ⏳ pending | — | — |

Status key: ⏳ pending | 🔄 in progress | ✅ met | ❌ not met

---

## Wave Overview
| Wave | Description | Status |
|------|-------------|--------|
| 1 | [description] | ⏳ pending |
| 2 | [description] | ⏳ pending |

---

## Linked Files
- [Tasks & Assignments](.agent-team/tasks.md)
- [Change Log](.agent-team/change-log.md)
- [Decisions](.agent-team/decisions.md)
- [Blockers & Questions](.agent-team/blockers.md)
- [Final Summary](.agent-team/final-summary.md)
- [After-Action Report](.agent-team/after-action.md)
```

---

### `.agent-team/tasks.md` — Full task breakdown

```markdown
# Tasks

Task status key: ⏳ pending | 🔄 in progress | ✅ done | ❌ failed | 🔴 blocked

---

## Wave 1: [description]

| ID | Role | Task | Status | Files Changed |
|----|------|------|--------|---------------|
| TASK-001 | architect | [description] | ⏳ pending | — |
| TASK-002 | software-engineer | [description] | ⏳ pending | — |

---

## Wave 2: [description]

| ID | Role | Task | Status | Files Changed |
|----|------|------|--------|---------------|
| TASK-003 | qa-tester | [description] | ⏳ pending | — |
```

---

### `.agent-team/change-log.md` — File-level change history

```markdown
# Change Log

Maintained by Task Tracker. Updated after every wave.

| Wave | File | What Changed | Agent | Task ID |
|------|------|--------------|-------|---------|
```

---

### `.agent-team/decisions.md` — Decisions log

```markdown
# Decisions Log

| Wave | Decision | Rationale | Made By |
|------|----------|-----------|---------|
```

---

### `.agent-team/blockers.md` — Questions & blockers (agents append here)

```markdown
# Blockers & Questions

Agents: append your questions or blockers below using this format.
PM will review after each wave and resolve or escalate to the user.

Format: **ROLE | TASK-ID | Wave N** — [question or blocker description]

---
```

---

### `.agent-team/final-summary.md` — Written at wrap-up

```markdown
# Final Summary

**Completed:** [date]  
**Total Waves:** [N]

## What Was Done
[High-level narrative]

## Acceptance Criteria Met
| ID | Criterion | Evidence |
|----|-----------|----------|

## Key Decisions
[Summary from decisions.md]

## New Verification Skills Created
[List any skills added to agent-team/skills/]

## Follow-Up Items / Tech Debt
- ...
```

---

### `.agent-team/after-action.md` — Written by PM at wrap-up

```markdown
# After-Action Report

**Task:** [task title from PLAN.md]  
**Completed:** [date]  
**Total Waves:** [N]  
**Agents Used:** [list of roles]

---

## Agent Grades

### [Role Name] — TASK-XXX, TASK-XXX

**Grade:** A | B | C | D | F

| Dimension | Score (1–5) | Notes |
|-----------|-------------|-------|
| Structured output quality | | Did they follow the output format? |
| Self-report accuracy | | Did Task Tracker confirm what they claimed? |
| Verification rigor | | Did they verify, or just say "done"? |
| Scope discipline | | Did they stay on task or drift? |
| Blocker handling | | Did they surface blockers promptly and clearly? |
| Overall quality | | Was the work itself correct and complete? |

**What went well:**
[specific observations]

**What could be better:**
[specific observations — these feed directly into role file improvements]

---

[repeat for each agent that participated]

---

## Role Improvements Applied

| Role File | Change Made | Reason |
|-----------|-------------|--------|
| `agents/software-engineer.md` | [description] | [what the grade revealed] |

---

## Patterns Observed Across Agents

[Any systemic issues — e.g., "three agents produced incomplete blockers.md entries", "verification was consistently skipped when tasks ran long"]
```

---

## Phase 1 — Structured Planning Interview

Before writing any code or spawning any agents, conduct a thorough planning interview with the user. Work through these sections in order — do not skip any.

### 1. Goal
Ask the user to describe what needs to be done and why. Probe for the underlying motivation, not just the surface request. A well-stated goal answers: what will be different when this is done?

### 2. Constraints & Context
- What tech stack is involved?
- Which files, modules, or services are in scope?
- Are there existing patterns to follow? (Check `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md` if present — read them.)
- What should be avoided or left alone?
- **How should changes be submitted?** Options: `single-branch` (one commit, no PR), `single-pr` (one PR), `stacked-graphite` (stacked PRs using Graphite `gt`), `stacked-plain` (stacked PRs with plain git + gh). Record as `git-mode` in PLAN.md.
- **Do you use Linear?** If yes: should tickets be created fresh, linked to existing ones, or sub-issues added under an existing parent? What team and project? Record as `linear-mode` (values: `create`, `link`, `both`, or unset) and `linear-project` in PLAN.md.

### 3. Acceptance Criteria
This is the most important section. Spend more time here than anywhere else.

For each goal the user states, ask: **"How would you verify this is done?"** Keep asking until each criterion is specific enough to check programmatically or with a clear manual test. Push back on vague criteria like "it works" — help the user translate them into verifiable statements:

- Bad: "The feature works"
- Good: "The `/api/users` endpoint returns 200 with `{id, name, email}` for authenticated requests and 401 for unauthenticated ones"

Assign each criterion an ID (AC-001, AC-002, ...).

### 4. Risk Areas
What's likely to break? What's unfamiliar territory in this codebase? What has dependencies that could cause problems?

### 5. Out of Scope
What are we explicitly not doing? Getting this on paper prevents scope creep and helps agents stay focused.

### 0. Check for an existing `.agent-team/` directory

Before creating anything, check whether `.agent-team/` already exists in the repo root:

```bash
ls .agent-team/ 2>/dev/null
```

If it exists, ask the user:
- **Continue the previous task** — read the existing files and resume from the last completed wave.
- **Archive it** — rename to `.agent-team-YYYY-MM-DD/` and start fresh.
- **Delete it** — start fresh, discarding prior work.

Do not overwrite silently. An existing `.agent-team/` means a prior run happened and the user's intent must be confirmed.

### Show the plan and confirm

After the interview, create the `.agent-team/` directory and write all plan files using the templates above. Start with `PLAN.md` (the index) and `tasks.md` — the others can be initialized as empty shells.

Also add `.agent-team/` to `.gitignore` if not already present:

```bash
grep -q "^\.agent-team" .gitignore 2>/dev/null || echo ".agent-team/" >> .gitignore
```

Show the user `PLAN.md` and offer to adjust anything. Do not spawn any agents until the user approves the plan.

---

## Phase 2 — Role Selection & Work Breakdown

Read the confirmed plan and decide:

**Which roles are needed?** Not every task needs every role. Only assign roles whose work is actually required by the plan. Common patterns:
- Pure backend feature: architect, software-engineer, qa-tester, code-reviewer, integration-tester
- Frontend feature: software-engineer, qa-tester, accessibility-auditor, code-reviewer
- Security-sensitive work: security-auditor always
- DB changes: database-specialist always
- New dependencies: dependency-manager always
- User-facing docs needed: scribe
- `git-manager` — **always** assigned; runs in the final wave after all acceptance criteria are met
- `linear-manager` — assigned when `linear-mode` is set in PLAN.md; runs in Wave 1 and at wrap-up
- `task-tracker` — **always** runs after every wave; never assigned to a wave, always post-wave
- `pr-reviewer` — **on-demand only**; not pre-assigned during planning. The PM spawns it reactively when review feedback arrives on a task PR, potentially days after the task completed.

**Wave planning — respect dependencies (this is a hard constraint, not a guideline):**

If Agent B needs Agent A's output to do its work, A and B must be in different waves. A must complete first. Placing them in the same wave is a structural error — B will read stale context and produce incompatible work.

Common dependency chains that must be respected:
- Architect → Software Engineer (engineer needs the design)
- Software Engineer → Code Reviewer, QA Tester, Security Auditor (reviewers need the code)
- All implementation → Integration Tester (needs interfaces to exist)
- DB migration → any code that uses the new schema
- Dependency Manager → any code using the new dependency

When in doubt, put the dependency in an earlier wave. The cost of an extra wave is low. The cost of two agents making conflicting structural decisions is high.

The Task Tracker always runs after each implementation wave (not in parallel with it). Code review, QA, and security audit run after implementation, not during.

**Assign task IDs** (TASK-001, TASK-002, ...) to every discrete unit of work. A task should be completable by one agent in one session — if it's too big, break it down.

Update `.agent-team/tasks.md` with the full wave breakdown and task table, and update the Wave Overview table in `.agent-team/PLAN.md` before spawning anything.

---

## Phase 3 — Wave Execution Loop

This is the core loop. Run it until all acceptance criteria are `✅ met`.

### For each wave:

**Step 1: Spawn all agents in this wave in the same turn (parallel)**

Each agent receives:
- The full content of `.agent-team/PLAN.md` (index)
- The full content of `.agent-team/tasks.md` (their specific task IDs)
- The full content of `.agent-team/change-log.md` (what has already been changed)
- The full content of `.agent-team/blockers.md` (known issues)
- The full content of `.agent-team/decisions.md` (architect design output and all prior decisions — **always include this from Wave 2 onwards**)
- The content of their role file (read it and include it verbatim in their prompt)
- Their specific task ID(s) for this wave
- The list of available verification skills (see Verification section below)
- Instructions to produce structured output (see Output Format below)
- Instructions to read `skills/writing-style.md` before writing anything
- Instructions to check `agent-team/skills/` for existing verification scripts before building new ones
- Instructions to append any blockers/questions to `.agent-team/blockers.md`

Do not gather context yourself before spawning — let each agent do its own context gathering for its assigned tasks.

**Step 2: Wait for all wave agents to complete**

If an agent produces no output or returns only freeform prose with no structured `## Task Output` block, treat that task as `❌ failed` — do not attempt to infer status from the text. Surface it to the Task Tracker as a missing output.

**Step 3: Spawn the Task Tracker**

After every wave, always — no exceptions. The Task Tracker:
- Reads all agent outputs
- Reconciles reported changes against actual file state
- Updates `.agent-team/tasks.md` task statuses with evidence
- Appends new entries to `.agent-team/change-log.md`
- Flags any discrepancies between what agents said they did and what actually exists in the files

Wait for the Task Tracker to complete before proceeding.

**Step 4: Check for questions and blockers**

Read `.agent-team/blockers.md`. For each new entry since the last wave:
- If the blocker can be resolved without user input (e.g., a design ambiguity that has an obvious answer given the plan), document your resolution as a decision in `.agent-team/decisions.md` and proceed.
- If the blocker requires user input and **other waves can proceed without the answer**, document an assumption in `.agent-team/decisions.md`, mark it as an unresolved assumption, and continue.
- If the blocker requires user input and **blocks all remaining work**, stop the loop. Surface the full context to the user: what is blocked, what was tried, and exactly what you need from them. Do not proceed until resolved.

**Conflict resolution:** If the Task Tracker flagged a file conflict (two agents modified the same file in ways that don't merge cleanly), decide now — do not let it carry forward. Determine which version is correct, record the resolution in `.agent-team/decisions.md` with your reasoning, and if needed schedule a targeted remediation task for the next wave.

Append any decisions made to `.agent-team/decisions.md`.

**Step 5: Check acceptance criteria and code-reviewer findings**

Read the Criteria Status table in `.agent-team/PLAN.md`. For each criterion, assess whether the work done in this wave has moved it forward. Update the table. Ask yourself: is there enough evidence to mark this `✅ met`? Be strict — partial implementation is not `✅`.

Also check any code-reviewer outputs from this wave. A task with `blocking` findings from the code-reviewer is **not done**, regardless of what the implementing agent reported. Treat blocking findings as equivalent to `❌` on that task — plan a remediation wave.

**Step 6: Decide what comes next**

| State | Action |
|---|---|
| All criteria ✅ | Proceed to wrap-up (Phase 4) |
| Some criteria ❌, first time | Plan a remediation wave, explain why to user |
| Same criterion ❌ for 2+ waves in a row | Stop and escalate to user with: what was tried, why it failed, what you need from them |
| Criteria ⏳ but work is progressing | Continue to next planned wave |

### Agent Output Format

Every agent must return structured output in this format. Include this requirement in every agent prompt:

```
## Task Output

### TASK-XXX: [task title]
**Status:** ✅ done | ❌ failed | 🔴 blocked
**What I did:** [concrete description]
**Files changed:**
- path/to/file.ts — [what changed and why]
**Verification:**
- Method used: [skill name or manual check]
- Result: [passed/failed, with evidence]
**Blockers/Questions:** [none | description — also written to PLAN.md#Questions & Blockers]
```

### Writing convention

Every agent must read `skills/writing-style.md` before writing anything — `.agent-team/` files, PR descriptions, tickets, commit messages, or documentation. Include this instruction in every agent prompt without exception. Unattributed or freeform writing makes reconciliation and grading unreliable.

### Verification skills

Agents use verification skills matched to task type. Include the relevant skill reference in every agent prompt.

**Backend / logic tasks** → read and follow `skills/run-checks.md`
- Type check → lint → test → build, in that order
- Use the project's own script aliases where available

**Frontend / UI tasks** → read and follow `skills/browser-verify.md`
- Run the standard checklist: open → clear buffers → interact → screenshot → check errors → check console → check failed network requests
- Also check dev server output for build/HMR errors not visible in the browser

**API / integration tasks** → read and follow `skills/api-test.md`
- Verify status codes, response shapes, auth behaviour
- Chain requests where needed (login → use token)

**Debugging / log analysis** → read and follow `skills/read-logs.md`
- Find the root cause, not just the first error
- Use signal extraction patterns to cut through noise

**If no existing skill covers the verification need:**
1. Agent completes its work first
2. Agent uses `skill-creator` to build a minimal verification script, saves it to `agent-team/skills/`
3. Agent uses the new script to verify, notes the new skill in its output

### Ad-hoc Roles

If a task genuinely requires a role not in the predefined list, the PM can define a new one — but only when no existing role covers the need even loosely. Requirements:
- Write a comprehensive `agents/<new-role>.md` following the same structure as existing role files
- Record the justification in `PLAN.md#Decisions Log`
- The file is saved permanently to `agent-team/agents/` for future tasks

This should be rare. When in doubt, stretch an existing role rather than creating a new one.

---

## Phase 4 — Wrap-Up

Once all acceptance criteria are `✅ met`, run these steps **in order** — each depends on the previous completing first:

1. **Spawn the Task Tracker** one final time to write `.agent-team/final-summary.md`. Wait for it to complete before proceeding.
2. **Spawn the Scribe** if any user-facing documentation needs updating (README, changelog, API docs, inline comments). Give it `.agent-team/change-log.md` and `.agent-team/final-summary.md` as context. Scribe must run after Task Tracker completes Step 1 — it needs `final-summary.md` to exist.
3. **Spawn the git-manager** — PM surfaces the PR split proposal to the user and waits for explicit approval before git-manager executes. The proposal is written to `.agent-team/decisions.md` and can be revised. Wait for git-manager to complete and write PR URLs to `decisions.md` before proceeding.
4. **Spawn the linear-manager** (if `linear-mode` is set) — reads PR URLs from `.agent-team/decisions.md` (written by git-manager in Step 3), links them to tickets, and closes issues. Linear-manager must run after git-manager — it needs the PR URLs.
5. **Write the after-action report** (see Phase 5) — once, after all PRs are created.
6. **Apply role improvements** from the after-action grades to the relevant `agents/*.md` files (see Phase 5).
7. **Present a summary to the user:**
   - What was done (high-level)
   - All acceptance criteria met (with evidence)
   - Key decisions made (from `.agent-team/decisions.md`)
   - PRs created (with URLs and CI status)
   - Linear tickets updated (if applicable)
   - Any new verification skills created (now in `agent-team/skills/`)
   - Role improvements applied (brief summary)
   - Location of `.agent-team/` for full detail

**Post-task: handling review feedback**

After PRs are created, the task is complete. If review comments arrive later (from humans or bots), the PM can re-engage by spawning `pr-reviewer` with the relevant PR number(s). The pr-reviewer reads `.agent-team/decisions.md` to understand original intent before triaging any comment — this is what makes it more accurate than a context-free review tool.

---

## Phase 5 — After-Action Report & Role Improvement

This phase runs exactly once, after all acceptance criteria are `✅ met`. Its purpose is to make the team permanently better.

### Step 1: Write `.agent-team/after-action.md`

Grade every agent that participated across the entire run — all waves combined, not wave by wave. You have the full picture now: every task output, every Task Tracker reconciliation, every blocker entry. Use all of it.

For each agent, score these dimensions 1–5 and assign an overall letter grade:

| Dimension | What to assess |
|---|---|
| Structured output quality | Did they consistently follow the required output format? |
| Self-report accuracy | Did Task Tracker's reconciliations confirm what they claimed? Any gaps? |
| Verification rigor | Did they actually verify their work, or just assert it was done? |
| Scope discipline | Did they stay within their assigned tasks, or drift into other roles' territory? |
| Blocker handling | Did they surface blockers promptly and with enough detail to act on? |
| Overall work quality | Was the output itself correct, complete, and useful? |

Grade scale: **A** = excellent, **B** = good, **C** = acceptable, **D** = poor, **F** = failed to function in role.

Be honest. An agent that reported `✅ done` on tasks the Task Tracker marked `❌ failed` should not get an A for self-report accuracy. The grades are only useful if they're truthful.

Also note patterns across agents — systemic issues that aren't one agent's fault but reflect a gap in how the team was structured or briefed.

### Step 2: Update role files based on grades

After writing the after-action report, open the `agents/*.md` file for each agent that scored below a B on any dimension, and append a `## Lessons from Prior Runs` section (or update it if it already exists). Write specific, actionable guidance derived directly from what went wrong:

- If a software-engineer repeatedly drifted into architecture: add a note reinforcing scope boundaries
- If a qa-tester's tests didn't catch a regression: add guidance about running the full suite
- If a security-auditor missed a class of issue: add that class to the checklist
- If blockers.md entries were too vague to act on: add a better example to that role's blocker format

The `## Lessons from Prior Runs` section should be appended at the bottom of the role file, below all existing content. Each entry should note the date so the history accumulates over time:

```markdown
## Lessons from Prior Runs

### [date]
- [specific lesson derived from the after-action grade]
- [another lesson]
```

Do not rewrite or remove existing lessons — append to them. These accumulate as institutional memory across every task this team runs.

---

## Attribution Convention

Every write to any `.agent-team/` file must be attributed. This is non-negotiable — the Task Tracker and PM rely on knowing exactly who wrote what to reconcile state and grade agents accurately.

**Format for all agent-written entries:**

```
> **[role] | [TASK-ID] | Wave [N] | [date]**
[content of the entry]
```

Examples:
- Blocker: `> **software-engineer | TASK-004 | Wave 2 | 2026-04-03** — Cannot resolve import cycle between auth.ts and session.ts`
- Change log row: each row already has Agent and Task ID columns — fill them in, never leave them blank
- Decisions: the `Made By` column must name the role, not just "agent"

The PM attributes its own writes the same way: `> **pm | Wave [N] | [date]**`

---

## Principles

- **`.agent-team/` is ground truth.** Every agent reads the relevant files before starting. The Task Tracker keeps them accurate after every wave. Never let them drift from reality.
- **Acceptance criteria drive everything.** The loop doesn't end until criteria are met. Vague criteria are the enemy — sharpen them during planning.
- **Only the PM talks to the user.** Agents communicate via `.agent-team/` files. The PM surfaces questions and decisions. This prevents the user from being interrupted by every agent independently.
- **Parallel within waves, sequential across waves.** All agents in a wave start together. The next wave doesn't start until the Task Tracker has reconciled the current one.
- **Verify before reporting done.** An agent that can't verify its work isn't done — it either uses an existing skill, builds a new one, or escalates to the PM.
- **Structured output is non-negotiable.** Freeform agent output makes Task Tracker's job impossible. Always include the structured output format in agent prompts.
- **Every write is attributed.** Any entry added to any `.agent-team/` file must follow the attribution format. Anonymous entries cannot be graded or traced.
- **Every agent follows the writing style.** All agents read `skills/writing-style.md` before writing anything. Consistent, concise writing makes every file more useful to every other agent that reads it.
- **Grades happen once, at the end.** The after-action report is written after all acceptance criteria are met — not after each wave. Per-wave Task Tracker reconciliations are inputs to the final grade, not grades themselves.
