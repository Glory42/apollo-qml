import QtQuick
import Quickshell
import Quickshell.Io

// Records what is copied, newest first: text in the history file, images as files beside it.
Item {
    id: root

    visible: false

    readonly property int limit: 300
    readonly property string imageDir: Quickshell.statePath("logbook-images")
    readonly property string script: Quickshell.shellPath("qml/logbook/capture.sh")

    // { type: "text", text } or { type: "image", path, at }
    property var history: []

    function same(a, b) {
        return a.type === b.type && (a.type === "text" ? a.text === b.text : a.path === b.path);
    }

    function save() {
        store.setText(JSON.stringify(root.history));
    }

    // Images are files, so one that leaves the history is deleted with it.
    function forget(entries, kept) {
        for (const entry of entries) {
            if (entry.type === "image" && !kept.some((other) => root.same(other, entry)))
                Quickshell.execDetached(["rm", "-f", entry.path]);
        }
    }

    function add(entry) {
        const rest = root.history.filter((other) => !root.same(other, entry));
        const next = [entry].concat(rest);
        root.forget(next.slice(root.limit), next.slice(0, root.limit));
        root.history = next.slice(0, root.limit);
        save();
    }

    function remove(entry) {
        const next = root.history.filter((other) => !root.same(other, entry));
        root.forget([entry], next);
        root.history = next;
        save();
    }

    // The script sends text as hex bytes of UTF-8; anything that is not valid UTF-8 is dropped.
    function decode(hex) {
        try {
            return decodeURIComponent(hex.replace(/(..)/g, "%$1"));
        } catch (error) {
            return "";
        }
    }

    function received(line) {
        const space = line.indexOf(" ");
        const kind = line.slice(0, space);
        const payload = line.slice(space + 1);
        if (kind === "image")
            add({ type: "image", path: payload, at: Date.now() });
        else if (kind === "text" && root.decode(payload) !== "")
            add({ type: "text", text: root.decode(payload) });
    }

    // Shift+Insert pastes everywhere once the primary selection holds the entry too, so both are set.
    function put(entry, paste) {
        const copy = entry.type === "image"
            ? 'wl-copy --type image/png < "$1"; wl-copy --primary --type image/png < "$1"'
            : 'printf %s "$1" | wl-copy; printf %s "$1" | wl-copy --primary';
        const then = paste ? "; sleep 0.15; wtype -M shift -k Insert -m shift" : "";
        Quickshell.execDetached(["sh", "-c", copy + then, "sh", entry.type === "image" ? entry.path : entry.text]);
    }

    FileView {
        id: store

        path: Quickshell.statePath("logbook.json")
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(store.text());
                // Whatever was copied while this loaded is newer than the file.
                root.history = root.history.concat(saved.filter((entry) => !root.history.some((other) => root.same(other, entry)))).slice(0, root.limit);
            } catch (error) {
            }
        }
    }

    // The watchers sleep until something is copied. setpriv makes them exit with the shell.
    Process {
        running: true
        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "text", "--watch", root.script, "text", root.imageDir]
        stdout: SplitParser {
            onRead: (line) => root.received(line)
        }
    }

    Process {
        running: true
        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "image/png", "--watch", root.script, "image", root.imageDir]
        stdout: SplitParser {
            onRead: (line) => root.received(line)
        }
    }
}
