import QtQuick
import Quickshell.Io

// `houston earthrise <function>`; it opens on the focused monitor.
QtObject {
    id: wrapper

    required property var earthrise

    property IpcHandler handler: IpcHandler {
        target: "earthrise"

        function toggle() { wrapper.earthrise.toggle(); }
        function open() { wrapper.earthrise.open(); }
        function close() { wrapper.earthrise.close(); }
    }
}
