#!/bin/sh
# Symlink every skills/<name>/ folder of this repository into the skill
# directories that coding agents scan. See docs/compatibility.md for the
# sources behind each target directory.
#
# Usage: ./install.sh [--agent claude|opencode|codex|all] [--dest DIR]
#                     [--project] [--uninstall] [--dry-run] [--help]

set -eu

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Symlink each skills/<name>/ folder into agent skill directories.

Options:
  --agent NAME   claude | opencode | codex | all   (default: claude)
                 claude   -> ~/.claude/skills          (project: .claude/skills)
                 opencode -> ~/.config/opencode/skills (project: .opencode/skills)
                 codex    -> ~/.agents/skills          (project: .agents/skills)
  --dest DIR     Link into DIR instead of the agent directories.
  --project      Use project-level directories under the current directory.
  --uninstall    Remove the symlinks that point into this repository.
  --dry-run      Print what would happen without changing anything.
  -h, --help     Show this help.

Existing real files or directories, and symlinks that point elsewhere,
are never overwritten or removed.
EOF
}

die() {
  printf 'error: %s\n' "$1" >&2
  exit 2
}

AGENT=claude
DEST=
PROJECT=0
UNINSTALL=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)
      [ $# -ge 2 ] || die "--agent requires a value"
      AGENT=$2
      shift 2
      ;;
    --agent=*) AGENT=${1#--agent=}; shift ;;
    --dest)
      [ $# -ge 2 ] || die "--dest requires a value"
      DEST=$2
      shift 2
      ;;
    --dest=*) DEST=${1#--dest=}; shift ;;
    --project) PROJECT=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac
done

case "$AGENT" in
  claude|opencode|codex|all) ;;
  *) die "unknown agent: $AGENT (expected claude, opencode, codex or all)" ;;
esac

REPO_DIR=$(cd "$(dirname "$0")" && pwd -P)
SKILLS_DIR=$REPO_DIR/skills
[ -d "$SKILLS_DIR" ] || die "skills directory not found: $SKILLS_DIR"

target_dir() {
  if [ "$PROJECT" -eq 1 ]; then
    base=$(pwd -P)
    case "$1" in
      claude) printf '%s\n' "$base/.claude/skills" ;;
      opencode) printf '%s\n' "$base/.opencode/skills" ;;
      codex) printf '%s\n' "$base/.agents/skills" ;;
    esac
  else
    case "$1" in
      claude) printf '%s\n' "$HOME/.claude/skills" ;;
      opencode) printf '%s\n' "$HOME/.config/opencode/skills" ;;
      codex) printf '%s\n' "$HOME/.agents/skills" ;;
    esac
  fi
}

if [ -n "$DEST" ]; then
  TARGETS=$DEST
elif [ "$AGENT" = all ]; then
  TARGETS="$(target_dir claude)
$(target_dir opencode)
$(target_dir codex)"
else
  TARGETS=$(target_dir "$AGENT")
fi

PREFIX=
[ "$DRY_RUN" -eq 1 ] && PREFIX='[dry-run] '
FAILED=0

say() {
  printf '%s%s\n' "$PREFIX" "$1"
}

run() {
  [ "$DRY_RUN" -eq 1 ] || "$@"
}

install_into() {
  dir=$1
  if [ ! -d "$dir" ]; then
    say "create directory $dir"
    run mkdir -p "$dir"
  fi
  for src in "$SKILLS_DIR"/*/; do
    [ -f "${src}SKILL.md" ] || continue
    src=${src%/}
    name=${src##*/}
    dst=$dir/$name
    if [ -L "$dst" ]; then
      current=$(readlink "$dst")
      if [ "$current" = "$src" ]; then
        say "ok      $dst (already linked)"
      else
        case "$current" in
          "$SKILLS_DIR"/*)
            say "relink  $dst -> $src"
            run rm "$dst"
            run ln -s "$src" "$dst"
            ;;
          *)
            printf 'refuse  %s (symlink to %s, not managed by this repo)\n' "$dst" "$current" >&2
            FAILED=1
            ;;
        esac
      fi
    elif [ -e "$dst" ]; then
      printf 'refuse  %s (exists and is not a symlink)\n' "$dst" >&2
      FAILED=1
    else
      say "link    $dst -> $src"
      run ln -s "$src" "$dst"
    fi
  done
}

uninstall_from() {
  dir=$1
  if [ ! -d "$dir" ]; then
    say "skip    $dir (does not exist)"
    return 0
  fi
  removed=0
  for dst in "$dir"/* "$dir"/.[!.]*; do
    [ -L "$dst" ] || continue
    current=$(readlink "$dst")
    case "$current" in
      "$SKILLS_DIR"/*)
        say "unlink  $dst"
        run rm "$dst"
        removed=1
        ;;
    esac
  done
  [ "$removed" -eq 1 ] || say "skip    $dir (no symlinks from this repo)"
}

OLD_IFS=$IFS
IFS='
'
for dir in $TARGETS; do
  IFS=$OLD_IFS
  if [ "$UNINSTALL" -eq 1 ]; then
    uninstall_from "$dir"
  else
    install_into "$dir"
  fi
done
IFS=$OLD_IFS

if [ "$FAILED" -ne 0 ]; then
  printf 'Some entries were refused; remove or rename them manually and re-run.\n' >&2
  exit 1
fi
exit 0
