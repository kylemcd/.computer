---
name: write-pr-description
description: >
  Composes a pull request description based on git history and the repo's PR template. Use this
  skill whenever the user asks to write, draft, generate, or create a PR description or PR body,
  even if they say "write up what this PR does", "help me describe this PR", "what should my
  PR description say", or anything that implies composing the text that would go into a GitHub
  pull request. This skill gathers context from git (log, diff, stat) and any PR template in
  the repo, then produces a tight, direct description in the style of a teammate explaining
  their work. It only produces the description text; it does not post anything or open GitHub.
---

# Write PR Description

Your job is to draft a pull request description based on what changed in the code. The output
is text only — you are not posting it, not opening GitHub, not creating the PR. Just the words.

## Gathering context

Run these in the repo to understand what's going on:

```bash
# What commits are in this branch vs. the base (usually main or master)
git log main..HEAD --oneline

# Full diffs - what actually changed
git diff main..HEAD

# File-level summary - scope and shape of the change
git diff --stat main..HEAD
```

If the base branch isn't obvious, check `git remote show origin` or try `master` if `main`
doesn't exist. If you're on main already (no divergence), fall back to `git log -10 --oneline`
and `git diff HEAD~1` to get at least the most recent commit.

Also check for a PR template:

```bash
ls .github/pull_request_template.md 2>/dev/null || ls .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

If a template exists, read it. Use its headings and structure as the skeleton for your output.
Don't ignore sections — fill them in or explicitly note "N/A" if a section truly doesn't apply.

Also check if a PR already exists for this branch and read the current description:

```bash
gh pr view --json body --jq '.body' 2>/dev/null
```

If a description already exists, use it as the starting point. Preserve any sections that are
still accurate, update sections that are stale, and add anything new from the diff that isn't
covered. Don't discard human-written content — only replace what's actually wrong or missing.

## Writing the description

**Tone**: Talk like you're telling a teammate what you did. Not formal, not padded. Direct.

**Format**: Prefer bullets over prose. Short bullets. One idea per bullet.

**Length**: Hit the key things. Don't pad. If a section would just be filler, skip it.

**Content**: Focus on:
- What changed and why (the "so what")
- Any gotchas, tradeoffs, or things a reviewer should know about
- How to test it, if that's relevant and non-obvious

**What to avoid**:
- Filler openers like "This PR..." or "In this change..."
- Over-explaining things that are obvious from the diff
- Restating the commit messages verbatim
- Vague summary sentences that could apply to any PR

## Style rules

Apply these consistently throughout the description:

- **Every word earns its place.** If removing a word doesn't change the meaning, remove it.
- **No adverbs.** "Significantly improved" becomes "improved"; "simply removes" becomes "removes".
- **No exclamation marks.**
- **Sentence case for headings** — "What changed" not "What Changed".
- **List items end with a period.**
- **No rhetorical questions.**
- **Oxford comma** — "X, Y, and Z" not "X, Y and Z".
- **"Enable" not "allow"** — "enables users to export" not "allows users to export".

## If there's a template

Follow it. Use the template's headings. Fill in each section based on the diff context.
If a section is a checklist, check the boxes that apply based on what you know.

## If there's no template

Use a simple structure:

```
## What changed

[What changed, in bullets, each ending with a period.]

## Why

[Why this was needed / what problem it solves.]

## Notes

[Anything a reviewer should know: tradeoffs, follow-up work, how to test, etc. Omit if nothing worth noting.]
```

Keep it short. Most PRs don't need more than 10-15 lines total.

## Output

Just output the PR description as markdown. Don't wrap it in a code block. Don't add preamble
like "Here's the PR description:" — just give the description itself so the user can copy it
directly.
