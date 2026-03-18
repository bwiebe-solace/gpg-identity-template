# Why This Exists

## The Problem with GPG Keyservers

GPG's traditional key distribution mechanism relies on a global network of
keyservers. These servers were designed to make it easy to find and import
anyone's public key, and they supported the *web of trust* — a system where
people sign each other's keys to vouch for each other's identity, creating a
network of verifiable trust without relying on a central authority.

In 2019, this network was effectively broken by a certificate poisoning attack.
Because the protocol allows anyone to append signatures to any key on the
network with no limit, attackers flooded high-profile keys with hundreds of
thousands of garbage signatures. Importing one of these keys caused GnuPG to
hang indefinitely, rendering it unusable. The attack could not be patched
because it exploits a fundamental architectural property of the keyserver
network.

Modern keyserver alternatives (such as `keys.openpgp.org`) prevent this attack
by stripping all third-party signatures before serving keys. This solves the
denial-of-service problem, but at the cost of the web of trust — keys
distributed this way have no signatures and cannot be verified against anyone
else's keyring.

## Why GitHub

Hosting a GPG key in a GitHub repository solves these problems:

- **Retrieval is simple.** The raw key file is fetchable via a predictable URL,
  importable with a single command, and the repository itself is cloneable.
- **Updates are easy.** Any change to the key — a new signature, a new subkey,
  an extended expiry — is committed to the repository like any other file
  change, with a clear history of when and why.
- **Signatures are preserved.** Unlike modern keyservers, this repository stores
  the full key blob, including all third-party signatures. Anyone who signs the
  key and submits a PR is contributing to a genuine, hosted web of trust.
- **The owner controls what is accepted.** PRs can be reviewed and rejected.
  There is no equivalent of a poisoning attack here because the key owner
  approves every change before it is merged.

## How the Web of Trust Works Here

When someone signs a GPG key, they are making a public statement: "I have
verified that this key belongs to the person whose name and email are on it."
That signature is embedded in the key blob itself and travels with it.

The practical effect is that if you already trust one of the signers on a key,
GPG can extend that trust to the key owner automatically. The more signatures a
key accumulates from people within your trust network, the more confidence you
can have in the owner's identity — without needing to verify it yourself
directly.

By hosting the signed key in a public GitHub repository and accepting signature
contributions via pull requests, the key owner can accumulate verifiable trust
signals over time, and anyone who imports the key gets the full trust picture
alongside it.

## Why PRs Are Merged Locally

Signature PRs are intentionally not merged through the GitHub UI. Merging
locally serves two purposes:

1. **Validation.** The key owner imports the proposed key, reviews the new
   signature (checking who signed and that the key itself is intact), and only
   merges if satisfied. The GitHub Actions workflow performs basic automated
   checks, but the meaningful review happens locally.

2. **Keyring update.** Importing the key from the PR branch updates the owner's
   own GPG keyring with the new signature. The merge and the keyring update
   happen together as a single operation, keeping the repository and the local
   keyring in sync.
