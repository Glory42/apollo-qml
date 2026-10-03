import QtQuick
import Quickshell.Io
import ".."

// `houston launchpad <function>`; it opens on the focused monitor.
// For a keybind, also `apollo:launchpad-toggle`.
QtObject {
    id: wrapper

    required property var launchpad

    property IpcHandler handler: IpcHandler {
        target: "launchpad"

        function toggle() { wrapper.launchpad.toggle(); }
        function open() { wrapper.launchpad.open(); }
        function close() { wrapper.launchpad.close(); }
    }

    property Keybind toggle: Keybind {
        name: "launchpad-toggle"
        onPressed: wrapper.launchpad.toggle()
    }
}
