import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Capturing the screen: a screenshot, a recording with a choice of sound, or a colour. The menu rises in a lander.
Scope {
    id: root

    property string onlyScreen: ""
    property var recorder: null
    readonly property bool isOpen: win.open

    // "capture" for the first row, "record" for the choice of sound.
    property string page: "capture"
    // What the picker is picking for: "shot" or "record", and the sound for a recording.
    property string mode: ""
    property string sound: "none"

    signal opened()
    signal announce(string icon, string text, string color)
    signal failed(string message)

    readonly property var actions: page === "record" ? [
        { label: "No sound", icon: "videocam", run: () => root.record("none") },
        { label: "Desktop", icon: "volume", run: () => root.record("desktop") },
        { label: "Desktop + mic", icon: "mic", run: () => root.record("both") }
    ] : [
        { label: "Screenshot", icon: "camera", run: () => root.screenshot() },
        root.recorder && root.recorder.recording
            ? { label: "Stop", icon: "stop", run: () => root.recorder.stop() }
            : { label: "Record", icon: "videocam", run: () => root.open("record") },
        { label: "Colour", icon: "colorize", run: () => root.colour() }
    ]

    function open(at) {
        root.page = at || "capture";
        row.current = 0;
        if (!win.open) {
            win.show();
            root.opened();
        }
    }

    function close() {
        win.hide();
    }

    function toggle() {
        if (win.open)
            close();
        else
            open("capture");
    }

    // Alt+Print: stops a recording that is running, otherwise asks what sound to record.
    function recordKey() {
        if (root.recorder && root.recorder.recording)
            root.recorder.stop();
        else if (win.open && root.page === "record")
            close();
        else
            open("record");
    }

    // Choosing from the menu waits for the lander to sink away first, so it is not in the picture.
    function run(index) {
        const action = root.actions[index];
        if (!action)
            return;
        if (action.label === "Record") {
            action.run();
            return;
        }
        close();
        later.action = action.run;
        later.restart();
    }

    function screenshot() {
        root.close();
        root.mode = "shot";
        picker.begin(true);
    }

    function record(sound) {
        if (root.recorder.recording)
            return;
        root.close();
        root.mode = "record";
        root.sound = sound;
        later.action = () => picker.begin(false);
        later.restart();
    }

    function colour() {
        if (!colourPick.running)
            colourPick.running = true;
    }

    // Super+Alt+,: the newest screenshot in the editor.
    function edit() {
        Quickshell.execDetached(["sh", "-c", 'f=$(ls -t "$1"/*.png 2>/dev/null | head -n1); [ -n "$f" ] && exec sh -c "$2" sh "$f"', "sh",
            Config.screenshotDir, Config.screenshotEditCommand]);
    }

    function stamp() {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
    }

    // A notification whose click runs `command` on `file`; notify-send waits to hear whether it was clicked.
    function notice(summary, body, file, image, label, command) {
        const args = ["notify-send", "-a", "Hasselblad", "-A", "default=" + label, "--wait"];
        if (image)
            args.push("-i", file);
        noticeJob.createObject(root, { command: args.concat([summary, body]), file: file, openCommand: command });
    }

    function recordingSaved(file) {
        root.notice("Recording saved", file.slice(file.lastIndexOf("/") + 1), file, false, "Open", Config.openFileCommand);
    }

    Component {
        id: noticeJob

        Process {
            id: job

            property string file: ""
            property string openCommand: ""

            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text.trim() === "default")
                        Quickshell.execDetached(["sh", "-c", job.openCommand, "sh", job.file]);
                }
            }
            onExited: Qt.callLater(() => job.destroy())
        }
    }

    Timer {
        id: later

        property var action: null

        interval: 280
        onTriggered: if (action) action()
    }

    Picker {
        id: picker

        onlyScreen: root.onlyScreen

        onPicked: (rect, monitor, whole) => {
            if (root.mode === "shot") {
                // The outline and dimming go first, then grim takes the frozen picture underneath.
                picker.capturing = true;
                shoot.file = Config.screenshotDir + "/screenshot-" + root.stamp() + ".png";
                shoot.command = ["sh", "-c", 'mkdir -p "$1" && grim -g "$2" "$3" && wl-copy --type image/png < "$3"', "sh",
                    Config.screenshotDir, rect.x + "," + rect.y + " " + rect.w + "x" + rect.h, shoot.file];
                grabDelay.restart();
            } else {
                picker.finish();
                // The encoder wants even sizes.
                const w = Math.max(2, rect.w - rect.w % 2);
                const h = Math.max(2, rect.h - rect.h % 2);
                root.recorder.start(whole ? monitor : w + "x" + h + "+" + rect.x + "+" + rect.y, root.sound);
            }
        }
    }

    // One frame for the outline to disappear before grim looks.
    Timer {
        id: grabDelay

        interval: 60
        onTriggered: shoot.running = true
    }

    Process {
        id: shoot

        property string file: ""

        onExited: (exitCode) => {
            picker.finish();
            if (exitCode === 0)
                root.notice("Screenshot saved", "Copied to the clipboard. Click to edit it.", shoot.file, true, "Edit", Config.screenshotEditCommand);
            else
                root.failed("The screenshot could not be taken");
        }
    }

    Process {
        id: colourPick

        command: ["hyprpicker", "-f", "hex"]
        stdout: StdioCollector {
            onStreamFinished: {
                const colour = text.trim().toLowerCase();
                if (!/^#[0-9a-f]{6}$/.test(colour))
                    return;
                Quickshell.execDetached(["wl-copy", colour]);
                root.announce("colorize", colour + " copied", colour);
            }
        }
    }

    LanderWindow {
        id: win

        piece: "hasselblad"
        onlyScreen: root.onlyScreen
        onDismissed: root.close()
        onOpenChanged: if (open) row.forceActiveFocus()

        Row {
            id: row

            property int current: 0

            padding: 14
            spacing: 6
            focus: true

            Keys.onPressed: (event) => {
                const count = root.actions.length;
                if (event.key === Qt.Key_Escape)
                    root.close();
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                    row.current = (row.current + 1) % count;
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab)
                    row.current = (row.current + count - 1) % count;
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    root.run(row.current);
                else
                    return;
                event.accepted = true;
            }

            Repeater {
                model: root.actions

                Rectangle {
                    id: button

                    required property var modelData
                    required property int index

                    width: 96
                    height: 76
                    radius: 18
                    color: row.current === button.index ? Theme.fill2 : "transparent"

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 16
                        size: 22
                        name: button.modelData.icon
                        color: button.modelData.icon === "stop" ? Theme.danger : Theme.fg
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        text: button.modelData.label
                        color: row.current === button.index ? Theme.fg : Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: row.current = button.index
                        onClicked: root.run(button.index)
                    }
                }
            }
        }
    }
}
