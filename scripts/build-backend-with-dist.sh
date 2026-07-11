#!/usr/bin/env bash
# Build OpenList backend binary with a pre-built frontend dist already in place.
# Does NOT fetch official frontend releases (so our patched UI is kept).
set -euo pipefail

BACKEND_DIR="${1:-}"
DIST_DIR="${2:-}"
OUT_BIN="${3:-}"
VERSION="${VERSION:-custom}"
WEB_VERSION="${WEB_VERSION:-custom-dblseek}"

if [[ -z "${BACKEND_DIR}" || -z "${DIST_DIR}" || -z "${OUT_BIN}" ]]; then
  echo "Usage: $0 <backend-src> <frontend-dist-dir> <output-binary-path>"
  exit 1
fi

if [[ ! -f "${BACKEND_DIR}/main.go" && ! -f "${BACKEND_DIR}/go.mod" ]]; then
  echo "Error: ${BACKEND_DIR} is not an OpenList backend checkout"
  exit 1
fi
if [[ ! -f "${DIST_DIR}/index.html" ]]; then
  echo "Error: ${DIST_DIR} does not look like a Vite dist (missing index.html)"
  exit 1
fi

# Replace any existing dist
rm -rf "${BACKEND_DIR}/public/dist"
mkdir -p "${BACKEND_DIR}/public/dist"
cp -a "${DIST_DIR}/." "${BACKEND_DIR}/public/dist/"

builtAt="$(date +'%F %T %z')"
gitAuthor="OpenList dblclick-seek custom build"
gitCommit="unknown"
if git -C "${BACKEND_DIR}" rev-parse --short HEAD >/dev/null 2>&1; then
  gitCommit="$(git -C "${BACKEND_DIR}" rev-parse --short HEAD)"
fi

# Same style as official OpenList build.sh — single string, single-quoted -X values
ldflags="\
-w -s \
-X 'github.com/OpenListTeam/OpenList/v4/internal/conf.BuiltAt=${builtAt}' \
-X 'github.com/OpenListTeam/OpenList/v4/internal/conf.GitAuthor=${gitAuthor}' \
-X 'github.com/OpenListTeam/OpenList/v4/internal/conf.GitCommit=${gitCommit}' \
-X 'github.com/OpenListTeam/OpenList/v4/internal/conf.Version=${VERSION}' \
-X 'github.com/OpenListTeam/OpenList/v4/internal/conf.WebVersion=${WEB_VERSION}' \
"

mkdir -p "$(dirname "${OUT_BIN}")"
echo "==> go build -> ${OUT_BIN}"
(
  cd "${BACKEND_DIR}"
  CGO_ENABLED="${CGO_ENABLED:-0}" GOOS="${GOOS:-linux}" GOARCH="${GOARCH:-amd64}" \
    go build -o "${OUT_BIN}" -ldflags="${ldflags}" -tags=jsoniter .
)

chmod +x "${OUT_BIN}"
echo "==> Built $(du -h "${OUT_BIN}" | awk '{print $1}') ${OUT_BIN}"
