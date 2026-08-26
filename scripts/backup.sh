#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"
umask 077

if ! command -v docker >/dev/null 2>&1; then
    printf 'Docker is required.\n' >&2
    exit 1
fi

timestamp=$(date -u '+%Y%m%dT%H%M%SZ')
backup_dir="$repo_root/backups/$timestamp"
mkdir -p "$backup_dir"

stack_stopped=false
restart_stack() {
    if [[ "$stack_stopped" == true ]]; then
        docker compose up -d >/dev/null
    fi
}
trap restart_stack EXIT

docker compose stop
stack_stopped=true

volume_names=(node-data blockbook-data shield-data caddy-data caddy-config)
for volume_name in "${volume_names[@]}"; do
    docker run --rm \
        --volume "organic-server-stack_${volume_name}:/source:ro" \
        --volume "$backup_dir:/backup" \
        alpine:3.22.1@sha256:4bcff63911fcb4448bd4fdacec207030997caf25e9bea4045fa6c8c44de311d1 \
        tar -C /source -czf "/backup/${volume_name}.tar.gz" .
done

(
    cd "$backup_dir"
    sha256sum ./*.tar.gz >SHA256SUMS
)

docker compose up -d
stack_stopped=false
trap - EXIT

printf 'Backup created: %s\n' "$backup_dir"
