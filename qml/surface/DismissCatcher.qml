import QtQuick
import Quickshell
import Quickshell.Wayland

// Transparent full-screen layer under an open surface that closes it on any click; it never takes keyboard focus.
PanelWindow {
    id: root

    property bool active: false
    // Whether it also covers fullscreen windows and other overlays.
    property bool overlay: false

    signal dismissed()

    visible: active
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "apollo-dismiss"
    WlrLayershell.layer: root.overlay ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.dismissed()
    }
}
