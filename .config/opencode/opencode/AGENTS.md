# Global Agent Rules

At the start of every session, check for an `AGENTS.md` file in the working directory and read it if present. It contains repo-specific conventions, structure, and rules that override defaults. If no `AGENTS.md` exists, continue normally.

## File Search

**Use fff MCP for all file search.** Prefer `fff_find_files` over Glob, `fff_grep` over Grep, and `fff_multi_grep` over multi-pattern Grep. Do not use bash `grep`, `find`, or `rg` for searching the codebase.
