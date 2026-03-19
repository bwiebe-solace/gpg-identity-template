# Key Archive

This directory is an archive of **retired** keys associated with this
identity. The current active key is at `pubkey.asc` in the repository root —
that is the only copy maintained while a key is active.

When a key is retired (rotated at expiry or revoked due to compromise), it is
moved here named by its full 40-character fingerprint:

```
keys/<FINGERPRINT>.asc
```

The full fingerprint is used rather than a short or long key ID because short
fingerprints have known collision vulnerabilities.

## Archive

| Fingerprint | Status | Retired | Reason |
|---|---|---|---|
| *(none yet)* | | | |

## Why Keep Retired Keys?

- Allows verification of signatures made before the key was retired
- Anyone who previously imported a retired key can re-import it from here to
  receive the embedded revocation certificate (if applicable)
- Provides a complete, auditable record of all keys associated with this
  identity

See `attestations/` for signed statements accompanying any key transitions or
revocations.
