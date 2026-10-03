import QtQuick
import Quickshell.Io
import ".."

// `houston airlock lock`. There is no unlock here on purpose: only the password opens it.
// For a keybind, also `apollo:airlock-lock`.
QtObject {
    id: wrapper

    required property var airlock

    property IpcHandler handler: IpcHandler {
        target: "airlock"

        function lock() { wrapper.airlock.lock(); }
    }

    property Keybind lock: Keybind {
        name: "airlock-lock"
        onPressed: wrapper.airlock.lock()
    }
}
