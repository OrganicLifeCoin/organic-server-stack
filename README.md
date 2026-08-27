# OrganicLifeCoin Server Stack

OrganicLifeCoin Server Stack deploys the complete OLC browser-wallet backend with Docker Compose.

The stack runs these components:

- An OrganicLifeCoin testnet node
- The non-custodial OLC web wallet
- The restricted OLC RPC bridge
- The OLC Blockbook indexer and explorer
- A Caddy public gateway

Application source stays in separate repositories. This repository contains only deployment, security, backup, and operations files.

## Security model

Caddy is the only service with host ports. The node RPC port, RPC bridge, Blockbook, and wallet stay on a Docker network.

The browser wallet creates and signs transactions locally. The server submits signed data, but it does not receive wallet private keys.

Docker secret files provide the node RPC credentials. A network-isolated initializer copies them into a private read-only volume for the non-root services. The repository does not contain credentials, certificates, wallet files, or private keys.

The default configuration runs testnet. The node image uses the official `v1.1.2.0-testnet` release and verifies its published SHA-256 digest.

## Source repositories

- [OrganicLifeCoin Core](https://github.com/OrganicLifeCoin/OrganLife-Core)
- [OrganicLifeCoin Web Wallet](https://github.com/OrganicLifeCoin/organic-web-wallet)
- [OrganicLifeCoin RPC Bridge](https://github.com/OrganicLifeCoin/organic-rpc-bridge)
- [OrganicLifeCoin Blockbook](https://github.com/OrganicLifeCoin/organic-blockbook)

The Compose file pins each application to a Git commit or release digest. Review and update these pins together.

## Requirements

- A Linux server with amd64 or arm64 architecture
- Docker Engine with the Compose plugin
- Open ports `80/tcp` and `443/tcp`
- At least 4 GB of memory for initial testnet use
- Persistent storage for the node and Blockbook databases

Blockbook compilation and initial indexing can require more memory and storage.

## Install

Clone the repository:

```bash
git clone git@github.com:OrganicLifeCoin/organic-server-stack.git
cd organic-server-stack
```

Run the guarded installer:

```bash
./scripts/install.sh
```

The installer creates `.env` and two private RPC secret files. It then validates, builds, and starts the stack.

Read the service state:

```bash
docker compose ps
```

Read the gateway health response:

```bash
curl --fail http://127.0.0.1/healthz
```

Open `http://SERVER_ADDRESS/` for the wallet. Open `http://SERVER_ADDRESS/blocks` for the explorer.

## Public routes

| Route | Service |
| --- | --- |
| `/` | OLC web wallet |
| `/mainnet*` and `/testnet*` | Restricted RPC bridge |
| `/api*` and `/websocket` | Blockbook API |
| `/blocks`, `/block/*`, `/tx/*`, `/address/*` | OLC explorer |
| `/sapling-output.params` | Sapling output parameters |
| `/sapling-spend.params` | Sapling spend parameters |

## Operations

- [Deployment](docs/deployment.md)
- [Backup and restore](docs/backup-and-restore.md)
- [Cloudflare and HTTPS](docs/cloudflare.md)

Run all repository checks:

```bash
make check
```

Render the resolved Compose configuration:

```bash
make compose-config
```

## Mainnet promotion

This release is testnet-only. Do not change `NETWORK` to `mainnet` with the current node release.

Publish a reviewed mainnet Core release first. Then update its release tag, architecture digests, ports, and companion repository pins in one commit.

## License

Deployment files in this repository use the MIT license. Each companion repository retains its own license and upstream notices.
