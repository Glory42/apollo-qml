import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// The full-screen window a lander or orbiter appears in: it holds the keyboard, and a click outside the surface closes it.
PanelWindow {
    id: win

    property string piece: "surface"
    property string onlyScreen: ""
    property bool open: false
    // Stays true while the surface is still animating away.
    property bool shown: open

    signal dismissed()

    function show() {
        const wanted = win.onlyScreen !== "" ? win.onlyScreen : (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
        for (const candidate of Quickshell.screens) {
            if (candidate.name === wanted)
                win.screen = candidate;
        }
        win.open = true;
    }

    function hide() {
        win.open = false;
    }

    visible: win.shown
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "apollo-" + win.piece
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: win.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: win.dismissed()
    }
}
