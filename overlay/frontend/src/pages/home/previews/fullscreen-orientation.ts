import Artplayer from "artplayer"

const CSS_CLASS = "openlist-fs-orientation"
/** Wait for built-in autoOrientation lock + layout settle before CSS fallback. */
const SETTLE_MS = 200
const METADATA_WAIT_MS = 1000

const MOBILE_RE =
  /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|Mobile/i

function isMobile(): boolean {
  return MOBILE_RE.test(navigator.userAgent || "")
}

function needRotate(player: Artplayer): boolean {
  const video = player.template.$video
  if (!video) return false
  const { videoWidth, videoHeight } = video
  if (!videoWidth || !videoHeight) return false
  const sw = document.documentElement.clientWidth
  const sh = document.documentElement.clientHeight
  return (
    (videoWidth > videoHeight && sw < sh) ||
    (videoWidth < videoHeight && sw > sh)
  )
}

function applyCssRotate(player: Artplayer) {
  const $player = player.template.$player
  if (!$player || $player.classList.contains(CSS_CLASS)) return

  const viewWidth = document.documentElement.clientWidth
  const viewHeight = document.documentElement.clientHeight
  // Same geometry as ArtPlayer autoOrientation web-fullscreen path.
  $player.style.width = `${viewHeight}px`
  $player.style.height = `${viewWidth}px`
  $player.style.transformOrigin = "0 0"
  $player.style.transform = `rotate(90deg) translate(0, -${viewWidth}px)`
  $player.classList.add(CSS_CLASS)
  // ArtPlayer marks isRotate as readonly in types; runtime field is writable.
  ;(player as Artplayer & { isRotate: boolean }).isRotate = true
  player.emit("resize")
}

function clearCssRotate(player: Artplayer) {
  const $player = player.template.$player
  if (!$player || !$player.classList.contains(CSS_CLASS)) return

  $player.style.width = ""
  $player.style.height = ""
  $player.style.transformOrigin = ""
  $player.style.transform = ""
  $player.classList.remove(CSS_CLASS)
  ;(player as Artplayer & { isRotate: boolean }).isRotate = false
  player.emit("resize")
}

function waitForVideoSize(player: Artplayer): Promise<void> {
  const video = player.template.$video
  if (!video) return Promise.resolve()
  if (video.videoWidth > 0 && video.videoHeight > 0) return Promise.resolve()

  return new Promise((resolve) => {
    let done = false
    const finish = () => {
      if (done) return
      done = true
      video.removeEventListener("loadedmetadata", finish)
      window.clearTimeout(timer)
      resolve()
    }
    const timer = window.setTimeout(finish, METADATA_WAIT_MS)
    video.addEventListener("loadedmetadata", finish)
  })
}

/**
 * Native fullscreen landscape enhancement for mobile:
 * 1) Prefer screen.orientation.lock matching video aspect.
 * 2) If lock fails / unavailable / system rotation locked, CSS-rotate
 *    the player (same approach as ArtPlayer web fullscreen).
 *
 * Does not touch fullscreenWeb — upstream autoOrientation already handles it.
 */
export function enableFullscreenOrientation(player: Artplayer) {
  if (!isMobile()) return

  let weLocked = false
  let settleTimer: number | undefined
  let generation = 0

  const tryUnlock = () => {
    if (!weLocked) return
    weLocked = false
    try {
      screen.orientation?.unlock?.()
    } catch {
      // ignore
    }
  }

  const tryOrient = async (gen: number) => {
    if (gen !== generation || !player.fullscreen) return

    await waitForVideoSize(player)
    if (gen !== generation || !player.fullscreen) return
    if (!needRotate(player)) {
      clearCssRotate(player)
      return
    }

    const video = player.template.$video
    const landscapeVideo = !!video && video.videoWidth > video.videoHeight
    const target = landscapeVideo ? "landscape" : "portrait"

    let lockOk = false
    try {
      if (screen.orientation?.lock) {
        await screen.orientation.lock(target as "landscape" | "portrait")
        if (gen !== generation || !player.fullscreen) return
        lockOk = true
        weLocked = true
      }
    } catch {
      lockOk = false
    }

    // After lock, allow orientation change to settle before CSS decision.
    await new Promise<void>((r) => window.setTimeout(r, SETTLE_MS))
    if (gen !== generation || !player.fullscreen) return

    if (!lockOk || needRotate(player)) {
      applyCssRotate(player)
    } else {
      clearCssRotate(player)
    }
  }

  const scheduleOrient = () => {
    generation += 1
    const gen = generation
    if (settleTimer !== undefined) window.clearTimeout(settleTimer)
    settleTimer = window.setTimeout(() => {
      void tryOrient(gen)
    }, SETTLE_MS)
  }

  const onFullscreen = (state: boolean) => {
    if (!state) {
      generation += 1
      if (settleTimer !== undefined) {
        window.clearTimeout(settleTimer)
        settleTimer = undefined
      }
      clearCssRotate(player)
      tryUnlock()
      return
    }
    scheduleOrient()
  }

  const onViewportChange = () => {
    if (!player.fullscreen) return
    if (needRotate(player)) {
      if (!player.template.$player.classList.contains(CSS_CLASS)) {
        applyCssRotate(player)
      }
    } else {
      clearCssRotate(player)
    }
  }

  player.on("fullscreen", onFullscreen as any)
  window.addEventListener("orientationchange", onViewportChange)
  window.addEventListener("resize", onViewportChange)

  player.on("destroy", () => {
    generation += 1
    if (settleTimer !== undefined) window.clearTimeout(settleTimer)
    window.removeEventListener("orientationchange", onViewportChange)
    window.removeEventListener("resize", onViewportChange)
    clearCssRotate(player)
    tryUnlock()
  })
}
