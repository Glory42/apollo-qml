import QtQuick
import Quickshell.Io

// `houston launchpad <function>`; it opens on the focused monitor.
QtObject {
    id: wrapper

    required property var launchpad

    property IpcHandler handler: IpcHandler {
        target: "launchpad"

        function toggle() { wrapper.launchpad.toggle(); }
        function open() { wrapper.launchpad.open(); }
        function close() { wrapper.launchpad.close(); }
    }
}
