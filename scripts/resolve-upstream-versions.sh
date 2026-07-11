#!/usr/bin/env bash
# Resolve upstream OpenList backend/frontend tags.
# Outputs shell-assignable KEY=value lines (and optionally GitHub Actions outputs).
set -euo pipefail

BACKEND_REPO="${BACKEND_REPO:-OpenListTeam/OpenList}"
FRONTEND_REPO="${FRONTEND_REPO:-OpenListTeam/OpenList-Frontend}"
BACKEND_REF="${BACKEND_REF:-}"
FRONTEND_REF="${FRONTEND_REF:-}"

auth_header=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  auth_header=(-H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28")
fi

latest_tag() {
  local repo="$1"
  curl -fsSL "${auth_header[@]}" \
    "https://api.github.com/repos/${repo}/releases/latest" \
    | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tag_name",""))'
}

if [[ -z "${BACKEND_REF}" ]]; then
  BACKEND_REF="$(latest_tag "${BACKEND_REPO}")"
fi
if [[ -z "${FRONTEND_REF}" ]]; then
  FRONTEND_REF="$(latest_tag "${FRONTEND_REPO}")"
fi

if [[ -z "${BACKEND_REF}" || -z "${FRONTEND_REF}" ]]; then
  echo "Failed to resolve upstream tags" >&2
  exit 1
fi

echo "BACKEND_REPO=${BACKEND_REPO}"
echo "FRONTEND_REPO=${FRONTEND_REPO}"
echo "BACKEND_REF=${BACKEND_REF}"
echo "FRONTEND_REF=${FRONTEND_REF}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "backend_repo=${BACKEND_REPO}"
    echo "frontend_repo=${FRONTEND_REPO}"
    echo "backend_ref=${BACKEND_REF}"
    echo "frontend_ref=${FRONTEND_REF}"
  } >>"${GITHUB_OUTPUT}"
fi
