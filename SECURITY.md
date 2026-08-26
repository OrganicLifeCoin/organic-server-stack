# Security Policy

Do not publish a suspected vulnerability in a public issue before maintainers can assess it.

Report the affected repository, commit, configuration, impact, and reproduction steps through a private GitHub security advisory.

Never include these values in a report:

- Wallet seed phrases
- Wallet private keys
- Node RPC credentials
- Production certificates
- Unredacted wallet files

The current stack supports testnet evaluation. A production deployment must use HTTPS, private RPC networking, reviewed source pins, and encrypted backups.

Maintainers support the latest commit on `main` and the component revisions pinned by that commit.
