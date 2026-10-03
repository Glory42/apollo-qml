import QtQuick
import Quickshell.Io
import ".."

// `houston logbook <function>`; it opens on the focused monitor.
// For a keybind, also `apollo:logbook-toggle`.
QtObject {
    id: wrapper

    required property var logbook

    property IpcHandler handler: IpcHandler {
        target: "logbook"

        function toggle() { wrapper.logbook.toggle(); }
        function open() { wrapper.logbook.open(); }
        function close() { wrapper.logbook.close(); }
    }

    property Keybind toggle: Keybind {
        name: "logbook-toggle"
        onPressed: wrapper.logbook.toggle()
    }
}
