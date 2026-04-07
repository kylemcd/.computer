# PR Description

How to write pull request descriptions. Self-contained — no external references needed.

---

## Before writing

Run these commands and read the output before writing a single word:

```bash
# What commits are in this PR
git log main..HEAD --oneline

# Which files changed and by how much
git diff --stat main..HEAD

# The full diff (skim for context — don't copy-paste it)
git diff main..HEAD
```

Check for a PR template:
```bash
ls .github/pull_request_template.md 2>/dev/null || ls .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

If a template exists, use its headings as the skeleton and fill each section with the style below. Do not add sections that aren't in the template.

---

## Format (no template)

```markdown
## Stack context
[One sentence: what the overall task is and where this PR sits in the sequence. Omit this section for a single-PR workflow.]

## What
- [Concrete change 1 — file paths and identifiers in `backticks`.]
- [Concrete change 2.]
- [Concrete change 3.]

## Why
[1–3 sentences: what prompted this work and why this approach was chosen over alternatives.]

## Notes
[Optional. Migration steps, known limitations, follow-up tickets. Omit entirely if nothing relevant.]
```

---

## For stacked PRs

The "Stack context" section is mandatory. It must answer:
- What is the overall task?
- How many PRs are in the stack?
- What position is this PR and why does this chunk of work stand alone?

Example:
```markdown
## Stack context
Part 2 of 3 in the JWT auth stack. PR 1 added the DB schema and migration. This PR implements the middleware layer. PR 3 will add the auth routes.
```

---

## Style rules

These apply without exception. Read `skills/writing-style.md` for the full guide — the most relevant rules here are:

- No adverbs: "quickly", "simply", "easily", "just". Cut them.
- No exclamation marks.
- No hedging: "this might", "potentially", "arguably".
- Sentence case headings: "What changed" not "What Changed".
- Each bullet ends with a period.
- Oxford comma.
- Code, file paths, and identifiers in backticks: `auth.ts`, `validateToken()`.
- "Enable" not "allow". "Remove" not "get rid of".
- Passive voice only when the actor genuinely doesn't matter.

---

## Length

The description should be readable in under 2 minutes. If it's longer, the PR is probably too large.

A good PR description is not a summary of the diff — the diff speaks for itself. It explains the **why**: what problem this solves, what decision was made, and what a reviewer needs to know to evaluate it correctly.

---

## What to avoid

**Restating the commit messages.** If the commits already say "Add JWT middleware" and "Add refresh token rotation", the PR description doesn't need to list those again. It should add context the commits don't have.

**Implementation detail.** "The middleware calls `jwt.verify()` with the secret from `process.env.JWT_SECRET`" is not useful in a PR description. That's visible in the diff.

**Vague "what":** "Updated auth flow" tells a reviewer nothing. "Added `requireAuth` middleware to all `/api/` routes, replacing the per-handler token checks in `users.ts`, `posts.ts`, and `comments.ts`" is useful.

**Exclamation marks.** Never.

---

## Writing PR body to a file (required for `gh` CLI)

Always write the PR body to a temp file and use `--body-file`. Shell escaping in `--body` strings will mangle markdown tables and code blocks.

```bash
# Write body to temp file
cat > /tmp/pr-body.md << 'PREOF'
## Stack context
...

## What
- ...

## Why
...
PREOF

# Create PR
gh pr create --title "feat: add JWT auth middleware" --body-file /tmp/pr-body.md

# Or edit an existing PR
gh pr edit <number> --title "feat: add JWT auth middleware" --body-file /tmp/pr-body.md
```
