import QtQuick
import Quickshell.Io
import ".."

// `houston <name> <function>` for a piece that opens on the focused monitor (Launchpad, Logbook, Visor, Earthrise, Splashdown).
// For a keybind, also `apollo:<name>-toggle`.
QtObject {
    id: wrapper

    required property string name
    required property var piece

    property IpcHandler handler: IpcHandler {
        target: wrapper.name

        function toggle() { wrapper.piece.toggle(); }
        function open() { wrapper.piece.open(); }
        function close() { wrapper.piece.close(); }
    }

    property Keybind toggle: Keybind {
        name: wrapper.name + "-toggle"
        onPressed: wrapper.piece.toggle()
    }
}
