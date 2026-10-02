import QtQuick
import Quickshell.Io

// `houston splashdown <function>`; it opens on the focused monitor.
QtObject {
    id: wrapper

    required property var splashdown

    property IpcHandler handler: IpcHandler {
        target: "splashdown"

        function toggle() { wrapper.splashdown.toggle(); }
        function open() { wrapper.splashdown.open(); }
        function close() { wrapper.splashdown.close(); }
    }
}
