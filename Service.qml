import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Owns the hyperpower state for the shell: runs bin/hyperpower, mirrors its
// status, and exposes the toggle to the bar widget, IPC, and keybindings.
Item {
  id: root

  // Injected by omarchy-shell.
  property var shell: null

  property bool active: false
  property bool stateLoaded: false
  property int intensity: 16
  property bool chaos: true
  property bool wow: true

  readonly property string scriptPath: {
    var url = String(Qt.resolvedUrl("bin/hyperpower"))
    return decodeURIComponent(url.replace(/^file:\/\//, ""))
  }

  // The Lua listener writes one cursor position per key press here.
  readonly property string stateDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-hyperpower"
  readonly property string burstPath: stateDir + "/bursts"

  function refresh() {
    if (statusProbe.running) return
    statusProbe.running = true
  }

  // Store the requested settings. A running shake picks them up at once.
  function applySettings(pixels, chaosEnabled, wowEnabled) {
    var value = Math.round(Number(pixels))
    if (isFinite(value)) root.intensity = Math.max(0, Math.min(64, value))
    root.chaos = !!chaosEnabled
    root.wow = !!wowEnabled
    if (root.stateLoaded && root.active) startShake()
  }

  function startShake() {
    runAction([
      root.scriptPath,
      "start",
      "--intensity", String(root.intensity),
      root.chaos ? "--chaos" : "--no-chaos",
      root.wow ? "--wow" : "--no-wow"
    ])
  }

  // The Lua listener writes one cursor position per key press. A tail keeps
  // the stream live and tolerates the truncation on every start.
  function spawnBurst(line) {
    if (!root.active || !root.wow) return

    var parts = String(line).trim().split(/\s+/)
    if (parts.length < 2) return
    var x = Number(parts[0])
    var y = Number(parts[1])
    if (!isFinite(x) || !isFinite(y)) return

    for (var i = 0; i < overlayInstantiator.count; i++) {
      var overlay = overlayInstantiator.objectAt(i)
      if (overlay) overlay.spawn(x, y)
    }
  }

  function stopShake() {
    runAction([root.scriptPath, "stop"])
  }

  function toggle() {
    if (root.active) root.stopShake()
    else root.startShake()
  }

  property var queuedAction: null

  function runAction(argv) {
    if (actionProcess.running) {
      queuedAction = argv
      return
    }
    actionProcess.command = ["bash"].concat(argv)
    actionProcess.running = true
  }

  Component.onCompleted: {
    burstFileSetup.running = true
    refresh()
  }

  // Leave no shake loop behind when the plugin goes away.
  Component.onDestruction: {
    if (root.active) Quickshell.execDetached(["bash", root.scriptPath, "stop"])
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProbe
    command: ["bash", root.scriptPath, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.active = String(text).trim() === "active"
        root.stateLoaded = true
      }
    }
  }

  Process {
    id: actionProcess
    onExited: function() {
      if (root.queuedAction) {
        var next = root.queuedAction
        root.queuedAction = null
        root.runAction(next)
        return
      }
      root.refresh()
    }
  }

  // One particle overlay per screen. They stay unmapped until the shake runs.
  Instantiator {
    id: overlayInstantiator
    model: Quickshell.screens

    delegate: Component {
      ParticleOverlay {
        required property var modelData
        targetScreen: modelData
        armed: root.active && root.wow
      }
    }
  }

  Process {
    id: burstFileSetup
    command: ["bash", "-c",
      "mkdir -p " + Util.shellQuote(root.stateDir) + " && touch " + Util.shellQuote(root.burstPath)]
    onExited: burstTail.running = true
  }

  Process {
    id: burstTail
    command: ["tail", "-n", "0", "-F", root.burstPath]
    stdout: SplitParser {
      onRead: function(line) {
        root.spawnBurst(line)
      }
    }
    onExited: function(code) {
      burstTailRestart.restart()
    }
  }

  Timer {
    id: burstTailRestart
    interval: 1000
    onTriggered: burstTail.running = true
  }

  IpcHandler {
    target: "hyperpower"

    function status(): string {
      return JSON.stringify({
        active: root.active,
        intensity: root.intensity,
        chaos: root.chaos,
        wow: root.wow
      })
    }

    function toggle(): void {
      root.toggle()
    }

    function enable(): void {
      root.startShake()
    }

    function disable(): void {
      root.stopShake()
    }

    function refresh(): void {
      root.refresh()
    }
  }
}
