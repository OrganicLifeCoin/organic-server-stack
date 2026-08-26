#!/bin/sh
set -eu

umask 077

network=${NETWORK:-testnet}
if [ "$network" != "testnet" ]; then
    printf 'This pinned node release supports the approved testnet deployment only.\n' >&2
    exit 1
fi

rpc_user_file=${NODE_RPC_USER_FILE:-/run/secrets/node_rpc_user}
rpc_password_file=${NODE_RPC_PASSWORD_FILE:-/run/secrets/node_rpc_password}

if [ ! -r "$rpc_user_file" ] || [ ! -r "$rpc_password_file" ]; then
    printf 'The node RPC secret files are not readable.\n' >&2
    exit 1
fi

rpc_user=$(cat "$rpc_user_file")
rpc_password=$(cat "$rpc_password_file")

case "$rpc_user" in
    ''|*[!A-Za-z0-9._-]*)
        printf 'The node RPC user contains an invalid character.\n' >&2
        exit 1
        ;;
esac

if [ "${#rpc_password}" -lt 24 ]; then
    printf 'The node RPC password must contain at least 24 characters.\n' >&2
    exit 1
fi

single_line_password=$(printf '%s' "$rpc_password" | tr -d '\r\n')
if [ "$rpc_password" != "$single_line_password" ]; then
    printf 'The node RPC password contains a line break.\n' >&2
    exit 1
fi

rpc_port=${NODE_RPC_PORT:-49718}
p2p_port=${NODE_P2P_PORT:-49716}
rpc_threads=${NODE_RPC_THREADS:-8}
rpc_work_queue=${NODE_RPC_WORK_QUEUE:-64}
config_path=/runtime/organiclife.conf
temporary_config=/runtime/organiclife.conf.tmp

cat >"$temporary_config" <<EOF
testnet=1
server=1
txindex=1
daemon=0
printtoconsole=1
listen=1
port=$p2p_port
rpcport=$rpc_port
rpcbind=0.0.0.0
rpcallowip=172.29.0.0/24
rpcuser=$rpc_user
rpcpassword=$rpc_password
rpcthreads=$rpc_threads
rpcworkqueue=$rpc_work_queue
zmqpubhashblock=tcp://0.0.0.0:38349
zmqpubhashtx=tcp://0.0.0.0:38349
EOF

chmod 0600 "$temporary_config"
mv "$temporary_config" "$config_path"

unset rpc_user rpc_password single_line_password

exec organiclifed \
    -conf="$config_path" \
    -datadir=/data \
    -paramsdir=/opt/organiclifecoin/params
