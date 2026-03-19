# Attestation Templates

Write the statement as a plain text file, then sign it with your key:

```bash
gpg --clearsign --armor -o YYYY-MM-DD-<type>.asc statement.txt
```

The resulting `.asc` file contains your statement and the signature inline.
Commit it to this directory with a signed commit.

---

## Key Transition

Use when rotating to a new key due to expiry or preference change.
Sign with the **old** key — the one being retired.

```
Key Transition Statement — YOUR NAME
Date: YYYY-MM-DD

I am transitioning my active GPG key.

Previous key:
  Fingerprint: <OLD_FINGERPRINT>
  Status:      Retiring (expired / superseded)

New key:
  Fingerprint: <NEW_FINGERPRINT>
  Available:   https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME

The new key has been signed by the previous key, and the previous key has
been signed by the new key, preserving the chain of trust. Both are
available in the keys/ directory of this repository.

Anyone who trusted the previous key should re-import the key file from
this repository to receive the updated status, and import the new key.

— YOUR NAME
```

---

## Key Revocation

Use when a key must be revoked due to compromise or loss.
Sign with the **compromised key if still possible**, otherwise with a
cross-signed personal key, or leave unsigned and explain why.

```
Key Revocation Notice — YOUR NAME
Date: YYYY-MM-DD

My GPG key with the following fingerprint has been revoked:
  Fingerprint: <FINGERPRINT>
  Reason:      [Compromise / Loss / Retirement / Superseded]

[Brief explanation if appropriate.]

A revocation certificate has been embedded in the key. The updated key
file is available at this repository. Anyone who has previously imported
this key should re-import it from:
  https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME

[If this notice is not signed with the revoked key, state which key
signed it and how to verify that key, or note that signing was not
possible and advise out-of-band verification.]

— YOUR NAME
```

---

## Cross-Signature

Use when establishing a signing relationship with another key (e.g.
cross-signing a personal key with this work key).
Sign with the key making the statement.

```
Cross-Signature Notice — YOUR NAME
Date: YYYY-MM-DD

I have established a cross-signature relationship between the following
keys, both of which belong to me:

  Key A:
    Fingerprint: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

  Key B:
    Fingerprint: <OTHER_FINGERPRINT>
    Available:   <OTHER_KEY_URL>

Each key has been signed by the other. Either key can serve as a trust
anchor for the other.

— YOUR NAME
```
