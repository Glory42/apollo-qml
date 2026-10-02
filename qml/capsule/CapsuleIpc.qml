import QtQuick
import Quickshell.Io

// `houston capsule <function>`; views open on the focused monitor, notifications show everywhere.
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
        // A short peek of an icon and a few words that is not kept anywhere, for a script to say what it just did.
        function say(icon: string, text: string) { wrapper.shellRoot.announce(icon, text); }
    }
}
