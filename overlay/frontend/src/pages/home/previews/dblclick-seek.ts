import Artplayer from "artplayer"

/** Default seek step (seconds) for left/right double-click zones. */
export const DBLCLICK_SEEK_STEP = 10

/**
 * YouTube/Bilibili-style double-click seek:
 * - left half of the video: backward
 * - right half of the video: forward
 * Disables ArtPlayer's default double-click fullscreen.
 */
export function enableDblclickSeek(
  player: Artplayer,
  step: number = DBLCLICK_SEEK_STEP,
) {
  Artplayer.DBCLICK_FULLSCREEN = false

  const showHint = (label: string, side: "left" | "right") => {
    const existing = player.template.$player.querySelector(
      ".openlist-dblclick-seek-hint",
    ) as HTMLElement | null
    if (existing) existing.remove()

    const el = document.createElement("div")
    el.className = "openlist-dblclick-seek-hint"
    el.textContent = label
    Object.assign(el.style, {
      position: "absolute",
      top: "50%",
      [side]: "12%",
      transform: "translateY(-50%)",
      padding: "10px 16px",
      borderRadius: "8px",
      background: "rgba(0,0,0,0.55)",
      color: "#fff",
      fontSize: "18px",
      fontWeight: "600",
      pointerEvents: "none",
      zIndex: "999",
      transition: "opacity 0.3s",
    } as CSSStyleDeclaration)
    player.template.$player.appendChild(el)
    window.setTimeout(() => {
      el.style.opacity = "0"
      window.setTimeout(() => el.remove(), 300)
    }, 500)
  }

  // Prefer the video surface; fall back to player root for coordinate calc.
  const onDblclick = (event: Event) => {
    const e = event as MouseEvent
    const video = player.template.$video
    const rect = (video || player.template.$player).getBoundingClientRect()
    if (!rect.width) return
    const x = e.clientX - rect.left
    const isLeft = x < rect.width / 2
    if (isLeft) {
      player.backward = step
      showHint(`-${step}s`, "left")
    } else {
      player.forward = step
      showHint(`+${step}s`, "right")
    }
  }

  // ArtPlayer emits 'dblclick' on the video area (desktop).
  player.on("dblclick", onDblclick as any)

  // Mobile / some browsers: also listen on video element.
  const video = player.template.$video
  if (video) {
    video.addEventListener("dblclick", onDblclick)
    player.on("destroy", () => {
      video.removeEventListener("dblclick", onDblclick)
    })
  }
}
