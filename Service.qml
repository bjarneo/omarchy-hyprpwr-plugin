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

  readonly property string scriptPath: {
    var url = String(Qt.resolvedUrl("bin/hyperpower"))
    return decodeURIComponent(url.replace(/^file:\/\//, ""))
  }

  function refresh() {
    if (statusProbe.running) return
    statusProbe.running = true
  }

  // Store the requested intensity. A running shake picks it up at once.
  function applyIntensity(value) {
    var pixels = Math.round(Number(value))
    if (!isFinite(pixels)) return
    pixels = Math.max(0, Math.min(64, pixels))
    root.intensity = pixels
    if (root.stateLoaded && root.active) startShake(pixels)
  }

  function startShake(pixels) {
    if (pixels === undefined) pixels = root.intensity
    runAction([root.scriptPath, "start", "--intensity", String(pixels)])
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

  Component.onCompleted: refresh()

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

  IpcHandler {
    target: "hyperpower"

    function status(): string {
      return JSON.stringify({ active: root.active, intensity: root.intensity })
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
