#!/usr/bin/env bash
# Local smoke: resolve tags → patch frontend → build frontend → build backend binary.
# Does not require Docker registry access.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${WORK_DIR:-/tmp/openlist-smoke}"
export PATH="${PATH}"

echo "==> Resolve upstream versions"
# shellcheck disable=SC1091
eval "$("${ROOT}/scripts/resolve-upstream-versions.sh" | sed 's/^/export /')"
echo "    backend=${BACKEND_REF} frontend=${FRONTEND_REF}"

rm -rf "${WORK}"
mkdir -p "${WORK}"

echo "==> Clone frontend ${FRONTEND_REF}"
git clone --depth 1 --branch "${FRONTEND_REF}" \
  "https://github.com/${FRONTEND_REPO}.git" "${WORK}/frontend"

echo "==> Apply patches"
bash "${ROOT}/scripts/apply-frontend-custom.sh" "${WORK}/frontend"

echo "==> Fetch official i18n (zh-CN, etc.)"
bash "${ROOT}/scripts/fetch-frontend-i18n.sh" "${WORK}/frontend" "${FRONTEND_REF}"

echo "==> Build frontend"
(
  cd "${WORK}/frontend"
  corepack enable
  corepack prepare --activate || true
  pnpm install --frozen-lockfile || pnpm install
  pnpm build
  test -f dist/index.html
  test -d src/lang/zh-CN
)

echo "==> Clone backend ${BACKEND_REF}"
git clone --depth 1 --branch "${BACKEND_REF}" \
  "https://github.com/${BACKEND_REPO}.git" "${WORK}/backend"

echo "==> Build backend binary"
VERSION="${BACKEND_REF}" WEB_VERSION="${FRONTEND_REF}+dblseek" \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  bash "${ROOT}/scripts/build-backend-with-dist.sh" \
    "${WORK}/backend" \
    "${WORK}/frontend/dist" \
    "${WORK}/openlist"

"${WORK}/openlist" version
echo "==> Smoke OK: ${WORK}/openlist"
