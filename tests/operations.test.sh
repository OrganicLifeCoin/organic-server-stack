#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

required_files=(
    README.md
    LICENSE
    NOTICE
    CONTRIBUTING.md
    SECURITY.md
    docs/deployment.md
    docs/backup-and-restore.md
    docs/cloudflare.md
    scripts/install.sh
    scripts/backup.sh
    scripts/restore.sh
    deploy/systemd/organic-server-stack.service
)

for path in "${required_files[@]}"; do
    if [[ ! -f "$repo_root/$path" ]]; then
        printf 'Missing operations file: %s\n' "$path" >&2
        exit 1
    fi
done

for script in scripts/install.sh scripts/backup.sh scripts/restore.sh; do
    if ! rg -q '^set -euo pipefail$' "$repo_root/$script"; then
        printf '%s does not enable strict Bash behavior.\n' "$script" >&2
        exit 1
    fi
done

if ! rg -q -- '--confirm-restore' "$repo_root/scripts/restore.sh"; then
    printf 'The restore script lacks explicit destructive confirmation.\n' >&2
    exit 1
fi

if ! rg -q 'sha256sum.*--check' "$repo_root/scripts/restore.sh"; then
    printf 'The restore script does not verify backup checksums.\n' >&2
    exit 1
fi

if ! rg -q 'chmod 0600' "$repo_root/scripts/install.sh"; then
    printf 'The install script does not restrict secret files.\n' >&2
    exit 1
fi

if ! rg -q '^umask 077$' "$repo_root/scripts/backup.sh"; then
    printf 'The backup script does not create private archives.\n' >&2
    exit 1
fi

if ! rg -q 'OrganicLifeCoin/organic-web-wallet' "$repo_root/README.md" \
    || ! rg -q 'OrganicLifeCoin/organic-rpc-bridge' "$repo_root/README.md" \
    || ! rg -q 'OrganicLifeCoin/organic-blockbook' "$repo_root/README.md" \
    || ! rg -q 'OrganicLifeCoin/OrganLife-Core' "$repo_root/README.md"; then
    printf 'The README does not identify all source repositories.\n' >&2
    exit 1
fi

if ! rg -qi 'firewall.*Cloudflare|Cloudflare.*firewall' "$repo_root/docs/cloudflare.md"; then
    printf 'The Cloudflare guide does not restrict direct origin access.\n' >&2
    exit 1
fi

printf 'Operations checks passed.\n'
