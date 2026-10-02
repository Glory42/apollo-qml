import QtQuick
import Quickshell.Io

// `houston airlock lock`. There is no unlock here on purpose: only the password opens it.
QtObject {
    id: wrapper

    required property var airlock

    property IpcHandler handler: IpcHandler {
        target: "airlock"

        function lock() { wrapper.airlock.lock(); }
    }
}
