# Deployment

## Prepare the server

Install Docker Engine and the Compose plugin from the Docker package repository.

Create a dedicated directory:

```bash
sudo install -d -o "$USER" -g "$USER" /opt/organic-server-stack
git clone git@github.com:OrganicLifeCoin/organic-server-stack.git /opt/organic-server-stack
cd /opt/organic-server-stack
```

## Configure testnet

Run the installer:

```bash
./scripts/install.sh
```

The installer copies `.env.example` to `.env`. It also creates a random RPC password with restrictive permissions.

Review `.env`. Keep `NETWORK=testnet` for this release.

Validate the resolved configuration:

```bash
docker compose --env-file .env config --quiet
```

## Start the stack

Build and start all services:

```bash
docker compose up -d --build
```

Read the service health state:

```bash
docker compose ps
```

Read node synchronization data:

```bash
docker compose exec node organiclife-cli \
  -conf=/runtime/organiclife.conf \
  -datadir=/data \
  getblockchaininfo
```

Wait for the node before you evaluate Blockbook synchronization. Initial indexing can take a long time.

## Install the systemd unit

Copy the supplied unit:

```bash
sudo cp deploy/systemd/organic-server-stack.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now organic-server-stack.service
```

The unit expects the repository at `/opt/organic-server-stack`.

## Update the stack

1. Back up the persistent volumes.
2. Fetch the reviewed repository commit.
3. Review all changed source pins.
4. Run `make check`.
5. Run `docker compose build --pull`.
6. Run `docker compose up -d --remove-orphans`.
7. Make sure that all health checks pass.
8. Make sure that the wallet and explorer work on testnet.

Do not use mutable branches for a release deployment.
