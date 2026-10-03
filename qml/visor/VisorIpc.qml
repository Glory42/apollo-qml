import QtQuick
import Quickshell.Io
import ".."

// `houston visor <function>`; it opens on the focused monitor.
// For a keybind, also `apollo:visor-toggle`.
QtObject {
    id: wrapper

    required property var visor

    property IpcHandler handler: IpcHandler {
        target: "visor"

        function toggle() { wrapper.visor.toggle(); }
        function open() { wrapper.visor.open(); }
        function close() { wrapper.visor.close(); }
    }

    property Keybind toggle: Keybind {
        name: "visor-toggle"
        onPressed: wrapper.visor.toggle()
    }
}
