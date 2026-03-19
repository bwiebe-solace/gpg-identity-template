> [!WARNING]
> **This repository has not been configured yet.** Follow [SETUP.md](SETUP.md)
> to replace all placeholder values with your own key details before making
> this repository public.

# GPG Identity — YOUR NAME

This repository is the canonical source for my GPG public key. It serves as a
distribution point and a place for others to contribute signatures, building a
verifiable web of trust without relying on keyserver infrastructure.

> **Signers:** See [SIGNER_GUIDE.md](SIGNER_GUIDE.md) for a detailed guide including what
> out-of-band verification means, what the automation does and does not protect,
> and privacy considerations.
>
> **Key owner:** See [MAINTAINER_GUIDE.md](MAINTAINER_GUIDE.md) for key lifecycle
> management, the attestations process, and maintainer responsibilities.

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
key, start by signing and exporting the updated key locally:

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

Then submit the updated `pubkey.asc` using one of the two methods below.

### Option 1 — Submit via GitHub issue (preferred)

Open a **[Submit Signature](../../issues/new?template=submit-signature.yml)**
issue, paste the contents of `pubkey.asc` into the form, and submit. A pull
request will be opened automatically on your behalf — no fork required.

### Option 2 — Open a pull request directly

Fork this repository, commit the updated `pubkey.asc` to your fork, and open a
pull request. The PR description template will guide you through the checklist.

---

PRs are merged manually by me on my local machine so that I can review the
incoming signature and update my own keyring at the same time.

You can also send the signed key directly by email or any other channel — a
GitHub account is not required. See [SIGNER_GUIDE.md](SIGNER_GUIDE.md) for details.

## Maintainer: Merging a Signature PR

PRs are intentionally not merged via the GitHub UI. The recommended approach
is the included script, which handles the full flow interactively:

```bash
bash accept-signature.sh
```

The script lists open signature PRs, fetches the branch, imports the signer's
public key from the issue if provided, shows current signatures, verifies them
if possible, and prompts to accept or reject. Only accept signatures from
people whose identity you can confirm — if the signer did not include their
public key, verification must happen out-of-band.

### Manual equivalent

```bash
# Fetch the PR branch
git fetch origin pull/<PR_NUMBER>/head:pr-<PR_NUMBER>

# Verify only pubkey.asc was changed
git diff main pr-<PR_NUMBER>

# Optionally import the signer's public key for verification
# (paste from the issue, or obtain directly from the signer)
gpg --import <signer-key.asc>

# Import the updated key and review signatures
git show pr-<PR_NUMBER>:pubkey.asc | gpg --import
gpg --list-sigs XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Accept: merge, push, and clean up
git merge --no-ff pr-<PR_NUMBER> -m "merge: Accept signature from <SIGNER>"
git push origin main
git branch -d pr-<PR_NUMBER>

# Reject: close the PR
gh pr close <PR_NUMBER> --comment "Rejected: <REASON>"
git branch -d pr-<PR_NUMBER>
```

To remove a signature from your local keyring after a rejection:

```bash
gpg --edit-key XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# At the gpg> prompt: uid 1 (select the uid), then: delsig
```
