import QtQuick
import Quickshell.Io

// Pairing agent driven through bluetoothctl, because BlueZ will not pair new devices without one.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool active: false
    property bool pairingInitiated: false
    property string promptKind: ""
    property string promptCode: ""
    property string buffer: ""

    function clean(text) {
        return text.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "").replace(/[\x01\x02\r]/g, "");
    }

    function handle(chunk) {
        buffer = (buffer + clean(chunk)).slice(-2000);
        let match = null;
        if ((match = buffer.match(/Confirm passkey (\d+)/))) {
            setPrompt("confirm", match[1]);
        } else if (/Enter passkey/.test(buffer)) {
            setPrompt("passkey", "");
        } else if (/Enter PIN code/.test(buffer)) {
            setPrompt("pin", "");
        } else if ((match = buffer.match(/(?:Passkey|PIN code): (\d+)/))) {
            setPrompt("display", match[1]);
        } else if (/(Authorize service|Request authorization)[^\n]*\(yes\/no\)/.test(buffer)) {
            buffer = "";
            proc.write(pairingInitiated ? "yes\n" : "no\n");
        } else if (/Pairing successful|Failed to pair|AuthenticationCanceled|Paired: yes/.test(buffer)) {
            clear();
        }
    }

    function setPrompt(kind, code) {
        buffer = "";
        promptKind = kind;
        promptCode = code;
    }

    function clear() {
        buffer = "";
        promptKind = "";
        promptCode = "";
    }

    function answer(text) {
        proc.write(text + "\n");
        clear();
    }

    function reject() {
        proc.write("no\n");
        clear();
    }

    onActiveChanged: if (!active) clear()

    Process {
        id: proc

        command: ["bluetoothctl"]
        running: root.active
        stdinEnabled: true
        onStarted: write("agent DisplayYesNo\ndefault-agent\n")

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => root.handle(data)
        }
    }
}
