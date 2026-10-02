import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// The window a lander or orbiter appears in, no larger than the surface: it holds the keyboard, and a press anywhere else closes it.
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

    // A window cannot be shown before it has a size, and it goes on top of the catcher by appearing after it.
    visible: win.shown && implicitWidth > 0 && implicitHeight > 0 && catcher.backingWindowVisible
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "apollo-" + win.piece
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: win.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Sits behind the surface and closes it when anything else on the screen is pressed.
    property DismissCatcher catcher: DismissCatcher {
        screen: win.screen
        active: win.shown
        overlay: true
        onDismissed: win.dismissed()
    }
}
