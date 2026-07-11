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
- Customization: ArtPlayer double-click left/right seek ±10s

## Key paths

- `patches/frontend/001-dblclick-seek.patch` — apply onto frontend checkout
- `overlay/frontend/.../dblclick-seek.ts` — source of the seek helper
- `scripts/apply-frontend-custom.sh` — apply patches
- `scripts/build-backend-with-dist.sh` — embed custom dist + go build
- `.github/workflows/build-docker.yml` — track upstream + push GHCR

## Refreshing patches after upstream breaks apply

```bash
git clone --depth 1 --branch <frontend_tag> https://github.com/OpenListTeam/OpenList-Frontend.git /tmp/fe
# re-apply manual edits to video.tsx / aliyun_video.tsx / video_box.tsx + add dblclick-seek.ts
cd /tmp/fe
git add -N src/pages/home/previews/dblclick-seek.ts
git diff > /path/to/this/repo/patches/frontend/001-dblclick-seek.patch
```
