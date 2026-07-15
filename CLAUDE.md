# OpenList custom (dblclick seek) — project rules

## Conda environment isolation (mandatory)

Project env name: **`openlist`**

```bash
# Create once (Node/Go: use conda-forge if needed; system Node 20+ is OK for local)
conda create -n openlist python=3.10 -y
# optional:
# conda install -n openlist -c conda-forge nodejs go -y

# Always wrap project python/shell helpers:
conda run -n openlist bash scripts/resolve-upstream-versions.sh
conda run -n openlist bash scripts/apply-frontend-custom.sh /path/to/frontend

# Frontend build (pnpm via corepack; prefer conda env PATH if node installed there):
conda run -n openlist --no-capture-output bash -lc 'corepack enable && cd /path/to/frontend && pnpm i && pnpm build'
```

Never run bare project scripts without `conda run -n openlist` when they use the env.

CI (GitHub Actions) uses `actions/setup-node` and `actions/setup-go` instead of conda.

## What this repo is

Patch layer on top of official OpenList:

- Upstream backend: https://github.com/OpenListTeam/OpenList (AGPL-3.0)
- Upstream frontend: https://github.com/OpenListTeam/OpenList-Frontend (MIT)
- Customization:
  - ArtPlayer double-click left/right seek ±10s
  - Mobile native fullscreen: prefer `orientation.lock`, CSS rotate fallback

## Key paths

- `patches/frontend/001-dblclick-seek.patch` — dblclick seek + `DBCLICK_FULLSCREEN=false`
- `patches/frontend/002-default-lang-zh-CN.patch` — default UI lang zh-CN
- `patches/frontend/003-fullscreen-orientation.patch` — native FS landscape fallback (after 001)
- `patches/frontend/004-hide-pip-mobile.patch` — disable ArtPlayer pip on mobile so native FS button stays visible
- `overlay/frontend/.../dblclick-seek.ts` — source of the seek helper
- `overlay/frontend/.../fullscreen-orientation.ts` — native FS orientation helper
- `scripts/apply-frontend-custom.sh` — apply patches (lexical order) + overlay copy
- `scripts/build-backend-with-dist.sh` — embed custom dist + go build
- `.github/workflows/build-docker.yml` — track upstream + push GHCR

## Refreshing patches after upstream breaks apply

```bash
git clone --depth 1 --branch <frontend_tag> https://github.com/OpenListTeam/OpenList-Frontend.git /tmp/fe
# 1) Refresh 001 first (seek): edit video.tsx / aliyun_video.tsx / video_box.tsx + dblclick-seek.ts
cd /tmp/fe
git add -N src/pages/home/previews/dblclick-seek.ts
git diff > /path/to/this/repo/patches/frontend/001-dblclick-seek.patch

# 2) Commit or re-apply 001(+002), then refresh 003 only:
#    add fullscreen-orientation.ts + enableFullscreenOrientation wire-in
git add -N src/pages/home/previews/fullscreen-orientation.ts
git diff -- src/pages/home/previews/fullscreen-orientation.ts \
  src/pages/home/previews/video.tsx src/pages/home/previews/aliyun_video.tsx \
  > /path/to/this/repo/patches/frontend/003-fullscreen-orientation.patch
```
