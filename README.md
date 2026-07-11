# OpenList 自定义镜像（双击左右快进）

基于官方 [OpenList](https://github.com/OpenListTeam/OpenList) / [OpenList-Frontend](https://github.com/OpenListTeam/OpenList-Frontend) 的**补丁层仓库**。

GitHub Actions 自动：

1. 拉取上游最新 release  
2. 注入官方多语言包（`i18n.tar.gz`，含简体中文）  
3. 给在线播放器打上「双击左半屏 -10s / 右半屏 +10s」；默认界面语言 **简体中文（zh-CN）**  
4. 构建前端并嵌入后端  
5. 推送 Docker 镜像到 **GHCR**（`linux/amd64`）

## 播放器行为

| 操作 | 行为 |
|------|------|
| 双击视频**左半屏** | 后退 10 秒 |
| 双击视频**右半屏** | 前进 10 秒 |
| 单击 | 保持 ArtPlayer 默认（桌面播放/暂停） |
| 原「双击全屏」 | 关闭，请用全屏按钮 / 快捷键 |
| 长按加速 | 保留官方 `fastForward` |

## 界面语言

- 默认：**简体中文（zh-CN）**（浏览器语言匹配时仍优先浏览器）  
- 构建时从上游 release 拉取 `i18n.tar.gz`，否则源码树只有英文  
- 若浏览器里以前选过英文，会记住 `localStorage.lang`；要改回中文可在界面语言菜单切换，或清除本站 localStorage 后刷新  

修改文件（上游路径）：

- `src/pages/home/previews/dblclick-seek.ts`（新增）
- `src/pages/home/previews/video.tsx`
- `src/pages/home/previews/aliyun_video.tsx`
- `src/pages/home/previews/video_box.tsx`（关闭 `DBCLICK_FULLSCREEN`）
- `src/app/i18n.ts` / `src/components/SwitchLanguage.tsx`（默认 zh-CN）

## 镜像

```text
ghcr.io/<你的GitHub用户名或组织>/openlist:latest
ghcr.io/<...>/openlist:upstream-<backend_tag>
ghcr.io/<...>/openlist:fe-<frontend_tag>
```

## 运行（Docker Compose，推荐）

仓库以 **docker compose** 为唯一推荐运行方式。

```bash
cd /path/to/openlist

# 1. 配置镜像所有者（小写 GitHub 用户名/组织）
cp .env.example .env
# 编辑 .env：GHCR_OWNER=your-github-username

# 2. 若 GHCR package 为 private，先登录
# echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 3. 拉取并启动
docker compose pull
docker compose up -d

# 4. 首次管理员密码在日志里
docker compose logs openlist | head -50

# 浏览器打开
# http://localhost:5244
```

常用命令：

```bash
docker compose ps
docker compose logs -f openlist
docker compose pull && docker compose up -d   # 更新镜像后重启
docker compose down                           # 停止（保留 ./data）
```

`.env` 可调项见 `.env.example`：`GHCR_OWNER`、`OPENLIST_TAG`、`OPENLIST_PORT`、`OPENLIST_DATA`。

## 启用 GitHub Actions（先构建镜像再 compose）

1. 将本仓库 push 到 GitHub（建议 public，便于 GHCR 拉取）  
2. 仓库 **Settings → Actions → General**：允许 workflow 读写  
3. **Settings → Packages**：构建后在 package 设置中将 visibility 设为 public（可选）  
4. 打开 **Actions → Build & Push OpenList Docker → Run workflow**  
5. 成功后按上文 `docker compose up -d`

定时任务：每天 UTC 02:00 检查上游；版本+补丁未变时可跳过重建。

手动指定版本：`workflow_dispatch` 输入 `backend_ref` / `frontend_ref`。

## 本地（Conda）

```bash
conda create -n openlist python=3.10 -y

# 解析版本
conda run -n openlist bash scripts/resolve-upstream-versions.sh

# 检出上游前端并打补丁
git clone --depth 1 --branch v4.2.3 \
  https://github.com/OpenListTeam/OpenList-Frontend.git /tmp/ol-fe
conda run -n openlist bash scripts/apply-frontend-custom.sh /tmp/ol-fe

# 构建前端（需 Node 20+ 与 pnpm；corepack enable）
cd /tmp/ol-fe && corepack enable && pnpm i && pnpm build
```

完整 Docker 构建建议直接走 GitHub Actions。

## 上游补丁冲突时

CI 的 `apply-frontend-custom` 会失败并提示。按 `CLAUDE.md` 中「Refreshing patches」流程，针对新 tag 重新生成 `patches/frontend/001-dblclick-seek.patch`。

## 许可与声明

- 后端上游：[OpenList](https://github.com/OpenListTeam/OpenList) **AGPL-3.0**  
- 前端上游：[OpenList-Frontend](https://github.com/OpenListTeam/OpenList-Frontend) **MIT**  
- 本仓库仅包含补丁、构建脚本与 CI；使用/分发请遵守上游协议。  
- 与 OpenList Team 无官方关联，仅为个人定制构建。
