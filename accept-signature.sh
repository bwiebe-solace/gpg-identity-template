#!/usr/bin/env bash
# Interactively review, accept, or reject a signature PR.
# Run from the root of the repository.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

FINGERPRINT="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# --- Helpers -----------------------------------------------------------------

bold()   { printf '\033[1m%s\033[0m' "$*"; }
green()  { printf '\033[32m%s\033[0m' "$*"; }
yellow() { printf '\033[33m%s\033[0m' "$*"; }
red()    { printf '\033[31m%s\033[0m' "$*"; }
die()    { echo "$(red "Error:") $*" >&2; exit 1; }

# --- Checks ------------------------------------------------------------------

command -v gpg >/dev/null 2>&1 || die "gpg not found in PATH"
command -v gh  >/dev/null 2>&1 || die "gh not found in PATH"

# --- List open signature PRs -------------------------------------------------

echo
echo "$(bold "Open signature PRs:")"
echo

mapfile -t PR_LINES < <(gh pr list \
  --json number,title,headRefName \
  --jq '.[] | select(.headRefName | startswith("signature/")) | "\(.number)|\(.title)"' \
  --state open 2>/dev/null || true)

if [[ ${#PR_LINES[@]} -eq 0 ]]; then
  echo "No open signature PRs found."
  exit 0
fi

PR_NUMBERS=()
PR_TITLES=()
while IFS='|' read -r num title; do
  PR_NUMBERS+=("$num")
  PR_TITLES+=("$title")
done < <(printf '%s\n' "${PR_LINES[@]}")

if [[ ${#PR_NUMBERS[@]} -eq 1 ]]; then
  printf "  #%s  %s\n\n" "${PR_NUMBERS[0]}" "${PR_TITLES[0]}"
  read -r -p "$(bold "Review this PR?") [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || exit 0
  IDX=0
else
  for i in "${!PR_NUMBERS[@]}"; do
    printf "  %d)  #%s  %s\n" "$((i+1))" "${PR_NUMBERS[$i]}" "${PR_TITLES[$i]}"
  done
  echo
  while true; do
    read -r -p "$(bold "Select a PR (1-${#PR_NUMBERS[@]}):")" choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#PR_NUMBERS[@]} )); then
      IDX=$((choice-1))
      break
    fi
    echo "Invalid selection."
  done
fi

PR_NUMBER="${PR_NUMBERS[$IDX]}"
LOCAL_BRANCH="pr-${PR_NUMBER}"

# --- Fetch PR branch ---------------------------------------------------------

echo
echo "Fetching PR #${PR_NUMBER}..."
git fetch origin "pull/${PR_NUMBER}/head:${LOCAL_BRANCH}"

# --- Verify only pubkey.asc changed ------------------------------------------

echo
CHANGED=$(git diff --name-only main "${LOCAL_BRANCH}")
if [ "$CHANGED" != "pubkey.asc" ]; then
  echo "$(red "Error:") PR modifies files other than pubkey.asc:"
  echo "$CHANGED"
  echo
  read -r -p "$(bold "Reject and close this PR?") [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    gh pr close "$PR_NUMBER" --comment "Rejected: PR modifies files other than \`pubkey.asc\`."
    git branch -d "$LOCAL_BRANCH"
  fi
  exit 1
fi

# --- Import signer's key from issue if provided ------------------------------

echo
ISSUE_NUMBER=$(gh pr view "$PR_NUMBER" --json body --jq '.body' \
  | grep -o '#[0-9]*' | head -1 | tr -d '#')

SIGNER_KEY_IMPORTED=false
if [ -n "$ISSUE_NUMBER" ]; then
  SIGNER_KEY=$(gh issue view "$ISSUE_NUMBER" --json body --jq '.body' | \
    awk '/^### Your public key/,0' | \
    awk '/^-----BEGIN PGP PUBLIC KEY BLOCK-----/ { found=1 } found { print } /^-----END PGP PUBLIC KEY BLOCK-----/ { exit }')

  if [ -n "$SIGNER_KEY" ] && ! echo "$SIGNER_KEY" | grep -q "_No response_"; then
    echo "Signer's public key found in issue — importing..."
    printf '%s\n' "$SIGNER_KEY" | gpg --import 2>/dev/null && SIGNER_KEY_IMPORTED=true
    echo
  fi
fi

if ! $SIGNER_KEY_IMPORTED; then
  echo "$(yellow "Note:") No signer public key provided. Signature can only be verified out-of-band."
  echo
fi

# --- Import updated key and show signatures ----------------------------------

echo "$(bold "Importing updated key...")"
git show "${LOCAL_BRANCH}:pubkey.asc" | gpg --import 2>/dev/null
echo

echo "$(bold "Current signatures:")"
gpg --list-sigs "$FINGERPRINT"
echo

# --- Verify signatures if signer key available -------------------------------

if $SIGNER_KEY_IMPORTED; then
  echo "$(bold "Signature verification:")"
  gpg --check-sigs "$FINGERPRINT" 2>/dev/null | grep "^sig" || true
  echo
fi

# --- Accept or reject --------------------------------------------------------

echo "  $(bold a)  Accept — merge and push"
echo "  $(bold r)  Reject — close PR without merging"
echo "  $(bold s)  Skip — do nothing"
echo
read -r -p "$(bold "Choose [a/r/s]:") " ACTION

case "$ACTION" in
  a|A)
    read -r -p "$(bold "Signer name/identifier for commit message:") " SIGNER_NAME
    git merge --no-ff "$LOCAL_BRANCH" -m "merge: Accept signature from ${SIGNER_NAME}"
    git push origin main
    git branch -d "$LOCAL_BRANCH"
    REMOTE_BRANCH=$(gh pr view "$PR_NUMBER" --json headRefName --jq '.headRefName' 2>/dev/null || true)
    [ -n "$REMOTE_BRANCH" ] && git push origin --delete "$REMOTE_BRANCH" 2>/dev/null || true
    echo
    echo "$(green "Accepted.") Signature merged and pushed."
    ;;
  r|R)
    read -r -p "$(bold "Rejection reason (optional, Enter to skip):") " REASON
    if [ -n "$REASON" ]; then
      gh pr close "$PR_NUMBER" --comment "Rejected: ${REASON}"
    else
      gh pr close "$PR_NUMBER"
    fi
    git branch -d "$LOCAL_BRANCH"
    echo
    echo "PR closed. If the signature was imported into your keyring, remove it with:"
    echo "  gpg --edit-key ${FINGERPRINT}"
    echo "  # At the gpg> prompt: uid 1, then: delsig"
    ;;
  *)
    echo "Skipped. Local branch ${LOCAL_BRANCH} left in place."
    ;;
esac
