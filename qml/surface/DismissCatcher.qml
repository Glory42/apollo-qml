import QtQuick
import Quickshell
import Quickshell.Wayland

// Transparent full-screen layer under the pill that closes it on any click; it never takes keyboard focus.
PanelWindow {
    id: root

    property bool active: false

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
    WlrLayershell.namespace: "surface-dismiss"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.dismissed()
    }
}
