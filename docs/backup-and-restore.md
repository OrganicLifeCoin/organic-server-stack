# Backup and Restore

The node and Blockbook can rebuild their databases from the blockchain. A backup reduces recovery time.

## Create a backup

Run:

```bash
./scripts/backup.sh
```

The script stops the stack before it reads the volumes. This action gives each archive a consistent filesystem state.

The script writes archives and `SHA256SUMS` under `backups/TIMESTAMP/`. Copy that directory to encrypted storage on another host.

## Restore a backup

CAUTION: A restore replaces all data in the target Docker volumes.

Stop other maintenance tasks. Then run:

```bash
./scripts/restore.sh backups/TIMESTAMP --confirm-restore
```

The script verifies all archive checksums before it changes a volume. It then replaces the selected volume contents and starts the stack.

Keep the `.env` file and `.secrets` directory in a separate encrypted backup. The data archive does not include these files.
