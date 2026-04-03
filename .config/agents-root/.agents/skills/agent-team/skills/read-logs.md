# Read Logs

How to extract signal from noisy log output. The goal is always to find the root cause — not the first error that appears, and not the loudest one, but the one that caused the others.

---

## Core principle

Most log output is noise. A single root cause typically produces many cascading errors. Find the origin — fix that, and the others usually disappear.

---

## Dev server logs

**Vite:**
- `[vite] error` — module resolution failure or plugin error. The line after it names the file.
- `[vite] Internal server error` — usually a transform error. Full stack trace follows.
- `[hmr]` errors — hot module replacement failure. Often caused by a syntax error in a changed file.

**Next.js:**
- `error` prefixed lines (red in terminal) are build or runtime errors.
- `Failed to compile` block — TypeScript or webpack errors. The file path and line number follow.
- API route errors appear in the server terminal, not the browser console.

**webpack-dev-server:**
- `ERROR in` — compilation error with file path and line number.
- `Module not found` — import path is wrong or the module isn't installed.

**Express/Fastify/Node:**
- Unhandled exceptions print a full stack trace. The first `at` line after the error message is your entry point.
- Port conflicts: `EADDRINUSE` — another process is on that port.

---

## Test runner output

Find the root failure, not the longest output.

**Jest/Vitest:**
```
● Test suite name › test name

  Error message here
    at Object.<anonymous> (path/to/test.ts:42:5)
```
Each `●` block is independent. The line with `at Object.<anonymous>` points to the failing assertion. Fix in order — they're rarely related.

**pytest:**
```
FAILED tests/test_auth.py::test_login - AssertionError: assert 401 == 200
```
The `E` prefixed lines below each `FAILED` line contain the assertion detail. The file path and line number are in the `FAILED` line itself.

**RSpec:**
```
Failures:
  1) AuthController POST /login returns 200
     Failure/Error: expect(response.status).to eq(200)
       got: 401
```
Read the `Failures:` section only. Ignore everything above it.

**Cargo test:**
```
---- tests::test_name stdout ----
thread 'tests::test_name' panicked at 'assertion failed', src/lib.rs:42
```
The file path and line number are in the `panicked at` line.

---

## Build output

**TypeScript (`tsc`):**
```
src/auth/middleware.ts:42:5 - error TS2345: Argument of type 'string' is not assignable...
```
Format is `file:line:col - error TScode: message`. Errors cascade — the first one is usually causal. Fix it and re-run before reading others.

```bash
# Find the first TypeScript error
npx tsc --noEmit 2>&1 | grep "error TS" | head -1
```

**Rust (`cargo build`):**
Read bottom-up. Rust prints the root error last, with a `^` or `^^^` pointing at the exact problematic token. The `error[E####]` lines are root errors; `note:` and `help:` lines are supplementary.

**Go (`go build`):**
Each `./path/to/file.go:line:col: message` is independent. Unlike TypeScript, Go errors don't typically cascade — each one is a real issue.

---

## CI logs (GitHub Actions)

```bash
# View only the failed step output
gh run view <run-id> --log-failed

# Full log (can be very long)
gh run view <run-id> --log

# List recent runs on this branch
gh run list --branch $(git branch --show-current)
```

Navigation:
1. Find the failed step (marked with ✗ or `FAILED` in the step list).
2. Within that step, scan for `Error:`, `FAIL`, `error[`, `fatal:`, `##[error]`.
3. Ignore "Post" steps — they're cleanup and almost never the root cause.
4. If the failed step is "Set up job" or "Checkout", it's an infrastructure issue, not a code issue.

---

## Signal extraction patterns

```bash
# Generic: find error lines in any log file
grep -E "^(error|Error|ERROR|FAIL|fatal|Fatal)" output.log

# TypeScript errors only
grep "error TS[0-9]" output.log

# First error only (stop reading at first signal)
grep -m 1 -E "(error|Error|FAIL)" output.log

# Jest/Vitest failures only
grep "●" output.log

# Python assertion failures
grep "AssertionError\|FAILED" output.log

# Rust root errors only (not notes or help lines)
grep "^error\[" output.log
```

---

## Distinguishing "error in your code" from "error in tooling setup"

**Your code:**
- Error message references a file path inside the project
- Stack trace points to project source files
- Error message is about types, assertions, missing values, or logic

**Tooling setup:**
- Error message references `node_modules/`, a global tool path, or a config file
- "Cannot find module" for a package (not a local file)
- Version mismatch messages
- Permission errors

Tooling errors should be written to `.agent-team/blockers.md` — they often require user intervention (installing a package, fixing environment variables, updating config).
