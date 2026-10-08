import QtQuick
import Quickshell
import Quickshell.Io

// Records what is copied, newest first: text in the history file, images as files beside it.
Item {
    id: root

    visible: false

    readonly property int limit: 300
    // Characters of text kept in all; past that the oldest entries go, as they do past the limit.
    readonly property int textBudget: 1000000
    readonly property string imageDir: Quickshell.statePath("logbook-images")
    readonly property string script: Quickshell.shellPath("qml/logbook/capture.sh")

    // { type: "text", text } or { type: "image", path, at }
    property var history: []

    // Packages not installed: without wl-clipboard nothing is recorded, without wtype entries are only copied.
    property var missing: []
    // Why nothing is being recorded, for Logbook to show; empty while recording works.
    property string problem: ""
    readonly property bool canPaste: missing.indexOf("wtype") < 0
    // Watcher restarts since they last ran a minute without exiting; past the limit they are left stopped.
    property int restarts: 0
    property bool closing: false

    // Posted once at start when something Logbook needs is not installed.
    signal unavailable(string summary, string body)

    function same(a, b) {
        return a.type === b.type && (a.type === "text" ? a.text === b.text : a.path === b.path);
    }

    function save() {
        saver.restart();
    }

    function write() {
        saver.stop();
        store.setText(JSON.stringify(root.history));
    }

    // The newest entries that fit within both the limit and the text budget.
    function fit(entries) {
        let size = 0;
        let count = 0;
        while (count < entries.length && count < root.limit) {
            size += entries[count].type === "text" ? entries[count].text.length : 0;
            if (size > root.textBudget && count > 0)
                break;
            count += 1;
        }
        return entries.slice(0, count);
    }

    // Images are files, so one that leaves the history is deleted with it.
    function forget(entries, kept) {
        for (const entry of entries) {
            if (entry.type === "image" && !kept.some((other) => root.same(other, entry)))
                Quickshell.execDetached(["rm", "-f", entry.path]);
        }
    }

    function add(entry) {
        const next = [entry].concat(root.history.filter((other) => !root.same(other, entry)));
        const kept = root.fit(next);
        root.forget(next.slice(kept.length), kept);
        root.history = kept;
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
        if (kind === "image") {
            add({ type: "image", path: payload, at: Date.now() });
        } else if (kind === "text") {
            const text = root.decode(payload);
            if (text !== "")
                add({ type: "text", text: text });
        }
    }

    // Shift+Insert pastes everywhere once the primary selection holds the entry too, so both are set.
    function put(entry, paste) {
        const copy = entry.type === "image"
            ? 'wl-copy --type image/png < "$1"; wl-copy --primary --type image/png < "$1"'
            : 'printf %s "$1" | wl-copy; printf %s "$1" | wl-copy --primary';
        const then = paste && root.canPaste ? "; sleep 0.15; wtype -M shift -k Insert -m shift" : "";
        Quickshell.execDetached(["sh", "-c", copy + then, "sh", entry.type === "image" ? entry.path : entry.text]);
    }

    // A burst of copies is written once, and whatever is still waiting is written as the shell exits.
    Timer {
        id: saver

        interval: 5000
        onTriggered: root.write()
    }

    Component.onDestruction: {
        root.closing = true;
        if (saver.running) {
            root.write();
            store.waitForJob();
        }
    }

    FileView {
        id: store

        path: Quickshell.statePath("logbook.json")
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(store.text());
                // Whatever was copied while this loaded is newer than the file.
                root.history = root.fit(root.history.concat(saved.filter((entry) => !root.history.some((other) => root.same(other, entry)))));
            } catch (error) {
            }
        }
    }

    function checked(found) {
        const tools = found.split("\n");
        const packages = [];
        if (tools.indexOf("wl-paste") >= 0 || tools.indexOf("wl-copy") >= 0)
            packages.push("wl-clipboard");
        if (tools.indexOf("wtype") >= 0)
            packages.push("wtype");
        root.missing = packages;
        if (packages.length > 0) {
            console.warn("Logbook: not installed: " + packages.join(", "));
            root.unavailable("Logbook needs " + packages.join(" and "), packages[0] === "wl-clipboard"
                ? "Nothing copied is recorded until it is installed."
                : "Entries are copied but not pasted until it is installed.");
        }
        if (packages[0] === "wl-clipboard") {
            root.problem = "Install wl-clipboard to record copies";
            return;
        }
        textWatcher.running = true;
        imageWatcher.running = true;
    }

    function watcherExited(exitCode) {
        if (root.closing)
            return;
        steady.stop();
        // 127 is setpriv failing to find wl-paste, removed since the check at start.
        if (exitCode === 127) {
            root.problem = "Install wl-clipboard to record copies";
            console.warn("Logbook: wl-paste not found, install wl-clipboard");
            return;
        }
        if (root.restarts >= 5) {
            restartWatchers.stop();
            textWatcher.running = false;
            imageWatcher.running = false;
            if (root.problem === "")
                console.warn("Logbook: the clipboard watchers keep exiting, leaving them stopped");
            root.problem = "Clipboard recording stopped";
            return;
        }
        root.restarts += 1;
        console.warn("Logbook: a clipboard watcher exited with " + exitCode + ", restarting it");
        restartWatchers.restart();
    }

    Process {
        running: true
        command: ["sh", "-c", 'for t in wl-paste wl-copy wtype; do command -v "$t" >/dev/null 2>&1 || echo "$t"; done']
        stdout: StdioCollector {
            onStreamFinished: root.checked(text.trim())
        }
    }

    // The watchers sleep until something is copied. setpriv makes them exit with the shell.
    Process {
        id: textWatcher

        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "text", "--watch", root.script, "text", root.imageDir]
        stdout: SplitParser {
            onRead: (line) => root.received(line)
        }
        onExited: (exitCode) => root.watcherExited(exitCode)
    }

    Process {
        id: imageWatcher

        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "image/png", "--watch", root.script, "image", root.imageDir]
        stdout: SplitParser {
            onRead: (line) => root.received(line)
        }
        onExited: (exitCode) => root.watcherExited(exitCode)
    }

    // Both watchers exit together when the compositor goes away, so one restart serves them.
    Timer {
        id: restartWatchers

        interval: 2000
        onTriggered: {
            textWatcher.running = true;
            imageWatcher.running = true;
            steady.restart();
        }
    }

    // A copy cannot show the watchers are well: wl-paste --watch sends the clipboard as it starts.
    Timer {
        id: steady

        interval: 60000
        onTriggered: root.restarts = 0
    }
}
