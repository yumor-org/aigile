#!/usr/bin/env bash
# aigile bootstrap — install aigile into the current GitHub repository.
#
# This script is self-contained: it clones the aigile source tree to a
# temporary directory, copies the canonical assets into the working tree,
# creates the required GitHub labels, and then cleans up after itself.
# No persistent install of aigile is required on the user's machine.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/yumor-org/aigile/main/cli/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/yumor-org/aigile/main/cli/install.sh | bash -s -- --yes --base-branch develop
#
# Options:
#   -f, --force              Overwrite existing files (default: skip).
#   -y, --yes                Skip the confirmation prompt.
#       --base-branch <ref>  Use the given branch as base_branch (default:
#                            the repository's default branch on GitHub).
#
# Environment overrides:
#   AIGILE_REPO  default: yumor-org/aigile
#   AIGILE_REF   default: main

set -euo pipefail

REPO="${AIGILE_REPO:-yumor-org/aigile}"
REF="${AIGILE_REF:-main}"

# ---------- logging ----------
log_info()  { printf '==> %s\n' "$*" >&2; }
log_step()  { printf '    %s\n' "$*" >&2; }
log_warn()  { printf 'WARN: %s\n' "$*" >&2; }
log_error() { printf 'ERROR: %s\n' "$*" >&2; }
die()       { log_error "$*"; exit 1; }

# ---------- preflight ----------
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

preflight() {
  require_cmd git
  require_cmd gh
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || die "Not inside a git working tree. Run \"git init\" first."
  gh auth status >/dev/null 2>&1 \
    || die "gh is not authenticated. Run \"gh auth login\" first."
  gh repo view >/dev/null 2>&1 \
    || die "Current directory is not connected to a GitHub repository."
}

# ---------- prompts ----------
prompt() {
  local label="$1" default="$2" answer=""
  if [ -e /dev/tty ]; then
    printf '%s [%s]: ' "$label" "$default" >&2
    read -r answer < /dev/tty 2>/dev/null || answer=""
  fi
  if [ -z "$answer" ]; then
    printf '%s' "$default"
  else
    printf '%s' "$answer"
  fi
}

confirm() {
  local label="$1" default_yn="${2:-y}" answer="" hint
  case "$default_yn" in
    y|Y) hint="Y/n" ;;
    *)   hint="y/N" ;;
  esac
  if [ -e /dev/tty ]; then
    printf '%s [%s]: ' "$label" "$hint" >&2
    read -r answer < /dev/tty 2>/dev/null || answer=""
  fi
  [ -z "$answer" ] && answer="$default_yn"
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------- file installer ----------
# install_file SRC DEST [KEY=VALUE]...
# Writes DEST from SRC, substituting __KEY__ tokens with VALUE.
install_file() {
  local src="$1" dest="$2"
  shift 2
  [ -e "$src" ] || die "source not found: $src"

  if [ -e "$dest" ] && [ "${FORCE:-0}" -ne 1 ]; then
    log_step "skip   $dest (exists; use --force to overwrite)"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  local content key value pair
  content="$(cat "$src")"
  for pair in "$@"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    content="${content//__${key}__/$value}"
  done
  printf '%s' "$content" > "$dest"
  log_step "write  $dest"
}

ensure_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    log_step "mkdir  $dir"
  fi
}

ensure_label() {
  local name="$1" color="$2" description="$3"
  if gh label list --limit 200 --json name --jq '.[].name' 2>/dev/null | grep -Fxq "$name"; then
    log_step "label  $name (exists)"
    return 0
  fi
  if gh label create "$name" --color "$color" --description "$description" >/dev/null 2>&1; then
    log_step "label  $name (created)"
  else
    log_warn "Failed to create label: $name (insufficient permission?)"
  fi
}

# ---------- main ----------
main() {
  FORCE=0
  local assume_yes=0
  local base_branch_override=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--force) FORCE=1 ;;
      -y|--yes)   assume_yes=1 ;;
      --base-branch=*) base_branch_override="${1#*=}" ;;
      --base-branch)   shift; base_branch_override="${1:-}" ;;
      -h|--help)
        sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
        return 0
        ;;
      *) die "Unknown argument: $1" ;;
    esac
    shift
  done

  preflight

  local owner repo default_branch user_login
  owner="$(gh repo view --json owner --jq .owner.login)"
  repo="$(gh repo view --json name --jq .name)"
  default_branch="$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)"
  user_login="$(gh api user --jq .login)"

  log_info "Repository: $owner/$repo"
  log_info "Default branch detected: $default_branch"
  log_info "Authenticated as: @$user_login"

  local base_branch
  if [ -n "$base_branch_override" ]; then
    base_branch="$base_branch_override"
  elif [ "$assume_yes" -eq 1 ]; then
    base_branch="$default_branch"
  else
    base_branch="$(prompt 'Base branch (Source of Truth) for aigile' "$default_branch")"
  fi

  printf '\n' >&2
  log_info "Plan:"
  log_step ".aigile/README.md                                    (onboarding guide)"
  log_step ".aigile/config.yml                                   (base_branch=$base_branch)"
  log_step ".aigile/stakeholders.yml                             (default approver: @$user_login)"
  log_step ".aigile/agents.yml                                   (empty catalog)"
  log_step ".aigile/docs/L1_requirements/TEMPLATE.md             (Requirement Document テンプレート)"
  log_step ".aigile/docs/L2_specifications/TEMPLATE.md           (Specification Document テンプレート)"
  log_step ".aigile/docs/L3_architectures/TEMPLATE.md            (Architecture Document テンプレート)"
  log_step ".github/ISSUE_TEMPLATE/aigile-requirement.yml"
  log_step ".github/workflows/aigile-requirement-analyzer.md     (gh aw)"
  log_step ".github/workflows/aigile-requirement-doc-writer.md   (gh aw)"
  log_step ".github/workflows/aigile-specification-doc-writer.md (gh aw)"
  log_step ".github/workflows/aigile-architecture-doc-writer.md  (gh aw)"
  log_step ".github/workflows/aigile-assign-doc-reviewers.yml    (Actions)"
  log_step ".github/workflows/aigile-mark-doc-fixed.yml          (Actions)"
  log_step "labels: aigile:issue:req, aigile:issue:status:req-analyzed,"
  log_step "        aigile:issue:status:req-fixed, aigile:issue:status:spec-fixed,"
  log_step "        aigile:issue:status:arch-fixed,"
  log_step "        aigile:pr:req, aigile:pr:spec, aigile:pr:arch,"
  log_step "        automation"
  printf '\n' >&2

  if [ "$assume_yes" -ne 1 ] && ! confirm 'Proceed?' 'y'; then
    log_info "Aborted by user."
    return 0
  fi

  # Fetch the aigile source tree to a temp dir so we can copy canonical assets.
  local tmp src
  tmp="$(mktemp -d 2>/dev/null || mktemp -d -t aigile-bootstrap)"
  trap 'rm -rf "$tmp"' EXIT
  src="$tmp/aigile"

  log_info "Fetching aigile ($REPO@$REF)..."
  git clone --quiet --depth 1 --branch "$REF" "https://github.com/${REPO}.git" "$src" 2>/dev/null \
    || die "failed to fetch https://github.com/${REPO}.git@${REF}"

  log_info "Installing files..."
  install_file "$src/cli/templates/readme.md"        ".aigile/README.md"
  install_file "$src/cli/templates/config.yml"       ".aigile/config.yml"        "BASE_BRANCH=$base_branch"
  install_file "$src/cli/templates/stakeholders.yml" ".aigile/stakeholders.yml"  "OWNER=$user_login"
  install_file "$src/cli/templates/agents.yml"       ".aigile/agents.yml"

  # 各レイヤーディレクトリは TEMPLATE.md が tracked ファイルとして保持するため、
  # 別途 .gitkeep を作成する必要はない。
  install_file "$src/cli/templates/docs/L1_requirements/TEMPLATE.md"   ".aigile/docs/L1_requirements/TEMPLATE.md"
  install_file "$src/cli/templates/docs/L2_specifications/TEMPLATE.md" ".aigile/docs/L2_specifications/TEMPLATE.md"
  install_file "$src/cli/templates/docs/L3_architectures/TEMPLATE.md"  ".aigile/docs/L3_architectures/TEMPLATE.md"

  install_file "$src/.github/ISSUE_TEMPLATE/aigile-requirement.yml"        ".github/ISSUE_TEMPLATE/aigile-requirement.yml"
  install_file "$src/.github/workflows/aigile-requirement-analyzer.md"     ".github/workflows/aigile-requirement-analyzer.md"
  install_file "$src/.github/workflows/aigile-requirement-doc-writer.md"   ".github/workflows/aigile-requirement-doc-writer.md"
  install_file "$src/.github/workflows/aigile-specification-doc-writer.md" ".github/workflows/aigile-specification-doc-writer.md"
  install_file "$src/.github/workflows/aigile-architecture-doc-writer.md"  ".github/workflows/aigile-architecture-doc-writer.md"
  install_file "$src/.github/workflows/aigile-assign-doc-reviewers.yml"    ".github/workflows/aigile-assign-doc-reviewers.yml"
  install_file "$src/.github/workflows/aigile-mark-doc-fixed.yml"          ".github/workflows/aigile-mark-doc-fixed.yml"

  log_info "Creating GitHub labels..."
  # Issue 識別ラベル
  ensure_label "aigile:issue:req"                 "0E8A16" "aigile Requirement Issue (追加の要求)"
  # Issue ステータスラベル（カスケードトリガー）
  ensure_label "aigile:issue:status:req-analyzed" "1D76DB" "Requirement Analyzer 完了 (Req Doc Writer の発火条件)"
  ensure_label "aigile:issue:status:req-fixed"    "0E8A16" "Requirement Document が main に確定 (Spec Writer の発火条件)"
  ensure_label "aigile:issue:status:spec-fixed"   "0E8A16" "Specification Document が main に確定 (Arch Writer の発火条件)"
  ensure_label "aigile:issue:status:arch-fixed"   "0E8A16" "Architecture Document が main に確定 (Doc カスケード終端)"
  # PR 識別ラベル（レビュアー割り当てに使用）
  ensure_label "aigile:pr:req"                    "5319E7" "aigile Requirement Document PR"
  ensure_label "aigile:pr:spec"                   "5319E7" "aigile Specification Document PR"
  ensure_label "aigile:pr:arch"                   "5319E7" "aigile Architecture Document PR"
  # 汎用マーカー
  ensure_label "automation"                       "BFD4F2" "Automated PR / Issue"

  printf '\n' >&2
  log_info "Done."
  cat >&2 <<'EOF'

Next steps:
  1. Review the new files and commit them.
       git status
       git add .aigile .github
       git commit -m "chore: bootstrap aigile"
       git push

  2. Open a Requirement Issue from the new template
     (Issues -> New issue -> "Requirement Issue (追加の要求)").

  3. The Document Writer workflows are GitHub Agentic Workflows. Install and
     compile them once with the gh-aw extension:
       gh extension install githubnext/gh-aw
       gh aw compile
       gh aw push
     This compiles 4 .md workflows to .lock.yml:
       - aigile-requirement-analyzer
       - aigile-requirement-doc-writer
       - aigile-specification-doc-writer
       - aigile-architecture-doc-writer
     The aigile-assign-doc-reviewers.yml is a regular Actions workflow and
     needs no compilation.
     See https://github.com/githubnext/gh-aw for the Anthropic API key
     secret setup and other gh-aw specifics.
EOF
}

main "$@"
