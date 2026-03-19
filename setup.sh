#!/usr/bin/env bash
# Setup script for gpg-identity-template.
# See SETUP.md for manual steps and full context.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Helpers -----------------------------------------------------------------

bold()  { printf '\033[1m%s\033[0m' "$*"; }
green() { printf '\033[32m%s\033[0m' "$*"; }

die() { echo "Error: $*" >&2; exit 1; }

ask() {
  local prompt="$1" default="${2:-}" reply
  if [[ -n "$default" ]]; then
    read -r -p "$(bold "$prompt") [$default]: " reply
    echo "${reply:-$default}"
  else
    read -r -p "$(bold "$prompt"): " reply
    echo "$reply"
  fi
}

confirm() {
  local reply
  read -r -p "$(bold "$1") [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

format_fingerprint() {
  local fpr="$1" result="" i
  for i in 0 4 8 12 16 20 24 28 32 36; do
    [[ -n "$result" ]] && result+=" "
    [[ "$i" -eq 20 ]] && result+=" "
    result+="${fpr:$i:4}"
  done
  echo "$result"
}

# sed -i syntax differs between macOS (BSD) and Linux (GNU)
sedi() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Escape a string for use as a sed replacement (not pattern) with # delimiter
escape_replacement() {
  printf '%s\n' "$1" | sed 's/[\\&]/\\&/g; s/#/\\#/g'
}

replace_in_files() {
  local pattern="$1" new="$2"
  local escaped_new
  escaped_new=$(escape_replacement "$new")
  local file
  for file in README.md \
              accept-signature.sh \
              .github/workflows/validate-pr.yml \
              .github/workflows/create-signature-pr.yml \
              .github/PULL_REQUEST_TEMPLATE.md \
              .github/ISSUE_TEMPLATE/submit-signature.yml; do
    [[ -f "$file" ]] || continue
    sedi "s#${pattern}#${escaped_new}#g" "$file"
  done
}

# --- Checks ------------------------------------------------------------------

command -v gpg >/dev/null 2>&1 || die "gpg not found in PATH"

# --- Select key --------------------------------------------------------------

echo
echo "$(bold "Scanning GPG keyring for secret keys...")"
echo

FINGERPRINTS=()
while IFS= read -r fpr; do
  FINGERPRINTS+=("$fpr")
done < <(gpg --with-colons --list-secret-keys 2>/dev/null | awk -F: '/^fpr/{print $10}')

[[ ${#FINGERPRINTS[@]} -gt 0 ]] || die "No secret keys found in your GPG keyring"

KEY_UIDS=()
for fpr in "${FINGERPRINTS[@]}"; do
  uid=$(gpg --with-colons --list-secret-keys "$fpr" 2>/dev/null | awk -F: '/^uid/{print $10; exit}')
  KEY_UIDS+=("$uid")
done

if [[ ${#FINGERPRINTS[@]} -eq 1 ]]; then
  printf "  %s  %s\n\n" "${FINGERPRINTS[0]}" "${KEY_UIDS[0]}"
  confirm "Use this key?" || die "Aborted"
  IDX=0
else
  for i in "${!FINGERPRINTS[@]}"; do
    printf "  %d)  %s  %s\n" "$((i+1))" "${FINGERPRINTS[$i]}" "${KEY_UIDS[$i]}"
  done
  echo
  while true; do
    choice=$(ask "Select a key (1-${#FINGERPRINTS[@]})")
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#FINGERPRINTS[@]} )); then
      IDX=$((choice-1))
      break
    fi
    echo "Invalid selection, try again."
  done
fi

CHOSEN_FPR="${FINGERPRINTS[$IDX]}"
RAW_UID="${KEY_UIDS[$IDX]}"

# --- Extract key details -----------------------------------------------------

ALGO_NUM=$(gpg --with-colons --list-keys "$CHOSEN_FPR" 2>/dev/null | awk -F: '/^pub/{print $4; exit}')
KEY_SIZE=$(gpg --with-colons --list-keys "$CHOSEN_FPR" 2>/dev/null | awk -F: '/^pub/{print $3; exit}')

KEY_EMAIL=$(echo "$RAW_UID" | grep -o '<[^>]*>' | tr -d '<>')
KEY_NAME=$(echo "$RAW_UID" | sed 's/ *([^)]*)//' | sed 's/ *<[^>]*>//' | sed 's/^ *//;s/ *$//')

case "$ALGO_NUM" in
  1)  KEY_TYPE="RSA ${KEY_SIZE}" ;;
  17) KEY_TYPE="DSA" ;;
  19) KEY_TYPE="ECDSA" ;;
  22) KEY_TYPE="Ed25519 / Curve25519" ;;
  *)  KEY_TYPE="Algorithm ${ALGO_NUM}" ;;
esac

FPR_FORMATTED=$(format_fingerprint "$CHOSEN_FPR")

REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
GITHUB_USERNAME=$(echo "$REMOTE" | sed 's|.*github\.com[:/]||' | sed 's|/.*||')
REPO_NAME=$(echo "$REMOTE" | sed 's|.*/||' | sed 's|\.git$||')

# --- Confirm details ---------------------------------------------------------

echo
echo "$(bold "Detected key details — press Enter to accept each value or type a replacement:")"
echo

KEY_NAME=$(ask          "Name"            "$KEY_NAME")
KEY_EMAIL=$(ask         "Email"           "$KEY_EMAIL")
KEY_TYPE=$(ask          "Key type"        "$KEY_TYPE")
GITHUB_USERNAME=$(ask   "GitHub username" "$GITHUB_USERNAME")
REPO_NAME=$(ask         "Repo name"       "$REPO_NAME")

echo
confirm "Proceed and update files?" || die "Aborted"

# --- Apply changes -----------------------------------------------------------

echo
echo "Replacing placeholders..."

# Note: patterns for sed are pre-escaped BRE patterns using # as the delimiter.
# Dots in the fixed placeholder strings are escaped to match literally.
replace_in_files "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"                       "$CHOSEN_FPR"
replace_in_files "XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX"           "$FPR_FORMATTED"
replace_in_files "YOUR NAME"                                                      "$KEY_NAME"
replace_in_files "your\.email@example\.com"                                       "$KEY_EMAIL"
replace_in_files "YOUR KEY TYPE (e\.g\. Ed25519 / Curve25519)"                   "$KEY_TYPE"
replace_in_files "YOUR_GITHUB_USERNAME"                                           "$GITHUB_USERNAME"
replace_in_files "YOUR_REPO_NAME"                                                 "$REPO_NAME"

echo "Exporting public key to pubkey.asc..."
gpg --armor --export "$CHOSEN_FPR" > pubkey.asc

echo "Removing setup banner from README.md..."
# Deletes from the > [!WARNING] line through the first blank line that follows
sedi '/^> \[!WARNING\]/,/^$/d' README.md

# --- Create GitHub label (optional) -----------------------------------------

echo
if command -v gh >/dev/null 2>&1; then
  if confirm "Create the 'signature-submission' label in GitHub now? (requires gh auth)"; then
    gh label create "signature-submission" \
      --color "0075ca" \
      --description "GPG key signature submission" 2>/dev/null \
      || echo "  Label may already exist or gh is not authenticated — create it manually in GitHub (Settings → Labels)."
  fi
else
  echo "Note: Create a 'signature-submission' label in GitHub (Settings → Labels) to enable the issue-based submission workflow."
fi

echo
echo "$(green "Done!") Review your changes with: $(bold "git diff")"
echo
echo "Suggested next steps:"
echo "  1. $(bold "git add -A && git commit -m 'chore: Configure identity for ${KEY_NAME}'")"
echo "  2. $(bold "git push")"
echo "  3. Ensure Issues are enabled in GitHub Settings (required for issue-based signature submission)"
echo "  4. Configure branch protection in GitHub Settings (see SETUP.md step 5)"
echo "  5. Optionally delete SETUP.md and setup.sh once everything is configured"
