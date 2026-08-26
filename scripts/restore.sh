#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 || "$2" != '--confirm-restore' ]]; then
    printf 'Usage: %s BACKUP_DIRECTORY --confirm-restore\n' "$0" >&2
    exit 1
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
backup_dir=$(cd "$1" && pwd)
cd "$repo_root"

if [[ ! -f "$backup_dir/SHA256SUMS" ]]; then
    printf 'The backup checksum file is missing.\n' >&2
    exit 1
fi

(
    cd "$backup_dir"
    sha256sum --check SHA256SUMS
)

volume_names=(node-data blockbook-data shield-data caddy-data caddy-config)
for volume_name in "${volume_names[@]}"; do
    if [[ ! -f "$backup_dir/${volume_name}.tar.gz" ]]; then
        printf 'Missing backup archive: %s.tar.gz\n' "$volume_name" >&2
        exit 1
    fi
done

docker compose stop

for volume_name in "${volume_names[@]}"; do
    docker volume create "organic-server-stack_${volume_name}" >/dev/null
    docker run --rm \
        --volume "organic-server-stack_${volume_name}:/target" \
        --volume "$backup_dir:/backup:ro" \
        alpine:3.22.1@sha256:4bcff63911fcb4448bd4fdacec207030997caf25e9bea4045fa6c8c44de311d1 \
        sh -eu -c "find /target -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; tar -C /target -xzf '/backup/${volume_name}.tar.gz'"
done

docker compose up -d
printf 'Restore complete.\n'
