# Guide for the Key Owner (Maintainer)

## Core Principle

**GPG is the ultimate source of truth.** This repository provides a structured
process, a public record, and some protection against common mistakes. It does
not replace careful GPG-level verification at every step. The automation adds
convenience, but the key owner is the final gate for every signature that
enters the key — and for every change to this repository.

Signed commits are required on `main`. Every change to this repository is
cryptographically attributed to your key, forming an audit trail that anyone
can verify. This is a stronger guarantee than most keyservers offer. It also
means that if you act carelessly, your own key attests to that carelessness.

## Accepting Signatures

Run `bash accept-signature.sh` to interactively review open signature PRs.
The script walks through the full review flow: fetching the branch, importing
the signer's key (if provided in the issue), showing signatures, verifying
cryptographically where possible, and prompting you to accept or reject.

**Before accepting any signature, satisfy yourself that:**
- The signer's identity is one you can independently confirm
- The diff contains only `pubkey.asc`
- The new signature is visible in `gpg --list-sigs` output and appears
  legitimate

If the signer did not include their public key in the issue, cryptographic
verification is not possible from the script alone. Either obtain their key
through another channel before merging, or confirm their identity out-of-band
and accept on that basis. Do not accept signatures from parties you cannot
identify.

On acceptance, the commit message `merge: Accept signature from <SIGNER>`
becomes part of the permanent git history and feeds the public signatory list
in the repository release. Choose the identifier you write here deliberately —
it is a public statement of acceptance.

## Rejecting Signatures

On rejection, the script closes the PR with an optional reason. If you
imported the signer's key during review, the signature was also added to your
local keyring. Remove it if you do not want to keep it:

```bash
gpg --edit-key XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# At the gpg> prompt: uid 1 (select the uid), then: delsig
# Select the unwanted signature and confirm deletion, then: save
```

## Alternative Channels

Signatures can also arrive out-of-band — by email, Signal, or any other
channel. If you receive an updated key file this way, follow the same review
process as the script manually (import the signer's key, verify the new
signature, confirm identity) and commit using the standard message format:

```bash
# After verifying the key file manually:
cp received-pubkey.asc pubkey.asc
git add pubkey.asc
git commit -m "merge: Accept signature from <SIGNER>"
git push origin main
```

## Key Lifecycle

### Key Expiry (Planned Rotation)

When your key is approaching expiry and you are transitioning to a new key:

1. Generate the new key and ensure it is ready
2. Cross-sign: sign the new key with the old, and the old with the new
   ```bash
   gpg --sign-key <NEW_FINGERPRINT>
   gpg --default-key <NEW_FINGERPRINT> --sign-key <OLD_FINGERPRINT>
   ```
3. Write and sign a key transition statement (see `attestations/TEMPLATE.md`)
4. Archive the old key in `keys/`:
   ```bash
   gpg --armor --export <OLD_FINGERPRINT> > keys/<OLD_FINGERPRINT>.asc
   ```
5. Replace `pubkey.asc` with the new key and add it to `keys/`:
   ```bash
   gpg --armor --export <NEW_FINGERPRINT> > pubkey.asc
   gpg --armor --export <NEW_FINGERPRINT> > keys/<NEW_FINGERPRINT>.asc
   ```
6. Update `keys/README.md` — mark the old key as expired/retired, add the new
7. Update the key details table in `README.md`
8. Commit everything with a signed commit (signed with the new key)

The cross-signatures preserve the web of trust: anyone who trusted the old key
gains a path to the new key without requiring a fresh round of out-of-band
verification.

### Key Revocation (Compromise or Loss)

If your key is compromised or lost:

1. Import and apply the revocation certificate:
   ```bash
   gpg --import <revocation-cert.asc>
   ```
2. Export the revoked key (the revocation is now embedded) and update the repo:
   ```bash
   gpg --armor --export <FINGERPRINT> > pubkey.asc
   gpg --armor --export <FINGERPRINT> > keys/<FINGERPRINT>.asc
   ```
3. Write a revocation notice in `attestations/` if you are able to. If the
   key is compromised and you cannot sign with it, use a cross-signed personal
   key or note in the attestation that it is unsigned and explain why
4. Update `keys/README.md` and `README.md`
5. Commit and push

Anyone who re-imports the key will automatically receive the revocation.
Importers who do not re-import will not know. This is a limitation shared by
all self-hosted key distribution (personal websites, WKD, etc.) and is not
unique to this repository.

## Attestations

Any significant statement about your key should be written as a signed file in
the `attestations/` directory. This includes key transitions, revocations,
cross-signature relationships, and any explanation of unusual changes. See
`attestations/README.md` for the format and verification instructions.

Attestations, combined with the signed commit history, allow anyone to audit
the full chain of decisions made about this key and confirm they were
intentional and authorised.
