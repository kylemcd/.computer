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
| `agents/ship-manager.md` | Phase 4: Linear tickets, git branches, draft PRs, linking — full shipping lifecycle |
| `agents/pr-reviewer.md` | On-demand: addresses review comments on task PRs |
| `agents/researcher.md` | Codebase mapping, library research, API investigation — runs before design and on-demand during execution |
| `agents/tools-engineer.md` | Builds reusable automation scripts in the global `skills/` directory that other agents can run without human intervention |
| `agents/recovery-coordinator.md` | Auto-triggered when execution derails — diagnoses what went wrong, rewrites the plan, and gets the task back on track |
| `lessons-learned.md` | Optional project-specific history of past failures and fixes — if present in a project's `.agent-teams/` directory, read by PM and recovery-coordinator on demand |

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

Each agent-team run gets its own directory under `.agent-teams/` in the repository root. The PM picks a short, descriptive name at task start using the format `YYYY-MM-DD-<slug>` (e.g., `2026-04-03-search-refactor`). This directory is the single source of truth for every agent on every wave. It is intentionally separate from user-facing files — agents own it, not the codebase.

Throughout this document, `$RUN` refers to the run directory path: `.agent-teams/<run-name>/`.

```
.agent-teams/
├── 2026-04-03-auth-refactor/               ← completed prior run
│   ├── PLAN.md
│   ├── ...
├── 2026-04-03-search-refactor/             ← current run ($RUN)
│   ├── PLAN.md           ← index: goal, criteria, wave overview, links to all other files
│   ├── tasks.md          ← full task table with IDs, statuses, roles, assignments
│   ├── change-log.md     ← file-level change history (Task Tracker maintains)
│   ├── decisions.md      ← decisions log (PM writes, agents may append; architect writes design here)
│   ├── blockers.md       ← questions & blockers (agents append here)
│   ├── research.md       ← researcher findings: codebase maps, library APIs, external docs
│   ├── final-summary.md  ← written by Task Tracker at wrap-up
│   ├── after-action.md   ← PM-written agent grades and role improvement notes
│   └── agent-logs/       ← per-agent execution logs (see Agent Memory below)
│       ├── TASK-001-researcher.md
│       ├── TASK-003-architect.md
│       └── ...
```

Tools and verification scripts built by the tools-engineer are saved to the global `skills/` directory inside the agent-team skill package (alongside `writing-style.md`, `browser-verify.md`, etc.). These persist across tasks and are reusable by any future agent-team run.

The entire `.agent-teams/` directory must be in `.gitignore` — these are internal planning files, not project artifacts. Add it at task start if not already excluded.

Every agent prompt should reference these files explicitly (using the full `$RUN` path) and instruct the agent to read the ones relevant to its work before starting.

### Agent Memory (`agent-logs/`)

Each spawned subagent writes a log file to `$RUN/agent-logs/` named `TASK-{ID}-{role}.md`. This file persists across the task run and serves two purposes:

1. **Continuity** — if the same role is spawned again (e.g., a second software-engineer wave, or a remediation pass), the new agent reads all prior logs for that role to understand what was already tried, what failed, and what decisions were made. The PM must include all relevant prior logs in the agent's prompt.
2. **Context recovery** — the Task Tracker and recovery-coordinator can read agent logs to reconstruct what happened without relying solely on structured output, which may be missing or incomplete.

**Agent log format:**

```markdown
# TASK-{ID} — {role} — Wave {N}

**Started:** {timestamp}
**Branch:** {git branch if relevant}

## What I did
{narrative of actions taken, in order}

## Key decisions
{any choices made during execution and why}

## Files touched
- `path/to/file.ts` — {what and why}

## Issues encountered
{anything unexpected — errors, ambiguities, workarounds}

## Result
{final status and evidence}
```

Every agent prompt must include the instruction: "Write your execution log to `$RUN/agent-logs/TASK-{ID}-{role}.md` before returning your structured output." The log is written by the agent itself, not by the PM or Task Tracker.

The PM never writes agent logs. The PM reads them when needed for context (e.g., when planning remediation waves or when the recovery-coordinator needs to diagnose what went wrong).

---

## File Templates

### `$RUN/PLAN.md` — Index file (keep this short and scannable)

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
- [Tasks & Assignments](tasks.md)
- [Change Log](change-log.md)
- [Decisions](decisions.md)
- [Blockers & Questions](blockers.md)
- [Research](research.md)
- [Final Summary](final-summary.md)
- [After-Action Report](after-action.md)
```

---

### `$RUN/tasks.md` — Full task breakdown

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

### `$RUN/change-log.md` — File-level change history

```markdown
# Change Log

Maintained by Task Tracker. Updated after every wave.

| Wave | File | What Changed | Agent | Task ID |
|------|------|--------------|-------|---------|
```

---

### `$RUN/decisions.md` — Decisions log

```markdown
# Decisions Log

| Wave | Decision | Rationale | Made By |
|------|----------|-----------|---------|
```

---

### `$RUN/blockers.md` — Questions & blockers (agents append here)

```markdown
# Blockers & Questions

Agents: append your questions or blockers below using this format.
PM will review after each wave and resolve or escalate to the user.

Format: **ROLE | TASK-ID | Wave N** — [question or blocker description]

---
```

---

### `$RUN/research.md` — Researcher findings

```markdown
# Research

Maintained by the researcher role. Each entry covers one question or topic.

---
```

---

### `$RUN/final-summary.md` — Written at wrap-up

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

### `$RUN/after-action.md` — Written by PM at wrap-up

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

### 5. Feature Flagging
Ask whether the changes need to be gated behind a feature flag. Not all work needs flagging — bug fixes, refactors, and internal tooling usually don't. But new user-facing features, behavioral changes, and risky migrations often do.

Questions to ask:
- **Is this user-facing?** New UI, changed behavior, new API endpoints → likely needs a flag.
- **Is this risky or reversible?** If something goes wrong, can we turn it off without a revert? A flag makes that possible.
- **Is this a gradual rollout?** If you want to ship to a subset of users first (internal, beta, percentage) → needs a flag.
- **Is this a refactor or bug fix?** Usually no flag needed — the old behavior was wrong.

If flagging is needed, record:
- Flag name and where it's checked (e.g., `new-checkout-flow` in the app, checked via `useFeatureFlag`)
- Default state (off for new features, on for migrations that are ready)
- Who controls the flag (LaunchDarkly, feature flag service, env var, etc.)
- Cleanup plan — flags are tech debt. Note when the flag should be removed.

Record the decision in PLAN.md under Constraints & Context as `feature-flag: [flag-name]` or `feature-flag: none`.

### 6. Out of Scope
What are we explicitly not doing? Getting this on paper prevents scope creep and helps agents stay focused.

### 0. Check for existing runs and pick a run name

Before creating anything, check whether `.agent-teams/` exists and list prior runs:

```bash
ls .agent-teams/ 2>/dev/null
```

If prior runs exist, mention them to the user. If any run looks related to the current task (similar name, recent date), ask whether to **continue that run** (resume from last completed wave) or **start a fresh run**.

Pick a name for the new run using the format `YYYY-MM-DD-<slug>` where `<slug>` is a short kebab-case description of the task (e.g., `2026-04-03-search-refactor`). The run directory is `.agent-teams/<run-name>/` — referred to as `$RUN` throughout this document.

Do not reuse a prior run's directory for a new task. Each task gets its own run.

### 7. Execution mode

Ask the user how they want to be involved during execution:

- **`autonomous`** — Run all waves to completion without pausing for approval between waves. Only stop for blockers that require user input. Present the final summary when done.
- **`supervised`** — Show the user a summary after each wave and wait for approval before proceeding to the next wave. This is the default if the user doesn't specify.

Record as `execution-mode` in PLAN.md. If the user says things like "run to completion", "just do it", "don't stop", or "I'll check at the end", use `autonomous`. If they say "let me review each step" or don't express a preference, use `supervised`.

### Show the plan and confirm

After the interview, create the `$RUN` directory and write all plan files using the templates above. Start with `PLAN.md` (the index) and `tasks.md` — the others can be initialized as empty shells.

Also add `.agent-teams/` to `.gitignore` if not already present:

```bash
grep -q "^\.agent-teams" .gitignore 2>/dev/null || echo ".agent-teams/" >> .gitignore
```

Create the run directory and `agent-logs/` subdirectory:

```bash
mkdir -p .agent-teams/<run-name>/agent-logs
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
- `ship-manager` — **always** assigned; runs in Phase 4 after all acceptance criteria are met. Owns the full shipping lifecycle: Linear tickets (if `linear-mode` is set), git branches, draft PRs, and linking. Replaces the separate `git-manager` and `linear-manager` roles. The sequencing is: propose PR split → create Linear sub-issues → create branches/draft PRs using ticket numbers → link PRs to tickets. When `git-mode` is `stacked-graphite`, the ship-manager must use `gt` commands exclusively (see Graphite hard gate in the role file).
- `task-tracker` — **always** runs after every wave; never assigned to a wave, always post-wave
- `researcher` — assign in **Wave 1** whenever the task involves unfamiliar libraries, a large or poorly-understood codebase, external APIs, or significant unknowns that the architect needs answered before designing. Also spawn **on-demand during any wave** when an agent writes a blocker that is fundamentally an information gap (not a conflict or decision — just "I don't know how X works").
- `tools-engineer` — assign whenever the task requires a repeatable automated process that other agents will invoke (measurement scripts, test harnesses, data collection, environment setup). Runs before the agents that will use the tool. Common trigger: an acceptance criterion that requires runtime measurement (performance, memory, load time) — the tools-engineer builds the measurement skill, then QA/performance agents use it. **Implementation note:** `tools-engineer` is not a built-in Cursor subagent type — use `generalPurpose` when spawning it.
- `pr-reviewer` — **on-demand only**; not pre-assigned during planning. The PM spawns it reactively when review feedback arrives on a task PR, potentially days after the task completed.
- `recovery-coordinator` — **auto-triggered only**; never pre-assigned during planning. The PM spawns it when recovery triggers are hit (see "Recovery trigger" in Phase 3). It reads all `$RUN/` files and agent logs, diagnoses the failure, and produces a corrected plan that the PM must adopt.

**Wave planning — respect dependencies (this is a hard constraint, not a guideline):**

If Agent B needs Agent A's output to do its work, A and B must be in different waves. A must complete first. Placing them in the same wave is a structural error — B will read stale context and produce incompatible work.

Common dependency chains that must be respected:
- Researcher → Architect (architect needs findings before designing — if researcher is assigned, it runs in Wave 1 and architect runs in Wave 2)
- Architect (design) → Software Engineer (engineer needs the design)
- Software Engineer → Architect (post-implementation review) + Code Reviewer + QA Tester + Security Auditor (all reviewers need the code — run these in parallel)
- Architect review / Code Reviewer / QA Tester → Software Engineer (remediation) → all reviewers again (re-verification). This cycle repeats until criteria are met.
- All implementation → Integration Tester (needs interfaces to exist)
- DB migration → any code that uses the new schema
- Dependency Manager → any code using the new dependency

When in doubt, put the dependency in an earlier wave. The cost of an extra wave is low. The cost of two agents making conflicting structural decisions is high.

The Task Tracker always runs after each implementation wave (not in parallel with it). Code review, QA, and security audit run after implementation, not during.

**Assign task IDs** (TASK-001, TASK-002, ...) to every discrete unit of work. A task should be completable by one agent in one session — if it's too big, break it down.

Update `$RUN/tasks.md` with the full wave breakdown and task table, and update the Wave Overview table in `$RUN/PLAN.md` before spawning anything.

---

## Phase 3 — Wave Execution Loop

This is the core loop. Run it until all acceptance criteria are `✅ met`.

### For each wave:

**Step 1: Spawn all agents in this wave in the same turn (parallel)**

Each agent receives:
- The full content of `$RUN/PLAN.md` (index)
- The full content of `$RUN/tasks.md` (their specific task IDs)
- The full content of `$RUN/change-log.md` (what has already been changed)
- The full content of `$RUN/blockers.md` (known issues)
- The full content of `$RUN/decisions.md` (architect design output and all prior decisions — **always include this from Wave 2 onwards**)
- The full content of `$RUN/research.md` if it exists (researcher findings about the codebase and libraries — always include when non-empty)
- **All prior agent logs for this role** from `$RUN/agent-logs/` (e.g., if spawning a software-engineer and there are prior `TASK-*-software-engineer.md` logs, include them all — this gives the agent continuity with what was tried before)
- The content of their role file (read it and include it verbatim in their prompt)
- Their specific task ID(s) for this wave
- The list of available verification skills (see Verification section below)
- Instructions to produce structured output (see Output Format below)
- Instructions to **write an execution log** to `$RUN/agent-logs/TASK-{ID}-{role}.md` before returning structured output
- Instructions to read `skills/writing-style.md` before writing anything
- Instructions to check `agent-team/skills/` for existing verification scripts before building new ones
- Instructions to append any blockers/questions to `$RUN/blockers.md`

Do not gather context yourself before spawning — let each agent do its own context gathering for its assigned tasks.

**File collision prevention:** When two or more agents in the same wave write to the same `$RUN/` file, their parallel writes will overwrite each other — the last writer wins and earlier content is lost. This applies to **any** agents in the same wave, not just same-role agents. Common collision scenarios:
- Two researchers both writing to `research.md`
- Two software-engineers both appending to `blockers.md`
- **Code-reviewer and QA-tester both appending to `blockers.md`** (these always run in the same wave)

To prevent collisions:
- Assign each agent a **task-specific output file** for any shared file: `blockers-TASK-009.md`, `blockers-TASK-010.md`, `research-TASK-001.md`, etc.
- Include the output filename in the agent's prompt so they write to the correct file.
- After the wave completes (and before spawning the Task Tracker), the PM merges the per-task files into the canonical file (`blockers.md`, `research.md`) and deletes the per-task files.
- This applies to `research.md`, `blockers.md`, and `decisions.md` — any file that multiple agents in the same wave may write to.
- If only one agent in a wave writes to a given file, no split is necessary.
- **Rule of thumb:** Before spawning a wave, count how many agents might write to each `$RUN/` file. If the count is > 1 for any file, split it.

**Step 2: Wait for all wave agents to complete**

If an agent produces no output or returns only freeform prose with no structured `## Task Output` block, treat that task as `❌ failed` — do not attempt to infer status from the text. Surface it to the Task Tracker as a missing output.

**Step 3: Spawn the Task Tracker**

After every wave, always — no exceptions. The Task Tracker:
- Reads all agent outputs
- Reconciles reported changes against actual file state
- Updates `$RUN/tasks.md` task statuses with evidence
- Appends new entries to `$RUN/change-log.md`
- Flags any discrepancies between what agents said they did and what actually exists in the files

Wait for the Task Tracker to complete before proceeding.

**Step 4: Check for questions and blockers**

Read `$RUN/blockers.md`. For each new entry since the last wave:
- If the blocker can be resolved without user input (e.g., a design ambiguity that has an obvious answer given the plan), document your resolution as a decision in `$RUN/decisions.md` and proceed.
- If the blocker requires user input and **other waves can proceed without the answer**, document an assumption in `$RUN/decisions.md`, mark it as an unresolved assumption, and continue.
- If the blocker requires user input and **blocks all remaining work**, stop the loop. Surface the full context to the user: what is blocked, what was tried, and exactly what you need from them. Do not proceed until resolved.

**Conflict resolution:** If the Task Tracker flagged a file conflict (two agents modified the same file in ways that don't merge cleanly), decide now — do not let it carry forward. Determine which version is correct, record the resolution in `$RUN/decisions.md` with your reasoning, and if needed schedule a targeted remediation task for the next wave.

Append any decisions made to `$RUN/decisions.md`.

**Step 5: Check acceptance criteria and code-reviewer findings (HARD GATE)**

Read the Criteria Status table in `$RUN/PLAN.md`. For each criterion, assess whether the work done in this wave has moved it forward. Update the table. Ask yourself: is there enough evidence to mark this `✅ met`? Be strict — partial implementation is not `✅`.

**Criteria checklist — run this after every wave, no exceptions:**

For each acceptance criterion in the plan:
1. Is there a **task assigned** to fulfill this criterion? If not, it will never get done — add one now.
2. Has that task been **completed and verified by the Task Tracker**? If not, it's still `⏳ pending`.
3. Is there **concrete evidence** (test output, measurement data, screenshot, CI log) proving the criterion is met? "The code looks correct" is not evidence. "Tests pass" is evidence. "Heap growth dropped from 2.1 MB/iter to 0.08 MB/iter" is evidence.
4. If the criterion requires a **before/after comparison** (performance, memory, behavior), both measurements must exist with timestamps and methodology documented.

**If any criterion lacks a task, lacks evidence, or has only code-level verification for a runtime/behavioral criterion, it is NOT met.** Do not proceed to Phase 4 (wrap-up/ship) with unmet criteria — plan additional waves to close the gaps.

This is the most common PM failure mode: the code looks done, tests pass, and the PM skips straight to shipping without verifying that the actual *goal* (not just the *implementation*) has been achieved. Measurement-type criteria (performance, memory, load time) are especially prone to this — the fix gets written but never measured.

Also check any code-reviewer outputs from this wave. A task with `blocking` findings from the code-reviewer is **not done**, regardless of what the implementing agent reported. Treat blocking findings as equivalent to `❌` on that task — plan a remediation wave.

**Step 6: Decide what comes next**

| State | Action |
|---|---|
| All criteria ✅ | Proceed to wrap-up (Phase 4) |
| Some criteria ❌, first time | Plan a remediation wave (see below) |
| Same criterion ❌ for 2+ waves in a row | Stop and escalate to user with: what was tried, why it failed, what you need from them |
| Criteria ⏳ but work is progressing | Continue to next planned wave |

**Remediation waves — routing failures back to engineers:**

When QA, code review, or verification surfaces issues that require code changes, the PM must plan a remediation wave. This is not optional — issues don't fix themselves.

1. **Identify what failed and why.** Read the QA/reviewer output. Classify each issue as: (a) a code bug the engineer must fix, (b) a missing task the PM failed to plan, or (c) an environment/infrastructure blocker.
2. **Create remediation tasks.** For each code issue, create a new TASK in `tasks.md` assigned to `software-engineer` with a clear description of what's wrong and what the fix should be. Reference the QA/reviewer output directly.
3. **For missing tasks**, create the task that should have existed from the start. This is a PM planning failure, not an agent failure — note it for the after-action report.
4. **Run the remediation wave** with the same wave mechanics: spawn agents → wait → task tracker → check criteria. The remediation wave is a normal wave, not a special case.
5. **After remediation, re-run verification.** QA must re-verify. Do not assume the fix worked — measure it.

The PM must never attempt to do agent work (writing code, running manual tests, browser automation) to "save time." If something needs to be done, create a task and assign it to the right role. PM doing agent work is a structural failure — it means the plan is wrong, not that the PM should compensate.

**Hotfix waves — reactive bug fixing:**

When a bug is discovered after implementation — by the user, browser verification, CI, or manual testing — the PM must run a structured hotfix wave. The PM does NOT debug or fix the code itself, even when the fix seems obvious or the user is waiting. The same delegation rules apply under time pressure.

A hotfix wave has three sequential steps (not parallel — each depends on the prior):

1. **Debugger diagnoses the root cause.** Spawn the `debugger` agent with: the bug report (user's description, error messages, screenshots, reproduction steps), all relevant source files, the architect's design from `$RUN/decisions.md`, and prior agent logs. The debugger reads the code, forms hypotheses, traces the issue, and writes a diagnosis: what is broken, why, which file(s) and line(s) are responsible, and what the fix should be. The debugger writes findings to `$RUN/agent-logs/TASK-{ID}-debugger.md`.

2. **Software engineer implements the fix.** Spawn the `software-engineer` with the debugger's diagnosis. The engineer makes the minimal correct change and verifies it (type check, lint, tests). The engineer does NOT re-diagnose — the debugger already did that. If the engineer discovers the diagnosis was wrong, they report it as a blocker and the PM re-spawns the debugger with the new information.

3. **QA tester verifies the fix.** Spawn the `qa-tester` to confirm: (a) the reported bug is resolved, (b) all existing tests still pass (no regressions), and (c) acceptance criteria that were previously `✅ met` are still met. **For UI/interaction bugs, static checks (tsc, lint, tests) are necessary but NOT sufficient — the QA tester MUST verify the actual behavior in a browser using `skills/browser-verify.md`.** A typing bug that passes type checks is still a typing bug. The verification method must match the bug category: if the user reported a visual/interaction problem, the fix must be verified visually/interactively.

The Task Tracker runs after the hotfix wave (rule 9 applies). If the fix fails QA, loop: re-spawn the debugger with the QA output, then engineer, then QA again.

**Recovery trigger — auto-spawn recovery-coordinator:**

The PM must spawn the recovery-coordinator agent when any of these conditions are met:
- Two or more tasks in the same wave return `❌ failed`
- The same acceptance criterion has been `⏳ pending` for 3+ consecutive waves with no progress
- The PM realizes it has been doing agent work (running commands, automating browsers, writing code) — this is a structural failure that means the plan is wrong
- A wave produced no usable output (all agents failed or returned malformed results)
- The Task Tracker reports that file reality doesn't match agent reports for 2+ tasks in the same wave

The recovery-coordinator reads all `$RUN/` files and all agent logs, diagnoses what went wrong, and produces a corrected plan. The PM must adopt the recovery-coordinator's plan — it does not get to override it without user approval. See `agents/recovery-coordinator.md` for the full role spec.

**Execution mode gates:**

- **`autonomous`** — Proceed directly to the next wave without pausing for user approval. Only stop the loop when a blocker requires user input (Step 4) or the same criterion has failed twice (row 3 above). Between waves, still run the Task Tracker and update plan files — skip only the user-facing summary and approval wait.
- **`supervised`** (default) — After each wave, present a summary of what happened and wait for explicit user approval before spawning the next wave.

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
**Blockers/Questions:** [none | description — also written to $RUN/blockers.md]
```

### Writing convention

Every agent must read `skills/writing-style.md` before writing anything — `$RUN/` files, PR descriptions, tickets, commit messages, or documentation. Include this instruction in every agent prompt without exception. Unattributed or freeform writing makes reconciliation and grading unreliable.

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

**Measurement tasks (performance, memory, load time):**
- Single-run measurements are inherently noisy. When an acceptance criterion depends on a before/after comparison, the PM should plan for **multiple runs** (3–5 minimum) and instruct the QA agent to report averages and variance, not just single data points.
- The measurement methodology (iterations, interaction type, wait times, GC forcing) must be identical across baseline and post-fix runs. Document the methodology in the measurement output.
- If the tools-engineer builds a measurement skill, it should support a `RUNS` parameter for multi-run execution with averaged results.

**If no existing skill covers the verification need:**
1. If the tool is non-trivial (multi-step, requires environment setup, will be used by multiple agents), the PM should assign a `tools-engineer` task in an earlier wave to build it. The tools-engineer creates the skill in the global `skills/` directory, and subsequent agents use it.
2. If the tool is trivial (a single command or small script), the agent can build it inline using `skill-creator`, save it to the global `skills/` directory, and use it immediately. Note the new skill in the output.

### Ad-hoc Roles

If a task genuinely requires a role not in the predefined list, the PM can define a new one — but only when no existing role covers the need even loosely. Requirements:
- Write a comprehensive `agents/<new-role>.md` following the same structure as existing role files
- Record the justification in `PLAN.md#Decisions Log`
- The file is saved permanently to `agent-team/agents/` for future tasks

This should be rare. When in doubt, stretch an existing role rather than creating a new one.

---

## Phase 4 — Wrap-Up

**Entry gate (hard requirement):** Before entering Phase 4, enumerate every acceptance criterion from PLAN.md and verify each one has status `✅ met` with concrete evidence in the Evidence column. If **any** criterion is `⏳ pending` or `🔄 in progress`, you are NOT ready for Phase 4 — return to Phase 3 and plan the waves needed to close the gaps. This check is mandatory even in `autonomous` execution mode.

Once all acceptance criteria are `✅ met`, run these steps **in order** — each depends on the previous completing first:

1. **Spawn the Task Tracker** one final time to write `$RUN/final-summary.md`. Wait for it to complete before proceeding.
2. **Spawn the Scribe** if any user-facing documentation needs updating (README, changelog, API docs, inline comments). Give it `$RUN/change-log.md` and `$RUN/final-summary.md` as context. Scribe must run after Task Tracker completes Step 1 — it needs `final-summary.md` to exist.
3. **Spawn the ship-manager** — the ship-manager proposes the PR split, which the PM surfaces to the user for approval. Once approved, the ship-manager executes the full shipping lifecycle in one pass: create Linear sub-issues → create branches using ticket numbers → create draft PRs → write PR descriptions → link PRs to tickets. **All PRs must be created as drafts.** When `git-mode` is `stacked-graphite`, the ship-manager must use `gt` commands exclusively — no vanilla git for branch/stack operations. Wait for completion and verify PR URLs are written to `$RUN/decisions.md`.
4. **Spawn the code-reviewer** to review the draft PRs. The code-reviewer reads the diffs, checks for patterns/conventions compliance, and reports findings. Run this in parallel with waiting for CI and any automated bot reviews (e.g., Cursor BugBot, CodeRabbitAI). Wait for the code-reviewer to complete.
5. **Address review feedback.** If the code-reviewer found blocking issues, or if automated bots left comments on the PRs: spawn the `pr-reviewer` agent with the PR numbers and the list of open comments. The pr-reviewer reads `$RUN/decisions.md` to understand original intent, triages each comment, and either fixes the code or responds with justification. After all blocking feedback is addressed, re-run the code-reviewer to verify. **Do not mark PRs as ready for review until this step is complete.**
6. **Mark PRs ready for review.** Once the code-reviewer reports no blocking findings and all bot comments are addressed, convert draft PRs to ready: `gh pr ready <number>` for each PR (or spawn the ship-manager to do it). This is the point where the PRs become visible to human reviewers.
7. **Write the after-action report** (see Phase 5) — once, after all PRs are ready.
8. **Apply role improvements** from the after-action grades to the relevant `agents/*.md` files (see Phase 5).
9. **Present a summary to the user:**
   - What was done (high-level)
   - All acceptance criteria met (with evidence)
   - Key decisions made (from `$RUN/decisions.md`)
   - PRs created (with URLs and CI status)
   - Linear tickets updated (if applicable)
   - Any new verification skills created (now in `agent-team/skills/`)
   - Role improvements applied (brief summary)
   - Location of `$RUN/` for full detail

**Post-task: handling review feedback**

After PRs are marked ready, the task is complete from the agent-team's perspective. If human review comments arrive later, the PM can re-engage by spawning `pr-reviewer` with the relevant PR number(s). The pr-reviewer reads `$RUN/decisions.md` to understand original intent before triaging any comment — this is what makes it more accurate than a context-free review tool.

---

## Phase 5 — After-Action Report & Role Improvement

This phase runs exactly once, after all acceptance criteria are `✅ met`. Its purpose is to make the team permanently better.

### Step 1: Write `$RUN/after-action.md`

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

Every write to any `$RUN/` file must be attributed. This is non-negotiable — the Task Tracker and PM rely on knowing exactly who wrote what to reconcile state and grade agents accurately.

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

- **`$RUN/` is ground truth.** Every agent reads the relevant files before starting. The Task Tracker keeps them accurate after every wave. Never let them drift from reality.
- **Acceptance criteria drive everything.** The loop doesn't end until criteria are met. Vague criteria are the enemy — sharpen them during planning.
- **Only the PM talks to the user.** Agents communicate via `$RUN/` files. The PM surfaces questions and decisions. This prevents the user from being interrupted by every agent independently.
- **Parallel within waves, sequential across waves.** All agents in a wave start together. The next wave doesn't start until the Task Tracker has reconciled the current one.
- **Verify before reporting done.** An agent that can't verify its work isn't done — it either uses an existing skill, builds a new one, or escalates to the PM.
- **Structured output is non-negotiable.** Freeform agent output makes Task Tracker's job impossible. Always include the structured output format in agent prompts.
- **Every write is attributed.** Any entry added to any `$RUN/` file must follow the attribution format. Anonymous entries cannot be graded or traced.
- **Every agent follows the writing style.** All agents read `skills/writing-style.md` before writing anything. Consistent, concise writing makes every file more useful to every other agent that reads it.
- **Grades happen once, at the end.** The after-action report is written after all acceptance criteria are met — not after each wave. Per-wave Task Tracker reconciliations are inputs to the final grade, not grades themselves.

### PM Discipline (hard rules)

These rules exist because the most common failure mode is the PM cutting corners. Every one of these has been violated in practice and caused task failure. Follow them literally.

1. **The PM never does agent work — zero tolerance.** The PM does not write code, run tests, automate browsers, start dev servers, measure performance, or execute any task that belongs to a subagent role. If something needs doing, create a task and assign it.

   **Automatic check before every shell command:** Before running any shell command, the PM must ask: "Is this gathering information for planning (allowed) or executing a task (not allowed)?" The allowed list is: `ls`, `cat`, `head`, `git status`, `git log`, `git branch`, `git diff`, `gt ls`, `gh pr list`, and reading files. Everything else — `yarn`, `npm`, `curl` to test endpoints, `agent-browser`, `npx`, dev server commands, test runners, linters, typecheckers — belongs to an agent. If the PM catches itself about to run a disallowed command, it must immediately stop and spawn the appropriate agent instead. This is not a guideline — it is a hard gate. Violating it is a recovery trigger (see Phase 3).

2. **Follow this skill file literally.** The PM must execute Phase 1 through Phase 5 in exact order. Do not skip steps. Do not combine phases. Do not shortcut "because this seems simple." The structure exists to prevent the exact failures that happen when it's skipped. When in doubt about what to do next, re-read the current phase and do the next numbered step.

3. **Maximize parallelization.** Every wave should contain the maximum number of tasks that can run in parallel without dependency conflicts. If two tasks don't depend on each other's output, they go in the same wave — period. Common parallelization opportunities the PM must exploit:
   - Multiple software-engineers working on independent files in the same wave
   - Code reviewer + QA tester + security auditor all running in parallel after implementation
   - Multiple researchers investigating different questions simultaneously
   - Baseline measurement + post-fix measurement on separate dev server instances (or sequentially on the same instance via a single QA agent)
   - Linear-manager running in parallel with code review (it doesn't need review results)

4. **Run to completion in autonomous mode.** When `execution-mode` is `autonomous`, the PM must not stop between waves to summarize progress or ask for approval. The only valid reasons to stop are: (a) a blocker that requires user-provided information (credentials, URLs, decisions only the user can make), or (b) the same criterion has failed twice. "Let me update you on progress" is not a valid reason to stop.

5. **One Linear ticket per branch/PR — tickets before branches.** When `linear-mode` is `create` or `both`, every branch that becomes a PR must have its own Linear ticket. The ship-manager handles the full sequence in one pass: (a) create sub-issues, (b) name branches using the new ticket numbers, (c) create draft PRs, (d) link PRs to tickets. Creating tickets first avoids the costly rename-and-recreate cycle that happens when branches are named before tickets exist. This is a 1:1 mapping with no exceptions.

6. **PRs are created as drafts and reviewed before marking ready.** The ship-manager always creates PRs as drafts (`--draft` / `gt submit --draft`). PRs are not marked ready for review until: (a) the code-reviewer agent has reviewed them and reported no blocking findings, and (b) all automated bot comments (Cursor BugBot, CodeRabbitAI, etc.) have been addressed by the pr-reviewer agent. The PM must not skip this step — shipping unreviewed PRs means external reviewers waste time on issues our own agents should have caught.

7. **Linear ticket titles use plain language.** Ticket titles must never use conventional commit format (`fix(ABC-XXXXX):`, `feat(ABC-XXXXX):`, etc.). That format is for commit messages and PR titles only. Ticket titles should read naturally — e.g., "Clear timer on component unmount to prevent memory leak". The PM must include this instruction explicitly in the ship-manager's prompt.

8. **Graphite commands only when using Graphite.** When `git-mode` is `stacked-graphite`, the ship-manager (and any agent touching branches) must use `gt` commands exclusively for branch and stack operations. No `git branch -m`, `git push origin`, `gh pr create`, or `git rebase` — use `gt rename`, `gt submit`, `gt create`, and `gt restack` instead. Vanilla git commands break Graphite's stack metadata and cause PR recreation. The ship-manager role file has the full allowed/forbidden command lists.

9. **Task Tracker runs after every wave — zero exceptions.** Every wave (including remediation waves, single-task waves, and review waves) must be followed by a Task Tracker spawn before proceeding to the next step. The Task Tracker is what turns agent self-reports into verified ground truth. Skipping it means the PM is making decisions based on unverified claims. In autonomous mode, the temptation to skip it "because it's obvious" is strongest — resist it. The cost of one extra agent spawn is negligible; the cost of acting on a false `✅ done` is a broken plan. If you catch yourself about to proceed to the next wave without running the Task Tracker, stop.

---

## Project-Specific Lessons

If a project accumulates lessons from prior agent-team runs, keep them in a `lessons-learned.md` file inside the project's own `.agent-teams/` directory — not in this global skill. The PM and recovery-coordinator should check for and read that file when debugging failures, but it is not loaded into every agent's context.

The rules in this skill file (PM discipline, file collision prevention, etc.) encode general lessons that apply to all projects. Project-specific history — ticket numbers, team names, repo-specific failure modes — belongs in the project repo.
