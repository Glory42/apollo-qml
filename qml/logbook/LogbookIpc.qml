import QtQuick
import Quickshell.Io

// `houston logbook <function>`; it opens on the focused monitor.
QtObject {
    id: wrapper

    required property var logbook

    property IpcHandler handler: IpcHandler {
        target: "logbook"

        function toggle() { wrapper.logbook.toggle(); }
        function open() { wrapper.logbook.open(); }
        function close() { wrapper.logbook.close(); }
    }
}
