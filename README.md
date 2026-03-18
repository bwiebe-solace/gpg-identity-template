> [!WARNING]
> **This repository has not been configured yet.** Follow [SETUP.md](SETUP.md)
> to replace all placeholder values with your own key details before making
> this repository public.

# GPG Identity — YOUR NAME

This repository is the canonical source for my GPG public key. It serves as a
distribution point and a place for others to contribute signatures, building a
verifiable web of trust without relying on keyserver infrastructure.

## Key Details

| Field       | Value                                                       |
|-------------|-------------------------------------------------------------|
| Name        | YOUR NAME                                                   |
| Email       | your.email@example.com                                      |
| Key type    | YOUR KEY TYPE (e.g. Ed25519 / Curve25519)                   |
| Fingerprint | `XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX`       |

## Retrieving the Key

Import directly from this repository:

```bash
curl -sL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME/main/pubkey.asc | gpg --import
```

Or clone the repo and import locally:

```bash
gpg --import pubkey.asc
```

## Verifying the Fingerprint

After importing, verify the fingerprint matches exactly what is shown above:

```bash
gpg --fingerprint your.email@example.com
```

Do not trust a key that does not produce this exact fingerprint. If in doubt,
verify out-of-band (in person, via a signed message, or through another
trusted channel).

## Contributing a Signature

If you have verified my identity and would like to add your signature to my
key, please follow the steps below and open a pull request.

### Signing Workflow

```bash
# 1. Import the current key from this repo
gpg --import pubkey.asc

# 2. Verify the fingerprint matches before signing (critical)
gpg --fingerprint your.email@example.com

# 3. Sign the key with your own key
gpg --sign-key XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# 4. Export the updated key (now includes your signature)
gpg --armor --export XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX > pubkey.asc
```

Then fork this repository, commit the updated `pubkey.asc`, and open a pull
request. The PR description template will guide you through the checklist.

PRs are merged manually by me on my local machine so that I can review the
incoming signature and update my own keyring at the same time.

## Maintainer: Merging a Signature PR

PRs are intentionally not merged via the GitHub UI. The steps below allow
validating the signature and updating the local keyring atomically.

```bash
# Fetch the PR branch without checking it out
git fetch origin pull/<PR_NUMBER>/head:pr-<PR_NUMBER>

# Inspect the diff — it must only modify pubkey.asc
git diff main pr-<PR_NUMBER>

# Import the key from the branch to update the local keyring and review sigs
git show pr-<PR_NUMBER>:pubkey.asc | gpg --import
gpg --list-sigs XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# If the signature looks legitimate, merge with an explicit merge commit
git merge --no-ff pr-<PR_NUMBER> -m "merge: Accept signature from <SIGNER>"
git push origin main

# Clean up
git branch -d pr-<PR_NUMBER>
```

If the signature is not legitimate or the PR modifies anything other than
`pubkey.asc`, close the PR without merging. To remove a bad signature from the
local keyring:

```bash
gpg --edit-key XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# At the gpg> prompt: uid 1 (select the uid), then: delsig
```
