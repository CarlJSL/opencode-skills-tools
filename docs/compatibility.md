# Agent compatibility

Which coding agents load the skills in this repository, from which
directories, and which frontmatter fields they honor. Every row below was
checked against the official documentation listed in [Sources](#sources) on
2026-11-07. Agents change quickly: re-check the sources before relying on a
path that matters.

## Summary

| Agent | Loads `SKILL.md` folders | User-level directories | Project-level directories | `install.sh --agent` |
| --- | --- | --- | --- | --- |
| Claude Code | Verified | `~/.claude/skills/` | `.claude/skills/` | `claude` |
| OpenCode | Verified | `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | `.opencode/skills/`, `.claude/skills/`, `.agents/skills/` | `opencode` (or `claude` / `codex`) |
| Codex CLI | Verified | `$HOME/.agents/skills/` (admin: `/etc/codex/skills`) | `.agents/skills/` in the launch directory, its parent inside a Git repo, and the repo root | `codex` |
| Gemini CLI | Verified | `~/.gemini/skills/`, `~/.agents/skills/` | `.gemini/skills/`, `.agents/skills/` | `codex` (shared `~/.agents/skills/`) |
| Cursor | Verified | `~/.cursor/skills/`, `~/.agents/skills/`, `~/.claude/skills/`, `~/.codex/skills/` | `.cursor/skills/`, `.agents/skills/`, `.claude/skills/`, `.codex/skills/` | `claude` or `codex` |
| GitHub Copilot | Verified | `~/.copilot/skills/`, `~/.agents/skills/` | `.github/skills/`, `.claude/skills/`, `.agents/skills/` | `codex` (shared `~/.agents/skills/`) |

Notes:

- `~/.agents/skills/` (what `install.sh --agent codex` targets) is read by
  Codex CLI, OpenCode, Gemini CLI, Cursor and GitHub Copilot. Claude Code does
  not list it.
- Agents that scan several directories (OpenCode, Cursor) may see the same
  skill more than once if you install it into several of them. Prefer one
  target per agent set: `--agent claude` alone already covers Claude Code,
  OpenCode and Cursor; add `--agent codex` for Codex CLI, Gemini CLI and
  Copilot.
- Symlinked skill folders are documented as supported by Claude Code and
  Codex CLI. OpenCode, Gemini CLI, Cursor and Copilot do not mention symlinks
  in the pages below; they are expected to work but are **not verified**.
- The Gemini CLI page states that Gemini CLI was replaced by Antigravity CLI
  on 2026-06-18 for unpaid-tier and Google One users. Antigravity CLI was not
  checked.
- GitHub Copilot support varies by surface (Copilot CLI, cloud agent, IDE
  agent modes). Personal skills are not guaranteed to reach cloud-running
  agents.

## Frontmatter fields

The [Agent Skills specification](https://agentskills.io/specification)
defines `name` (required, 1-64 chars, lowercase letters, digits and single
hyphens, must match the folder name), `description` (required, 1-1024 chars),
and the optional `license`, `compatibility`, `metadata` (string-to-string map)
and `allowed-tools` (experimental).

| Field | Claude Code | OpenCode | Codex CLI | Gemini CLI | Cursor | Copilot |
| --- | --- | --- | --- | --- | --- | --- |
| `name` | Optional, defaults to folder name | Optional display label; ID comes from the path | Required | Documented, should match folder | Required, must match folder | Required |
| `description` | Recommended; capped with `when_to_use` at 1,536 chars | Needed to be advertised to the model | Required | Documented, drives activation | Required | Required |
| `license` | Accepted, not acted on | Accepted, not interpreted | Not documented | Not documented | Not documented | Optional |
| `compatibility` | Accepted, not acted on | Accepted, not interpreted | Not documented | Not documented | Not documented | Not documented |
| `metadata` | Free-form map | Only `metadata.opencode/autoinvoke` is interpreted | Not documented (uses `agents/openai.yaml`) | Not documented | Arbitrary key-value pairs | Not documented |
| `allowed-tools` | Pre-approves tools | Not documented | Not documented | Not documented | Not documented | Pre-approves tools |

Agent-specific fields seen in the docs (do not use them in this repository's
skills, see [AGENTS.md](../AGENTS.md)): Claude Code `when_to_use`,
`disable-model-invocation`, `paths`, `context`, `model`, `hooks` and others;
Cursor `paths`, `disable-model-invocation`, `icon`, `color`; OpenCode
`disable-model-invocation`.

**Portable contract used here:** `name` + `description` (both required),
plus optional `license` and `metadata` (`author`, `version`). These are
all Agent Skills spec fields. Where an agent's docs do not mention `license`
or `metadata`, how it treats them is **not verified**; none of the pages
above say unknown fields are rejected.

## Instruction files

- Claude Code reads `CLAUDE.md`; it reads `AGENTS.md` only when no
  `CLAUDE.md` exists, and supports `@path` imports. This repository keeps
  `AGENTS.md` as the single source and a `CLAUDE.md` that imports it with
  `@AGENTS.md` (documented pattern).
- `AGENTS.md` loading by the other agents was not checked for this document.

## Sources

Fetched 2026-11-07.

- Claude Code, skills: https://code.claude.com/docs/en/skills
- Claude Code, memory (`CLAUDE.md`, `@path` imports, `AGENTS.md`): https://code.claude.com/docs/en/memory
- OpenCode, skills: https://opencode.ai/docs/skills/
- Codex, skills: https://learn.chatgpt.com/docs/build-skills (redirected from https://developers.openai.com/codex/skills)
- Gemini CLI, skills: https://geminicli.com/docs/cli/skills
- Gemini CLI, creating skills: https://geminicli.com/docs/cli/creating-skills
- Cursor, skills: https://cursor.com/docs/context/skills
- GitHub Copilot, about agent skills: https://docs.github.com/en/copilot/concepts/agents/about-agent-skills
- GitHub Copilot, creating skills: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-skills
- Agent Skills specification: https://agentskills.io/specification
