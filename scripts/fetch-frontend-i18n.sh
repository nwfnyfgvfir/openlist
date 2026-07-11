#!/usr/bin/env bash
# Download official OpenList-Frontend i18n.tar.gz into a frontend checkout.
# Git source only ships English; other locales come from release assets.
set -euo pipefail

TARGET="${1:-}"
TAG="${2:-${FRONTEND_REF:-}}"
FRONTEND_REPO="${FRONTEND_REPO:-OpenListTeam/OpenList-Frontend}"

if [[ -z "${TARGET}" ]]; then
  echo "Usage: $0 <path-to-OpenList-Frontend-checkout> [release-tag]"
  exit 1
fi

if [[ ! -d "${TARGET}/src/lang" ]]; then
  echo "Error: ${TARGET} does not look like OpenList-Frontend (missing src/lang)"
  exit 1
fi

if [[ -z "${TAG}" ]]; then
  if git -C "${TARGET}" describe --tags --exact-match >/dev/null 2>&1; then
    TAG="$(git -C "${TARGET}" describe --tags --exact-match)"
  else
    TAG="$(git -C "${TARGET}" describe --tags --abbrev=0 2>/dev/null || true)"
  fi
fi

if [[ -z "${TAG}" ]]; then
  echo "Error: could not determine frontend release tag (pass as \$2 or FRONTEND_REF)"
  exit 1
fi

# Accept "4.2.3" or "v4.2.3"
if [[ "${TAG}" != v* ]]; then
  TAG="v${TAG}"
fi

auth_args=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  auth_args=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

URL="https://github.com/${FRONTEND_REPO}/releases/download/${TAG}/i18n.tar.gz"
TMP="$(mktemp)"
cleanup() { rm -f "${TMP}"; }
trap cleanup EXIT

echo "==> Fetching i18n for ${TAG}"
echo "    ${URL}"
if ! curl -fsSL "${auth_args[@]}" -o "${TMP}" "${URL}"; then
  echo "Error: failed to download i18n.tar.gz for ${TAG}"
  echo "Without this archive the UI only has English."
  exit 2
fi

if ! tar -tzf "${TMP}" >/dev/null 2>&1; then
  echo "Error: downloaded file is not a valid tar.gz"
  exit 2
fi

tar -xzf "${TMP}" -C "${TARGET}/src/lang"

if [[ ! -f "${TARGET}/src/lang/zh-CN/index.json" ]]; then
  echo "Error: after extract, src/lang/zh-CN/index.json is missing"
  echo "Contents of src/lang:"
  ls -la "${TARGET}/src/lang" || true
  exit 3
fi

echo "==> i18n installed (zh-CN present)"
ls -1 "${TARGET}/src/lang" | tr '\n' ' '
echo
