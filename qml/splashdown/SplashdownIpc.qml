import QtQuick
import Quickshell.Io
import ".."

// `houston splashdown <function>`; it opens on the focused monitor.
// For a keybind, also `apollo:splashdown-toggle`.
QtObject {
    id: wrapper

    required property var splashdown

    property IpcHandler handler: IpcHandler {
        target: "splashdown"

        function toggle() { wrapper.splashdown.toggle(); }
        function open() { wrapper.splashdown.open(); }
        function close() { wrapper.splashdown.close(); }
    }

    property Keybind toggle: Keybind {
        name: "splashdown-toggle"
        onPressed: wrapper.splashdown.toggle()
    }
}
