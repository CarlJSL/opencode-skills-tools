# Contributor and agent rules

Rules for humans and coding agents that add or edit skills in this
repository. `CLAUDE.md` imports this file; keep all rules here.

## Layout

```
skills/<skill-name>/SKILL.md     # one folder per skill, required
skills/<skill-name>/references/  # optional supporting files
install.sh                       # symlinks skills/* into agent directories
test/install.test.sh             # installer tests (run before committing)
docs/compatibility.md            # verified agent support and sources
```

## Adding or editing a skill

1. Create `skills/<skill-name>/SKILL.md`. The folder name is the skill ID.
2. Write the frontmatter (contract below) and the body.
3. Add the skill to the index in `README.md` (trigger and what it needs).
4. If you changed `install.sh`, run `sh test/install.test.sh` and keep it
   green.
5. Commit with a conventional commit message (`feat:`, `fix:`, `docs:`,
   `refactor:`, `chore:`, `test:`). One logical change per commit.

## Frontmatter contract

Use only fields that every supported agent accepts (see
`docs/compatibility.md`):

```yaml
---
name: skill-name            # required; equals the folder name
description: "Trigger: ... What it does and when to use it."  # required
license: Apache-2.0         # optional
metadata:                   # optional; string values only
  author: "CarlJSL"
  version: "1.0"
---
```

- `name`: 1-64 chars, lowercase letters, digits and single hyphens, no
  leading or trailing hyphen, identical to the folder name.
- `description`: 1-1024 chars. Start with `Trigger:` and the phrases that
  should activate the skill, then say what it does.
- Do not add agent-specific fields (`allowed-tools`, `when_to_use`, `paths`,
  `disable-model-invocation`, `context`, `model`, ...). If a skill truly
  needs one, document why in the pull request.

## Versioning

- `metadata.version` is a quoted `"MAJOR.MINOR"` string.
- Bump MINOR for corrections and added guidance; bump MAJOR when a rule
  changes in a way that would make existing output non-compliant.
- Mention the new version in the commit message body or PR.

## Writing rules

- English for all skill text, docs and comments. Code identifiers and
  examples may keep the naming of the project they describe.
- No emojis.
- No agent-specific paths or tool names inside skills (no `~/.claude`,
  `.opencode`, `Task` tool, etc.). A skill must read the same in any agent.
- No machine-specific absolute paths, personal handles or private project
  names.
- Only cite files, symbols and paths you verified in the target project.
- Keep `SKILL.md` short (aim for under ~350 lines); move long reference
  material into `references/`.
- Keep the structure: Activation Contract, Hard Rules, patterns, checklist,
  references.
