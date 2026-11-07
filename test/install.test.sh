#!/bin/sh
# Tests for install.sh. Runs against a temporary HOME and never touches the
# real ~/.claude, ~/.config or ~/.agents directories.
#
# Usage: sh test/install.test.sh   (set TMPDIR to choose the scratch location)

set -u

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd -P)
INSTALL=$REPO_DIR/install.sh
SKILLS_DIR=$REPO_DIR/skills

WORK=$(mktemp -d "${TMPDIR:-/tmp}/install-test.XXXXXX")
trap 'rm -rf "$WORK"' EXIT INT TERM
HOME=$WORK/home
export HOME
mkdir -p "$HOME"

PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
not_ok() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
check() {
  desc=$1
  shift
  if "$@"; then ok "$desc"; else not_ok "$desc"; fi
}

is_link_to() { [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; }

SKILL=$(for d in "$SKILLS_DIR"/*/; do [ -f "${d}SKILL.md" ] && basename "$d" && break; done)
[ -n "$SKILL" ] || { echo "no skill found under $SKILLS_DIR"; exit 1; }
SRC=$SKILLS_DIR/$SKILL

CLAUDE=$HOME/.claude/skills
OPENCODE=$HOME/.config/opencode/skills
AGENTS=$HOME/.agents/skills

# 1. dry-run changes nothing
out=$(sh "$INSTALL" --agent all --dry-run 2>&1)
check "dry-run exits 0" [ $? -eq 0 ]
check "dry-run creates no directories" [ ! -e "$HOME/.claude" ]
check "dry-run reports planned links" sh -c 'printf "%s" "$1" | grep -q "\[dry-run\] link"' _ "$out"

# 2. install (default agent is claude)
sh "$INSTALL" >/dev/null 2>&1
check "install exits 0" [ $? -eq 0 ]
check "claude link created" is_link_to "$CLAUDE/$SKILL" "$SRC"
check "default install does not touch opencode" [ ! -e "$OPENCODE" ]

# 3. re-install is idempotent
out=$(sh "$INSTALL" 2>&1)
check "re-install exits 0" [ $? -eq 0 ]
check "re-install reports already linked" sh -c 'printf "%s" "$1" | grep -q "already linked"' _ "$out"
check "link still correct after re-install" is_link_to "$CLAUDE/$SKILL" "$SRC"

# 4. install all agents
sh "$INSTALL" --agent all >/dev/null 2>&1
check "install all exits 0" [ $? -eq 0 ]
check "opencode link created" is_link_to "$OPENCODE/$SKILL" "$SRC"
check "agents link created" is_link_to "$AGENTS/$SKILL" "$SRC"

# 5. --dest and --project
sh "$INSTALL" --dest "$WORK/custom" >/dev/null 2>&1
check "--dest link created" is_link_to "$WORK/custom/$SKILL" "$SRC"
mkdir -p "$WORK/proj"
(cd "$WORK/proj" && sh "$INSTALL" --project --agent codex >/dev/null 2>&1)
check "--project link created" is_link_to "$WORK/proj/.agents/skills/$SKILL" "$SRC"

# 6. dry-run uninstall keeps links
sh "$INSTALL" --agent all --uninstall --dry-run >/dev/null 2>&1
check "dry-run uninstall keeps links" is_link_to "$CLAUDE/$SKILL" "$SRC"

# 7. uninstall removes only our links
ln -s "$WORK" "$CLAUDE/foreign-link"
mkdir -p "$CLAUDE/real-skill"
sh "$INSTALL" --agent all --uninstall >/dev/null 2>&1
check "uninstall exits 0" [ $? -eq 0 ]
check "claude link removed" [ ! -L "$CLAUDE/$SKILL" ]
check "opencode link removed" [ ! -L "$OPENCODE/$SKILL" ]
check "agents link removed" [ ! -L "$AGENTS/$SKILL" ]
check "foreign symlink kept" [ -L "$CLAUDE/foreign-link" ]
check "real directory kept" [ -d "$CLAUDE/real-skill" ]

# 8. refuse to overwrite a real directory
mkdir -p "$CLAUDE/$SKILL"
echo keep > "$CLAUDE/$SKILL/marker"
sh "$INSTALL" >/dev/null 2>&1
check "install refuses real directory (exit 1)" [ $? -eq 1 ]
check "real directory untouched" [ -f "$CLAUDE/$SKILL/marker" ]
check "real directory not replaced by a link" [ ! -L "$CLAUDE/$SKILL" ]
rm -rf "${CLAUDE:?}/$SKILL"

# 9. refuse to replace a symlink owned by something else
ln -s "$WORK" "$CLAUDE/$SKILL"
sh "$INSTALL" >/dev/null 2>&1
check "install refuses foreign symlink (exit 1)" [ $? -eq 1 ]
check "foreign symlink untouched" is_link_to "$CLAUDE/$SKILL" "$WORK"

# 10. invalid arguments
sh "$INSTALL" --agent nope >/dev/null 2>&1
check "unknown agent exits 2" [ $? -eq 2 ]

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
