# Setup Guide

A setup script (`setup.sh`) is included that automates the configuration steps
below. If you prefer to set things up manually, or would rather not run the
script, follow the manual steps directly — both approaches produce the same
result.

---

## Automated Setup

Run the setup script from the root of the repository:

```bash
bash setup.sh
```

The script will:
- Check that `gpg` and `python3` are available
- List the secret keys in your keyring and prompt you to select one (or
  confirm if there is only one)
- Extract and display key details (name, email, key type, fingerprint), letting
  you edit any value before proceeding
- Replace all placeholders in the relevant files
- Export your public key as `pubkey.asc`
- Remove the setup warning banner from `README.md`

After the script completes, review the changes with `git diff`, then commit and
push. Continue from step 5 (branch protection) below.

---

## Manual Setup

### Step 1 — Export and commit your public key

Export your key in ASCII-armored format and save it as `pubkey.asc` in the
root of the repository:

```bash
gpg --armor --export YOUR_FINGERPRINT > pubkey.asc
```

Commit it:

```bash
git add pubkey.asc
git commit -m "chore: Add public key"
git push
```

### Step 2 — Update the validation workflow

In `.github/workflows/validate-pr.yml`, replace the placeholder fingerprint
with your own (no spaces, uppercase):

```yaml
EXPECTED="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

Your fingerprint can be found with:

```bash
gpg --fingerprint your.email@example.com
```

### Step 3 — Update the README

In `README.md`, replace all placeholder values:

| Placeholder | Replace with |
|-------------|--------------|
| `YOUR NAME` | Your name |
| `your.email@example.com` | Your email address |
| `YOUR KEY TYPE (e.g. Ed25519 / Curve25519)` | Your key algorithm |
| `XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX` | Your fingerprint, grouped in fours with a double space in the middle |
| `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` | Your fingerprint, no spaces (appears multiple times) |
| `YOUR_GITHUB_USERNAME` | Your GitHub username |
| `YOUR_REPO_NAME` | This repository's name |

### Step 4 — Update the PR template

In `.github/PULL_REQUEST_TEMPLATE.md`, replace the fingerprint in the
checklist with your own (formatted):

```markdown
- [ ] I verified the key fingerprint is `XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX` before signing
```

### Step 5 — Configure branch protection

In **Settings → Rules → Rulesets**, target the default branch and enable:

- Restrict deletions
- Block force pushes

In **Settings → General**, under **Pull Requests**, disable squash merging
and rebase merging — leave only **Allow merge commits** enabled.

Optionally disable **Issues** under **Settings → General → Features**.

### Step 6 — Remove the setup banner and clean up

Delete the warning block from the top of `README.md` (including the blank
line following it):

```markdown
> [!WARNING]
> **This repository has not been configured yet.** Follow [SETUP.md](SETUP.md)
> to replace all placeholder values with your own key details before making
> this repository public.
```

You may also delete `SETUP.md` and `setup.sh` at this point if you prefer a
clean repository, or keep them for reference.
