# Writing Style

Universal voice and format guide. Every agent reads this before writing anything — internal `.agent-team/` files, PR descriptions, tickets, documentation, or commit messages. No exceptions.

---

## Tone

**Direct and factual.** Write as a precise colleague explaining work, not a journalist or a document author.

- No filler or throat-clearing ("This PR aims to...", "In order to...", "It is worth noting that...").
- Never start a sentence with "I" — restructure it.
- No adverbs: "quickly", "simply", "easily", "just", "clearly" add nothing. Cut them.
- No exclamation marks anywhere.
- No hedging: "it seems like", "this might be", "potentially", "arguably". If uncertain, say so directly: "Unknown — needs investigation."
- No preamble before the answer. Start with the information.

---

## Format

- **Sentence case** for all headings: "What changed" not "What Changed".
- **Bullet points** for lists of 3+ items. Each bullet ends with a period.
- **Oxford comma**: "tests, linting, and build" not "tests, linting and build".
- **Backticks** for all code, file paths, function names, identifiers, and command names: `auth.ts`, `validateToken()`, `npm run build`.
- **Tables** for comparisons or structured data with 3+ rows.
- **Bold** for emphasis sparingly — one or two terms per section at most. Not for decoration.

---

## Length by output type

| Output | Target | Rule |
|--------|--------|------|
| Blocker entry | 1–3 sentences | Problem stated, what was tried, what is needed. |
| Change-log entry | 1 sentence per file | What changed and why — not how. |
| Decision entry | 3 sentences max | Problem, decision, rationale. |
| Commit message subject | ≤72 chars | Imperative mood: "Add auth middleware" not "Added auth middleware". |
| Commit message body | Optional | Why the change was made, not what — the diff shows the what. |
| PR description | See pr-description.md | Stack context + what + why. Readable in under 2 minutes. |
| Ticket description | 2–4 sentences | Problem statement and acceptance criteria only. No implementation detail. |
| Inline code comment | 1 sentence | Explain why, not what. Only where non-obvious. |
| README section | As short as accurate allows | Context → usage → reference. No prose padding. |
| Blockers.md entry | 2–3 sentences | What is blocked, root cause if known, what is needed to unblock. |

---

## What to avoid

**Restating the task title.** If the task is "Add JWT middleware", don't write "This task implements JWT middleware." Start with the substance.

**Documenting the obvious.** A function named `calculateTotal` that multiplies price by quantity does not need a comment explaining that it multiplies price by quantity.

**Passive voice when the actor matters.** "Updated the auth middleware to reject expired tokens" not "The auth middleware was updated." The actor — the agent, the commit, the decision — is part of the record.

**Emoji in professional output.** No emoji in `.agent-team/` files, PR descriptions, commit messages, or tickets. Emoji are acceptable in user-facing summaries only if the project already uses them consistently.

**Vague blockers.** "It doesn't work" is not a blocker entry. "The `refreshToken` function throws a `TypeError` when `user.sessions` is undefined — this happens when a user has no active sessions. The handler needs a null check before accessing `sessions[0]`." is a blocker entry.

**Implementation detail in tickets.** Ticket descriptions state the problem and the criteria for done. How it gets implemented is not the ticket's concern.

---

## Commit message format

```
<type>: <subject in imperative mood, ≤72 chars>

<optional body: why this change was made, one short paragraph>
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `security`.

Examples:
- `feat: add JWT refresh token rotation`
- `fix: handle null sessions in refreshToken handler`
- `refactor: extract auth middleware into separate module`
- `docs: document new /auth/refresh endpoint`

---

## Applies to

All agents without exception: task-tracker (change-log and decisions entries), software-engineer (commit messages, blockers), debugger (blocker entries, decisions), architect (design decisions), code-reviewer (findings), scribe (all documentation), git-manager (commit messages, PR descriptions), linear-manager (ticket descriptions), pr-reviewer (triage reasoning, reply comments), and the PM (PLAN.md, decisions.md, user-facing summaries).
