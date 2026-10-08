import QtQuick
import Quickshell.Io
import ".."

// `houston capsule <function>`; views open on the focused monitor, notifications show everywhere.
// The keybind ones are also `apollo:capsule-toggle-<view>`, `capsule-next`, `capsule-prev`, `capsule-close` and `capsule-invoke`.
QtObject {
    id: wrapper

    required property var shellRoot

    property IpcHandler handler: IpcHandler {
        target: "capsule"

        function toggle(view: string) { wrapper.shellRoot.show(view, true); }
        function open(view: string) { wrapper.shellRoot.show(view, false); }
        function next() { wrapper.shellRoot.step(1); }
        function prev() { wrapper.shellRoot.step(-1); }
        function close() { wrapper.shellRoot.closeAll(); }
        function notify(app: string, summary: string, body: string) {
            wrapper.shellRoot.services.center.post(app, summary, body);
        }
        function invoke() { wrapper.shellRoot.services.center.invokeLast(); }
        // A short peek of an icon and a few words that is not kept anywhere, for a script to say what it just did.
        function say(icon: string, text: string) { wrapper.shellRoot.announce(icon, text); }
    }

    property Instantiator views: Instantiator {
        model: ["quick", "music", "weather", "calendar", "notifications", "wifi", "bt", "sound", "display", "connection"]

        delegate: Keybind {
            required property string modelData

            name: "capsule-toggle-" + modelData
            onPressed: wrapper.shellRoot.show(modelData, true)
        }
    }

    property Keybind next: Keybind {
        name: "capsule-next"
        onPressed: wrapper.shellRoot.step(1)
    }

    property Keybind prev: Keybind {
        name: "capsule-prev"
        onPressed: wrapper.shellRoot.step(-1)
    }

    property Keybind close: Keybind {
        name: "capsule-close"
        onPressed: wrapper.shellRoot.closeAll()
    }

    property Keybind invoke: Keybind {
        name: "capsule-invoke"
        onPressed: wrapper.shellRoot.services.center.invokeLast()
    }
}
