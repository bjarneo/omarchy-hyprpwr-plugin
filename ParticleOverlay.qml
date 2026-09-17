import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// Fullscreen click-through overlay that draws the wow particles. One instance
// per screen, owned by Service.qml. The empty mask keeps every click and
// scroll on the desktop, and keyboard focus stays off.
PanelWindow {
  id: overlay

  required property var targetScreen

  // Set by the service: true while the shake runs and wow is on.
  property bool armed: false

  screen: targetScreen
  visible: armed
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.namespace: "omarchy-hyperpower-particles"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // An empty region means the surface never receives input.
  mask: Region {
    width: 0
    height: 0
  }

  property var particles: []
  readonly property int maxParticles: 400

  // Theme colors, like the terminal colors the original wow mode used.
  readonly property var palette: [Color.urgent, Color.accent, Color.foreground, Color.muted]

  function spawn(globalX, globalY) {
    if (!armed || !targetScreen) return

    var x = globalX - targetScreen.x
    var y = globalY - targetScreen.y
    if (x < -16 || y < -16 || x > width + 16 || y > height + 16) return
    if (particles.length >= maxParticles) return

    var count = 6 + Math.round(Math.random() * 5)
    var next = particles.slice()
    for (var i = 0; i < count; i++) {
      var c = palette[Math.floor(Math.random() * palette.length)]
      next.push({
        x: x,
        y: y,
        vx: -1 + Math.random() * 2,
        vy: -3.5 + Math.random() * 2,
        alpha: 1,
        r: Math.round(c.r * 255),
        g: Math.round(c.g * 255),
        b: Math.round(c.b * 255)
      })
    }

    particles = next
    if (!ticker.running) ticker.running = true
  }

  function step() {
    var alive = []
    for (var i = 0; i < particles.length; i++) {
      var p = particles[i]
      p.vy += 0.075
      p.x += p.vx
      p.y += p.vy
      p.alpha *= 0.96
      if (p.alpha > 0.1 && p.y < height + 8) alive.push(p)
    }

    particles = alive
    canvas.requestPaint()

    if (particles.length === 0) ticker.running = false
  }

  onVisibleChanged: {
    if (visible) canvas.requestPaint()
  }

  Timer {
    id: ticker
    interval: 16
    repeat: true
    onTriggered: overlay.step()
  }

  Canvas {
    id: canvas
    anchors.fill: parent

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var list = overlay.particles
      for (var i = 0; i < list.length; i++) {
        var p = list[i]
        ctx.fillStyle = "rgba(" + p.r + "," + p.g + "," + p.b + "," + p.alpha.toFixed(3) + ")"
        ctx.fillRect(Math.round(p.x) - 1, Math.round(p.y) - 1, 3, 3)
      }
    }
  }
}
