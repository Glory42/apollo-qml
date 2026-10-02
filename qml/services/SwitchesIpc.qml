import QtQuick
import Quickshell.Io

// `houston nightlight toggle`, `houston silence toggle` and `houston awake toggle`, for keybinds.
QtObject {
    id: wrapper

    required property var quick
    required property var center
    required property var idle

    property IpcHandler nightlight: IpcHandler {
        target: "nightlight"

        function toggle() { wrapper.quick.toggleNightLight(); }
    }

    property IpcHandler silence: IpcHandler {
        target: "silence"

        function toggle() { wrapper.center.focusMode = !wrapper.center.focusMode; }
    }

    property IpcHandler awake: IpcHandler {
        target: "awake"

        function toggle() { wrapper.idle.stayAwake = !wrapper.idle.stayAwake; }
    }
}
