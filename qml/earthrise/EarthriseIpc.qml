import QtQuick
import Quickshell.Io
import ".."

// `houston earthrise <function>`; it opens on the focused monitor.
// For a keybind, also `apollo:earthrise-toggle`.
QtObject {
    id: wrapper

    required property var earthrise

    property IpcHandler handler: IpcHandler {
        target: "earthrise"

        function toggle() { wrapper.earthrise.toggle(); }
        function open() { wrapper.earthrise.open(); }
        function close() { wrapper.earthrise.close(); }
    }

    property Keybind toggle: Keybind {
        name: "earthrise-toggle"
        onPressed: wrapper.earthrise.toggle()
    }
}
