#!/usr/bin/env bash
# Apply OpenList-Frontend customizations (dblclick seek + native FS orientation)
# onto a checkout.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-}"

if [[ -z "${TARGET}" ]]; then
  echo "Usage: $0 <path-to-OpenList-Frontend-checkout>"
  exit 1
fi

if [[ ! -d "${TARGET}/src/pages/home/previews" ]]; then
  echo "Error: ${TARGET} does not look like OpenList-Frontend (missing src/pages/home/previews)"
  exit 1
fi

PATCH_DIR="${ROOT}/patches/frontend"
OVERLAY="${ROOT}/overlay/frontend"

echo "==> Applying frontend customizations to: ${TARGET}"

# Prefer unified patches (includes new file + wiring). Lexical order: 001 → 002 → 003.
shopt -s nullglob
patches=("${PATCH_DIR}"/*.patch)
if ((${#patches[@]} > 0)); then
  for p in "${patches[@]}"; do
    echo "    git apply $(basename "$p")"
    # --whitespace=nowarn: upstream may change indentation slightly
    if ! git -C "${TARGET}" apply --check "${p}" 2>/dev/null; then
      # try from TARGET as cwd with -p1 if needed
      if ! (cd "${TARGET}" && patch -p1 --dry-run <"${p}" >/dev/null 2>&1); then
        echo "ERROR: patch failed to apply: ${p}"
        echo "Upstream frontend likely changed video.tsx / aliyun_video.tsx / video_box.tsx."
        echo "Refresh the patch against the new tag and re-run."
        exit 2
      fi
      (cd "${TARGET}" && patch -p1 <"${p}")
    else
      git -C "${TARGET}" apply "${p}"
    fi
  done
else
  echo "No patches found under ${PATCH_DIR}; copying overlay only."
fi

# Ensure overlay helpers exist even if a patch only wired imports (idempotent).
mkdir -p "${TARGET}/src/pages/home/previews"
if [[ -d "${OVERLAY}/src/pages/home/previews" ]]; then
  shopt -s nullglob
  for f in "${OVERLAY}/src/pages/home/previews"/*; do
    base="$(basename "$f")"
    if [[ ! -f "${TARGET}/src/pages/home/previews/${base}" ]]; then
      echo "    copy overlay ${base}"
      cp "${f}" "${TARGET}/src/pages/home/previews/${base}"
    fi
  done
fi

# Sanity checks
grep -q 'enableDblclickSeek' "${TARGET}/src/pages/home/previews/video.tsx" \
  || { echo "ERROR: video.tsx not wired (dblclick)"; exit 3; }
grep -q 'enableDblclickSeek' "${TARGET}/src/pages/home/previews/aliyun_video.tsx" \
  || { echo "ERROR: aliyun_video.tsx not wired (dblclick)"; exit 3; }
test -f "${TARGET}/src/pages/home/previews/dblclick-seek.ts" \
  || { echo "ERROR: dblclick-seek.ts missing"; exit 3; }

if [[ -f "${PATCH_DIR}/003-fullscreen-orientation.patch" ]]; then
  grep -q 'enableFullscreenOrientation' "${TARGET}/src/pages/home/previews/video.tsx" \
    || { echo "ERROR: video.tsx not wired (fullscreen orientation)"; exit 3; }
  grep -q 'enableFullscreenOrientation' "${TARGET}/src/pages/home/previews/aliyun_video.tsx" \
    || { echo "ERROR: aliyun_video.tsx not wired (fullscreen orientation)"; exit 3; }
  test -f "${TARGET}/src/pages/home/previews/fullscreen-orientation.ts" \
    || { echo "ERROR: fullscreen-orientation.ts missing"; exit 3; }
fi

echo "==> Frontend customizations applied successfully"
