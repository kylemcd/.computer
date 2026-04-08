# Global Agent Rules

At the start of every session, check for an `AGENTS.md` file in the working directory and read it if present. It contains repo-specific conventions, structure, and rules that override defaults. If no `AGENTS.md` exists, continue normally.

## File Search

**Use fff MCP for all file search.** Use `fff_find_files` instead of Glob, `fff_grep` instead of Grep, and `fff_multi_grep` for multi-pattern searches. Never use bash `grep`, `find`, or `rg` to search the codebase — always use the fff MCP tools.
