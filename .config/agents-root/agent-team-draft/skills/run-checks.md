# Run Checks

How to find and run a project's tests, build, lint, and type checks — regardless of language or toolchain.

Use this skill for any backend or logic task verification. For frontend tasks, use `skills/browser-verify.md` instead (or in addition).

---

## Discovery order

Check in this sequence and stop at the first match:

1. **`AGENTS.md` or `CLAUDE.md`** — look for a "Commands", "Checks", or "Development" section. This is the canonical source — follow it exactly.
2. **`package.json` scripts** — look for `test`, `build`, `lint`, `typecheck`, `check`, `ci`.
3. **`Makefile` or `justfile`** — look for `test`, `build`, `lint`, `check`, `ci` targets.
4. **Language config files** — `pyproject.toml` (pytest, ruff), `Cargo.toml` (cargo), `go.mod` (go test), `Gemfile` (rspec).

If none of these exist, look for test files near the changed code (`**/*.test.*`, `**/*.spec.*`, `**/test_*.py`) and run the relevant test runner directly.

---

## Run order

Always run in this sequence — cheap errors first:

1. Type check
2. Lint
3. Test
4. Build

Stop on the first failure and fix it before proceeding. Cascading errors from a type failure will pollute lint and test output.

---

## Quick reference by language

| Language | Type check | Lint | Test | Build |
|----------|-----------|------|------|-------|
| TypeScript | `npx tsc --noEmit` | `npx eslint .` or `npx biome check .` | `npx jest` or `npx vitest run` | `npx tsc` or `npx vite build` |
| JavaScript | — | `npx eslint .` | `npx jest` or `npx vitest run` | `npx vite build` or `npx esbuild` |
| Python | `mypy .` | `ruff check .` | `pytest` | `python -m build` |
| Rust | `cargo check` | `cargo clippy -- -D warnings` | `cargo test` | `cargo build --release` |
| Go | `go vet ./...` | `golangci-lint run` | `go test ./...` | `go build ./...` |
| Ruby | `steep check` | `rubocop` | `bundle exec rspec` | — |

Prefer the project's own script aliases (`npm test`, `npm run typecheck`) over direct invocations — they may include project-specific flags.

---

## Running only changed files

For speed during iterative development:

- **Jest**: `npx jest --testPathPattern="path/to/file"`
- **Vitest**: `npx vitest run path/to/file`
- **pytest**: `pytest path/to/test_file.py`
- **Cargo**: `cargo test test_function_name`
- **Go**: `go test ./path/to/package/...`
- **RSpec**: `bundle exec rspec spec/path/to/file_spec.rb`

---

## Interpreting failures

**TypeScript** — errors cascade. The first `error TS` line is usually causal; the rest are often consequences. Fix the first error and re-run before addressing others.

**Rust** — read `cargo check` output bottom-up. Rust prints the root error last, with `^` pointing at the exact location.

**ESLint/Biome** — `error` lines block; `warning` lines don't. Fix errors first. Warnings are informational unless the project treats them as errors (`--max-warnings 0`).

**pytest** — each `FAILED` line is independent. The `E` prefixed lines below each failure contain the assertion detail. Fix failures in order — they're rarely related.

**Jest/Vitest** — each `●` block is one test failure with full stack trace. The first line of the stack trace points to the failing assertion.

**Go** — each `--- FAIL:` line is independent. The `Error:` or `got/want` lines below it contain the detail.

---

## Common issues

**"Command not found"** — the tool isn't installed globally. Use `npx <tool>` for Node.js tools, or check if there's a project script (`npm run lint`) that handles the path.

**Tests pass locally but fail in CI** — check for environment variable differences, missing test fixtures, or timing-sensitive tests. Read the CI log with `gh run view --log-failed`.

**Build succeeds but type check fails** — `tsc` with `noEmit` is stricter than the bundler. Fix type errors — they indicate real issues even if the build passes.

**Lint fails on unchanged files** — another agent or a prior wave may have introduced a violation. Check `.agent-team/change-log.md` for recent changes to the flagged files.
