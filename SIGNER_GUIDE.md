# Guide for Signers

This document explains what signing someone's GPG key means, what this
repository's process does and does not protect, and how to participate safely.

## What You Are Committing To

Signing a GPG key is a public, cryptographic statement: *"I have independently
verified that this key belongs to the person whose name and email address are
listed on it, and I am lending my own cryptographic reputation to that claim."*

This matters because the signature travels with the key permanently. Anyone
who imports the key can see who has signed it. If you sign carelessly — without
genuine out-of-band verification — you weaken the value of your signature for
everyone who relies on it.

## Before You Sign: Out-of-Band Verification

**You must verify the key owner's identity before signing, through a channel
that is independent of this repository.**

The fingerprint listed in the README (`XXXX XXXX XXXX XXXX XXXX  XXXX XXXX
XXXX XXXX XXXX`) is provided as a sanity check against the key file — it lets
you confirm that the file you downloaded matches what the repository owner
intended. It does not prove that the key belongs to the person claiming it.
That is your responsibility to establish before signing.

Valid forms of out-of-band verification include:
- Meeting in person and confirming the fingerprint verbally or on a device you
  both trust
- A phone or video call with visual identity confirmation
- A message signed with a key you already trust that references this
  fingerprint
- Any channel that gives you independent confidence the fingerprint belongs to
  this person

**If you do not have an independent reason to trust the key, do not sign it.**

## Signing the Key Locally

```bash
# 1. Import the current key
gpg --import pubkey.asc

# 2. Verify the fingerprint matches what is published in the README (critical)
gpg --fingerprint your.email@example.com

# 3. Sign the key
gpg --sign-key XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# 4. Export the updated key (your signature is now embedded)
gpg --armor --export XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX > pubkey.asc
```

## Submitting Your Signature

### Option A — GitHub issue (recommended, no fork required)

1. Open the [Submit Signature](../../issues/new?template=submit-signature.yml)
   issue form
2. Paste the contents of `pubkey.asc` into the signed key field
3. Optionally paste your own public key — this allows the key owner to verify
   your signature cryptographically without relying on a keyserver
4. Fill in any other fields and submit

**What happens automatically:**
- The workflow validates that the submitted key contains the correct fingerprint
- If validation fails, it posts an error comment on your issue explaining why
- If validation passes, it creates a pull request on your behalf — you do not
  need to fork the repository
- A comment is posted on your issue with a link to the PR
- The issue closes automatically when the PR is merged

**What the automation does not check:** Whether your signature is
cryptographically valid, or whether you are who you claim to be. The key owner
reviews this manually before merging.

### Option B — Direct pull request

Fork the repository, commit the updated `pubkey.asc`, and open a pull request.
An automated check will confirm that only `pubkey.asc` was modified and that
the fingerprint is intact.

### Option C — Out-of-band (no GitHub required)

Send the updated key file directly to the key owner by email or any other
channel. This is always valid and requires no GitHub account. The key owner's
contact details are on the key itself.

If the automated flow (Option A) is not working for any reason, Option C is
the reliable fallback.

## Privacy

When submitting via GitHub issue or pull request:

- Your GitHub account identity is permanently and publicly linked to your
  submission
- The key file (which contains your signature and key ID) will be committed to
  a public repository
- Any information you provide in the issue form — your identity, verification
  method, or public key — is public and permanent

This is consistent with how the GPG web of trust works: signing is inherently
a public act. If you have privacy concerns about publicly associating your
identity with this key, Option C (direct, private channel) is the appropriate
approach.

## What This Repository Does and Does Not Provide

**This repository provides:**
- A findable, versioned, auditable distribution point for the key
- A public record of accepted signatures via the git history
- A structured process for submitting signatures without requiring a fork

**This repository does not provide:**
- Proof that the key belongs to the person claiming it — that is what your
  out-of-band verification establishes
- Automatic revocation notification — re-importing the key from this
  repository will include any revocation, but this does not happen automatically
- A replacement for standard GPG verification practices

**GPG is the ultimate source of truth.** The release notes and this repository
are conveniences. Any security-sensitive decision should be based on importing
the key and running `gpg --list-sigs`, `gpg --check-sigs`, and verifying the
fingerprint against an independent source.
