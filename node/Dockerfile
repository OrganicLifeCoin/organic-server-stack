FROM debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171 AS fetch

ARG TARGETARCH
ARG NODE_RELEASE
ARG NODE_AMD64_SHA256
ARG NODE_ARM64_SHA256

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    case "$TARGETARCH" in \
        amd64) release_arch=amd64; archive_sha256="$NODE_AMD64_SHA256" ;; \
        arm64) release_arch=aarch64; archive_sha256="$NODE_ARM64_SHA256" ;; \
        *) printf 'Unsupported architecture: %s\n' "$TARGETARCH" >&2; exit 1 ;; \
    esac; \
    archive="OrganicLife-linux-${release_arch}-daemon.zip"; \
    url="https://github.com/OrganicLifeCoin/OrganLife-Core/releases/download/${NODE_RELEASE}/${archive}"; \
    mkdir -p /release; \
    curl --fail --location --silent --show-error "$url" --output "/tmp/$archive"; \
    printf '%s  %s\n' "$archive_sha256" "/tmp/$archive" | sha256sum --check --strict; \
    unzip -q "/tmp/$archive" -d /release; \
    test -x /release/organiclifed; \
    test -x /release/organiclife-cli; \
    test -s /release/params/sapling-spend.params; \
    test -s /release/params/sapling-output.params; \
    rm "/tmp/$archive"

FROM debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 organiclife \
    && useradd --system --uid 10001 --gid organiclife --home-dir /data --shell /usr/sbin/nologin organiclife

COPY --from=fetch /release/organiclifed /usr/local/bin/organiclifed
COPY --from=fetch /release/organiclife-cli /usr/local/bin/organiclife-cli
COPY --from=fetch /release/organiclife-tx /usr/local/bin/organiclife-tx
COPY --from=fetch /release/params/ /opt/organiclifecoin/params/
COPY entrypoint.sh /usr/local/bin/organiclife-entrypoint

RUN chmod 0755 /usr/local/bin/organiclife-entrypoint \
    && mkdir -p /data /runtime \
    && chown -R organiclife:organiclife /data /runtime

USER organiclife

VOLUME ["/data"]
EXPOSE 38349 49716 49718

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=10 \
    CMD organiclife-cli -conf=/runtime/organiclife.conf -datadir=/data getblockchaininfo >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/organiclife-entrypoint"]
