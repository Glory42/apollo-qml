import QtQuick
import Quickshell.Io

// `houston visor <function>`; it opens on the focused monitor.
QtObject {
    id: wrapper

    required property var visor

    property IpcHandler handler: IpcHandler {
        target: "visor"

        function toggle() { wrapper.visor.toggle(); }
        function open() { wrapper.visor.open(); }
        function close() { wrapper.visor.close(); }
    }
}
