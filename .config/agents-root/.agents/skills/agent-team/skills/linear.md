# Linear

How to create and update Linear issues using the Linear MCP tools available in this environment.

The Linear MCP is already configured — no setup needed. The tools are available directly as `Linear_*` function calls.

---

## Find the right team and project

```
Linear_list_teams
→ returns list of teams with IDs and names

Linear_list_projects query="project name"
→ returns matching projects with IDs

Linear_get_project query="project name or ID"
→ returns full project details including milestones
```

Always confirm the team ID and project ID before creating issues. Wrong team = issue in the wrong place.

---

## Create a parent issue for the overall task

```
Linear_save_issue:
  title:       "[task name from .agent-team/PLAN.md]"
  team:        "[team name or ID]"
  project:     "[project name or ID — optional]"
  description: "[problem statement + acceptance criteria — see ticket description format below]"
  state:       "In Progress"
  assignee:    "me"
```

Record the returned issue ID in `.agent-team/decisions.md` for reference throughout the task run.

---

## Create sub-issues per wave

```
Linear_save_issue:
  title:    "Wave N: [wave description from tasks.md]"
  team:     "[team name or ID]"
  parentId: "[parent issue ID from above]"
  state:    "In Progress"
```

Create one sub-issue per planned wave. This maps the wave structure directly to Linear so progress is visible without reading `.agent-team/` files.

---

## Update issue state as work progresses

```
Linear_save_issue:
  id:    "[issue ID]"
  state: "In Review"    ← when PRs are created
```

```
Linear_save_issue:
  id:    "[issue ID]"
  state: "Done"         ← when PRs are merged / task is complete
```

State names vary by team workflow. Use `Linear_list_issue_statuses team="[team]"` to see available states if "In Review" or "Done" don't exist.

---

## Link a PR to an issue

```
Linear_save_issue:
  id:    "[issue ID]"
  links: [{ url: "[GitHub PR URL]", title: "PR: [PR title]" }]
```

Links are append-only — existing links are never removed. Call this once per PR after the git-manager creates it.

---

## Add a completion comment

```
Linear_save_comment:
  issueId: "[issue ID]"
  body:    "[brief summary — see writing-style.md conventions]"
```

The completion comment on the parent issue should summarize what was done, reference the final summary, and link to the PRs. Keep it to 3–5 sentences.

---

## Look up existing issues

```
Linear_list_issues query="search term" state="In Progress"
Linear_list_issues assignee="me"
Linear_get_issue id="TEAM-123"
```

Use these to find existing tickets when the user provides a ticket number or says "link to the existing ticket."

---

## Ticket description format

Follow `skills/writing-style.md`. Keep it short — tickets describe the problem and criteria, not the implementation.

```markdown
## Problem
[One sentence: what needs to change and why.]

## Acceptance criteria
- [Criterion 1 — specific and verifiable.]
- [Criterion 2 — specific and verifiable.]
- [Criterion 3 — specific and verifiable.]
```

No implementation detail in the ticket body. That belongs in the PR description or commit messages. Reviewers read tickets to understand what and why — not how.

---

## Attribution

When recording Linear issue IDs or actions in `.agent-team/decisions.md`, follow the standard attribution format:

```
> **linear-manager | Wave N | [date]**
Created parent issue TEAM-123. Sub-issues TEAM-124 (Wave 1) and TEAM-125 (Wave 2) created and linked.
```
