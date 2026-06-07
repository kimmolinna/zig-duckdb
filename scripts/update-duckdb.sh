#!/usr/bin/env bash
set -euo pipefail

DUCKDB_VERSION="${DUCKDB_VERSION:-v1.5.3}"
ARCH="${ARCH:-linux-amd64}"

case "${ARCH}" in
    linux-amd64)
        SHA256="0a926eba5bce0abc0010f4b9109133e4440cb74e97bd10fd2d0fc2a721621b05"
        ;;
    linux-arm64)
        SHA256=""
        ;;
    linux-amd64-musl)
        SHA256=""
        ;;
    *)
        echo "Unsupported arch: ${ARCH}" >&2
        echo "Supported: linux-amd64, linux-arm64, linux-amd64-musl" >&2
        exit 1
        ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${ROOT}/duckdb"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

URL="https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VERSION}/libduckdb-${ARCH}.zip"
ZIP="${TMPDIR}/libduckdb.zip"

echo "Downloading DuckDB ${DUCKDB_VERSION} (${ARCH})..."
curl -fsSL -o "${ZIP}" "${URL}"

if [[ -n "${SHA256}" ]]; then
    echo "Verifying SHA256..."
    echo "${SHA256}  ${ZIP}" | sha256sum -c -
fi

mkdir -p "${DEST}"
if command -v unzip >/dev/null 2>&1; then
    unzip -o "${ZIP}" -d "${DEST}"
else
    python3 -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "${ZIP}" "${DEST}"
fi

echo "Updated ${DEST}:"
ls -lh "${DEST}/duckdb.h" "${DEST}/libduckdb.so"
