import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import ".."

// Picks part of the screen: a window, a whole monitor, or a dragged region; frozen for a screenshot, live for a recording.
// Rectangles are { x, y, w, h } in Hyprland's logical layout coordinates.
Scope {
    id: root

    property string onlyScreen: ""
    property bool active: false
    property bool frozen: false
    // While the picked part is captured only the still picture shows, without the dimming and outline.
    property bool capturing: false

    // The windows on the visible workspaces, smallest first, so a window floating over another one wins.
    property var windows: []
    property var hovered: null
    property var dragStart: null
    property var dragRect: null
    readonly property var shown: dragRect || hovered

    // `whole` is true when a monitor was picked rather than a part of one.
    signal picked(var rect, string monitor, bool whole)
    signal cancelled()

    function begin(freeze) {
        root.frozen = freeze;
        root.capturing = false;
        root.hovered = null;
        root.dragStart = null;
        root.dragRect = null;
        info.running = true;
    }

    function finish() {
        root.active = false;
        root.capturing = false;
    }

    function cancel() {
        root.finish();
        root.cancelled();
    }

    function screens() {
        return Quickshell.screens.filter((screen) => root.onlyScreen === "" || screen.name === root.onlyScreen);
    }

    function screenRect(screen) {
        return { x: screen.x, y: screen.y, w: screen.width, h: screen.height };
    }

    function screenAt(x, y) {
        const list = root.screens();
        return list.find((screen) => x >= screen.x && x < screen.x + screen.width && y >= screen.y && y < screen.y + screen.height) || list[0] || null;
    }

    function contains(rect, x, y) {
        return x >= rect.x && x < rect.x + rect.w && y >= rect.y && y < rect.y + rect.h;
    }

    // The window under a point, or the monitor when there is none.
    function rectAt(x, y) {
        const hit = root.windows.find((rect) => root.contains(rect, x, y));
        if (hit)
            return hit;
        const screen = root.screenAt(x, y);
        return screen ? root.screenRect(screen) : null;
    }

    function pointer(x, y, pressed) {
        if (pressed && root.dragStart) {
            const w = Math.abs(x - root.dragStart.x);
            const h = Math.abs(y - root.dragStart.y);
            if (root.dragRect || w > 6 || h > 6)
                root.dragRect = { x: Math.min(x, root.dragStart.x), y: Math.min(y, root.dragStart.y), w: Math.max(1, w), h: Math.max(1, h) };
            return;
        }
        root.hovered = root.rectAt(x, y);
    }

    function release() {
        const rect = root.dragRect || root.hovered;
        root.dragStart = null;
        root.dragRect = null;
        if (rect)
            root.pick(rect);
    }

    function pick(rect) {
        const screen = root.screenAt(rect.x + rect.w / 2, rect.y + rect.h / 2);
        const whole = !!screen && rect.x === screen.x && rect.y === screen.y && rect.w === screen.width && rect.h === screen.height;
        const rounded = { x: Math.round(rect.x), y: Math.round(rect.y), w: Math.round(rect.w), h: Math.round(rect.h) };
        root.picked(rounded, screen ? screen.name : "", whole);
    }

    // Tab steps through windows in reading order; the arrows go to the nearest window that way.
    function step(dx, dy, ordered) {
        if (root.windows.length === 0)
            return;
        const current = root.hovered;
        if (ordered !== 0) {
            const list = root.windows.slice().sort((a, b) => a.y - b.y || a.x - b.x);
            const index = list.findIndex((rect) => current && rect.x === current.x && rect.y === current.y && rect.w === current.w && rect.h === current.h);
            root.hovered = list[(index + ordered + list.length) % list.length];
            return;
        }
        const from = current ? { x: current.x + current.w / 2, y: current.y + current.h / 2 } : { x: 0, y: 0 };
        let best = null;
        let bestDistance = Infinity;
        for (const rect of root.windows) {
            const cx = rect.x + rect.w / 2 - from.x;
            const cy = rect.y + rect.h / 2 - from.y;
            const along = cx * dx + cy * dy;
            if (along <= 1)
                continue;
            const distance = along + 2 * Math.abs(cx * dy - cy * dx);
            if (distance < bestDistance) {
                best = rect;
                bestDistance = distance;
            }
        }
        if (best)
            root.hovered = best;
    }

    function key(event, screen) {
        if (event.key === Qt.Key_Escape) {
            root.cancel();
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (event.modifiers & Qt.ControlModifier)
                root.pick(root.screenRect(root.hovered ? root.screenAt(root.hovered.x + root.hovered.w / 2, root.hovered.y + root.hovered.h / 2) : screen));
            else
                root.pick(root.hovered || root.screenRect(screen));
        } else if (event.key === Qt.Key_Tab) {
            root.step(0, 0, 1);
        } else if (event.key === Qt.Key_Backtab) {
            root.step(0, 0, -1);
        } else if (event.key === Qt.Key_Left) {
            root.step(-1, 0, 0);
        } else if (event.key === Qt.Key_Right) {
            root.step(1, 0, 0);
        } else if (event.key === Qt.Key_Up) {
            root.step(0, -1, 0);
        } else if (event.key === Qt.Key_Down) {
            root.step(0, 1, 0);
        } else {
            return;
        }
        event.accepted = true;
    }

    // Windows and the pointer, read once as the picker opens.
    Process {
        id: info

        command: ["sh", "-c", 'hyprctl -j clients; echo "@@"; hyprctl -j monitors; echo "@@"; hyprctl cursorpos']
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("@@");
                try {
                    const monitors = JSON.parse(parts[1]);
                    const visible = new Set();
                    for (const monitor of monitors) {
                        if (monitor.activeWorkspace)
                            visible.add(monitor.activeWorkspace.id);
                        if (monitor.specialWorkspace && monitor.specialWorkspace.id)
                            visible.add(monitor.specialWorkspace.id);
                    }
                    root.windows = JSON.parse(parts[0])
                        .filter((client) => client.mapped && !client.hidden && client.workspace && visible.has(client.workspace.id))
                        .map((client) => ({ x: client.at[0], y: client.at[1], w: client.size[0], h: client.size[1] }))
                        .sort((a, b) => a.w * a.h - b.w * b.h);
                } catch (error) {
                    root.windows = [];
                }
                const cursor = (parts[2] || "").split(",").map((value) => parseFloat(value));
                if (cursor.length === 2 && !isNaN(cursor[0]))
                    root.hovered = root.rectAt(cursor[0], cursor[1]);
                root.active = true;
            }
        }
    }

    Variants {
        model: root.screens()

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool focusedHere: !!Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name
            // The outlined rectangle in this monitor's own coordinates, or null when it is on another monitor.
            readonly property var box: {
                const rect = root.shown;
                if (!rect || rect.x >= modelData.x + modelData.width || rect.y >= modelData.y + modelData.height
                    || rect.x + rect.w <= modelData.x || rect.y + rect.h <= modelData.y)
                    return null;
                return { x: rect.x - modelData.x, y: rect.y - modelData.y, w: rect.w, h: rect.h };
            }

            screen: modelData
            visible: root.active
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "apollo-hasselblad"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.active && win.focusedHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            // The freeze: one still frame of this monitor, taken as the picker opens.
            ScreencopyView {
                id: still

                anchors.fill: parent
                visible: root.frozen
                captureSource: root.frozen && root.active ? win.modelData : null
                live: false
            }

            Item {
                anchors.fill: parent
                // Nothing is drawn until the still frame is in, so the frame cannot catch the picker itself.
                visible: !root.capturing && (!root.frozen || still.hasContent)

                Rectangle {
                    visible: !win.box
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.35)
                }

                Repeater {
                    // The dimming around the outlined rectangle: above, below, left and right of it.
                    model: win.box ? [
                        { x: 0, y: 0, w: win.width, h: win.box.y },
                        { x: 0, y: win.box.y + win.box.h, w: win.width, h: win.height - win.box.y - win.box.h },
                        { x: 0, y: win.box.y, w: win.box.x, h: win.box.h },
                        { x: win.box.x + win.box.w, y: win.box.y, w: win.width - win.box.x - win.box.w, h: win.box.h }
                    ] : []

                    Rectangle {
                        required property var modelData

                        x: modelData.x
                        y: modelData.y
                        width: Math.max(0, modelData.w)
                        height: Math.max(0, modelData.h)
                        color: Qt.rgba(0, 0, 0, 0.35)
                    }
                }

                Rectangle {
                    visible: !!win.box
                    x: win.box ? win.box.x : 0
                    y: win.box ? win.box.y : 0
                    width: win.box ? win.box.w : 0
                    height: win.box ? win.box.h : 0
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.accent
                }

                Rectangle {
                    visible: !!root.dragRect && !!win.box
                    x: win.box ? Math.min(win.box.x + 8, win.width - width - 8) : 0
                    y: win.box ? Math.max(8, win.box.y - height - 8) : 0
                    width: size.width + 16
                    height: 24
                    radius: 12
                    color: Theme.hull

                    Text {
                        id: size

                        anchors.centerIn: parent
                        text: root.dragRect ? Math.round(root.dragRect.w) + " × " + Math.round(root.dragRect.h) : ""
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.CrossCursor

                onPositionChanged: (mouse) => root.pointer(mouse.x + win.modelData.x, mouse.y + win.modelData.y, pressed)
                onPressed: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        root.cancel();
                        return;
                    }
                    root.dragStart = { x: mouse.x + win.modelData.x, y: mouse.y + win.modelData.y };
                }
                onReleased: (mouse) => {
                    if (mouse.button === Qt.LeftButton)
                        root.release();
                }
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: (event) => root.key(event, win.modelData)
            }
        }
    }
}
