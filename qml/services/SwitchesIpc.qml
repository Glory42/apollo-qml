import QtQuick
import Quickshell.Io
import ".."

// `houston nightlight toggle`, `houston silence toggle`, `houston awake toggle` and `houston touchpad toggle`, for keybinds;
// a Hyprland bind can use `apollo:nightlight-toggle`, `apollo:silence-toggle`, `apollo:awake-toggle` and `apollo:touchpad-toggle` instead.
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

    property IpcHandler touchpad: IpcHandler {
        target: "touchpad"

        function toggle() { wrapper.quick.toggleTouchpad(); }
    }

    property IpcHandler awake: IpcHandler {
        target: "awake"

        function toggle() { wrapper.idle.stayAwake = !wrapper.idle.stayAwake; }
    }

    property Keybind nightlightKey: Keybind {
        name: "nightlight-toggle"
        onPressed: wrapper.quick.toggleNightLight()
    }

    property Keybind silenceKey: Keybind {
        name: "silence-toggle"
        onPressed: wrapper.center.focusMode = !wrapper.center.focusMode
    }

    property Keybind touchpadKey: Keybind {
        name: "touchpad-toggle"
        onPressed: wrapper.quick.toggleTouchpad()
    }

    property Keybind awakeKey: Keybind {
        name: "awake-toggle"
        onPressed: wrapper.idle.stayAwake = !wrapper.idle.stayAwake
    }
}
