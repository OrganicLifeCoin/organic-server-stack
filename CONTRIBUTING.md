# Contributing

Test all deployment changes on OrganicLifeCoin testnet.

## Change rules

1. Keep application source in its companion repository.
2. Pin every release, Git revision, and base-image version.
3. Never commit `.env`, credentials, certificates, private addresses, or wallet data.
4. Add a repository check before you add deployment behavior.
5. Run `make check` before you submit a change.
6. Render the Compose configuration with `make compose-config`.
7. Build the affected images from a clean checkout.
8. Document configuration and operational changes.

Use clear commit messages. Keep each change small enough for an independent review.
