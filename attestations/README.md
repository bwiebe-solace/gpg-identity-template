# Attestations

This directory contains signed statements by the key owner about significant
key events: transitions to new keys, revocations, cross-signature
relationships, or explanations of any unusual changes.

Attestations, combined with the signed commit history of this repository,
allow anyone to audit the complete history of decisions made about this key
and confirm they were intentional and authorised.

## Verifying an Attestation

Each attestation is a GPG-signed plaintext file. To verify:

```bash
# Import the signing key (use the fingerprint from the attestation header)
gpg --import ../pubkey.asc

# Verify the attestation
gpg --verify <attestation-file>.asc
```

For key transition attestations, the statement is signed by the *old* key —
the one being retired. Verify using the archived key from `../keys/`:

```bash
gpg --import ../keys/<OLD_FINGERPRINT>.asc
gpg --verify <attestation-file>.asc
```

## File Naming

Attestation files are named by date and type:

```
YYYY-MM-DD-<type>.asc
```

Types:
- `key-transition` — planned rotation to a new key at expiry or by preference
- `key-revocation` — emergency revocation due to compromise or loss
- `cross-signature` — signing relationship established with another key
- `notice` — general notice about the key or this repository

## Templates

See `TEMPLATE.md` for the standard format for each type.
