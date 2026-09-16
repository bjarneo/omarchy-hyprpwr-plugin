import QtQuick
import qs.Commons
import qs.Ui

// Bar toggle for hyperpower. Click once to shake the whole desktop, click
// again to put it back.
BarWidget {
  id: root

  moduleName: "bjarneo.hyperpower"

  readonly property var hyperpowerService: {
    if (!bar || !bar.shell || typeof bar.shell.serviceFor !== "function") return null
    return bar.shell.serviceFor("bjarneo.hyperpower")
  }

  readonly property bool shaking: hyperpowerService ? !!hyperpowerService.active : false

  // Font Awesome toggle switch: filled when the shake runs.
  readonly property string glyph: shaking ? "\uf205" : "\uf204"

  readonly property int intensity: {
    var value = Number(root.setting("intensity", 16))
    if (!isFinite(value)) return 16
    return Math.max(0, Math.min(64, Math.round(value)))
  }

  function pushIntensity() {
    if (hyperpowerService) hyperpowerService.applyIntensity(root.intensity)
  }

  Component.onCompleted: pushIntensity()
  onHyperpowerServiceChanged: pushIntensity()
  onIntensityChanged: pushIntensity()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyph
    active: root.shaking
    dimmed: !root.shaking
    tooltipText: root.shaking ? "HyperPower is shaking the desktop" : "HyperPower is off"
    onPressed: function() {
      if (root.hyperpowerService) root.hyperpowerService.toggle()
    }
  }
}
