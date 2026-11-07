# Agent skills

Reusable skills for AI coding agents. A skill is a folder with a `SKILL.md`
file: YAML frontmatter (`name`, `description`) followed by Markdown
instructions. The agent reads the name and description at startup and loads
the full instructions only when a task matches. The format follows the
[Agent Skills specification](https://agentskills.io/specification).

## Supported agents

Verified against official documentation on 2026-11-07. Details, frontmatter
support and sources are in [docs/compatibility.md](docs/compatibility.md).

| Agent | User-level directory used by `install.sh` | `--agent` |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | `claude` |
| OpenCode | `~/.config/opencode/skills/` (also reads `~/.claude/skills/` and `~/.agents/skills/`) | `opencode` |
| Codex CLI | `~/.agents/skills/` | `codex` |
| Gemini CLI | `~/.agents/skills/` (alias of `~/.gemini/skills/`) | `codex` |
| Cursor | `~/.claude/skills/` or `~/.agents/skills/` | `claude` or `codex` |
| GitHub Copilot | `~/.agents/skills/` | `codex` |

Agents that scan several directories may list a skill twice if you install it
into more than one of them. `--agent claude` plus `--agent codex` covers every
agent above.

## Install

```sh
git clone https://github.com/CarlJSL/opencode-skills-tools.git
cd opencode-skills-tools
./install.sh --agent claude --dry-run   # preview
./install.sh --agent claude             # link into ~/.claude/skills
./install.sh --agent codex              # link into ~/.agents/skills
```

The repository name still says `opencode`; it is expected to be renamed. If it
is, update your remote with `git remote set-url origin <new-url>`.

`install.sh` (POSIX sh, no sudo) symlinks each `skills/<name>/` folder:

| Option | Effect |
| --- | --- |
| `--agent claude\|opencode\|codex\|all` | Target agent directories (default `claude`) |
| `--project` | Use project-level directories (`.claude/skills`, `.opencode/skills`, `.agents/skills`) under the current directory |
| `--dest DIR` | Link into `DIR` instead |
| `--dry-run` | Print the plan, change nothing |
| `--uninstall` | Remove only the symlinks that point into this repository |

It is idempotent, prints every action, and refuses (exit 1) to overwrite a
real directory or a symlink it does not own.

## Update

Skills are symlinked, so pulling updates them in place:

```sh
cd opencode-skills-tools
git pull
./install.sh --agent claude   # only needed when new skills were added
```

## Uninstall

```sh
./install.sh --agent all --uninstall
```

## Skills

| Skill | Trigger | What it needs |
| --- | --- | --- |
| [feature-creator](skills/feature-creator/SKILL.md) | "create feature", "new feature", "feature scaffold", "crear feature", "nueva feature" | A React project based on the react-template conventions (`src/features/_base/`, `src/core/lib/http-base.ts`, `useListPage`, Zod, React Query) |

## Contributing

Read [AGENTS.md](AGENTS.md) for the frontmatter contract, versioning and
writing rules. Run `sh test/install.test.sh` after changing `install.sh`.

## License

Skills declare their license in frontmatter (`feature-creator`:
Apache-2.0). The repository has no top-level LICENSE file yet.
