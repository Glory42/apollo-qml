import QtQuick
import Quickshell.Hyprland

// Owns which view this monitor shows and the rules for events; open views are never interrupted.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var screen: null
    property var clock: null
    property var mpris: null
    property var system: null
    property var weather: null
    property var center: null
    property var quick: null
    property var net: null
    property var countdown: null

    property string view: "rest"
    property string lastOpened: "music"

    property string peekKind: ""
    property string peekApp: ""
    property string peekSummary: ""
    property string peekBody: ""
    property string peekAppIcon: ""
    property string peekImage: ""
    property string peekIcon: ""
    property real peekProgress: -1

    readonly property var dock: [
        { id: "music", label: "Music", icon: "music" },
        { id: "quick", label: "Quick settings", icon: "sliders" },
        { id: "timer", label: "Timer", icon: "timer" },
        { id: "weather", label: "Weather", icon: "cloud" },
        { id: "calendar", label: "Calendar", icon: "cal" },
        { id: "notifications", label: "Notifications", icon: "bell" }
    ]
    readonly property var openViews: ["music", "quick", "timer", "weather", "calendar", "notifications", "wifi", "bt"]
    readonly property bool isOpen: openViews.indexOf(view) >= 0
    readonly property string dockCurrent: view === "wifi" || view === "bt" ? "quick" : view
    readonly property int unread: center && view !== "notifications" ? center.unread : 0
    readonly property bool wantsKeyboard: !!net && ((view === "wifi" && net.pendingSsid !== "")
        || (view === "bt" && (net.agent.promptKind === "passkey" || net.agent.promptKind === "pin")))

    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property int activeWorkspace: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1
    readonly property var workspaceIds: {
        const list = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        const ids = [];
        for (let i = 0; i < list.length; i++) {
            if (list[i].id > 0 && (!monitor || list[i].monitor === monitor))
                ids.push(list[i].id);
        }
        if (ids.indexOf(activeWorkspace) < 0)
            ids.push(activeWorkspace);
        ids.sort((a, b) => a - b);
        return ids.slice(0, 7);
    }

    function open(target) {
        if (openViews.indexOf(target) < 0)
            return;
        peekTimer.stop();
        peekKind = "";
        if (dock.some((entry) => entry.id === target))
            lastOpened = target;
        if (target === "notifications" && center)
            center.unread = 0;
        view = target;
    }

    function close() {
        peekTimer.stop();
        peekKind = "";
        view = "rest";
    }

    function toggle(target) {
        if (view === target)
            close();
        else
            open(target);
    }

    function startPeek(kind, ms) {
        peekKind = kind;
        view = "peek";
        peekTimer.interval = ms;
        peekTimer.restart();
    }

    function notify(app, summary, body, icon, image, critical, timeout) {
        if (view === "notifications" && center)
            center.unread = 0;
        if (isOpen || (center && center.focusMode && !critical))
            return;
        const title = summary !== "" ? summary : (body !== "" ? body : "New notification");
        peekApp = app;
        peekSummary = title;
        peekBody = body !== title ? body : "";
        peekAppIcon = icon;
        peekImage = image;
        startPeek("notify", timeout > 0 ? Math.max(3000, Math.min(timeout, 10000)) : 5000);
    }

    function osd(icon, progress) {
        if (isOpen)
            return;
        // A notification matters more than a volume tick, so let it finish.
        if (view === "peek" && peekKind === "notify")
            return;
        peekIcon = icon;
        peekProgress = progress;
        startPeek("osd", 1600);
    }

    Timer {
        id: peekTimer

        onTriggered: if (root.view === "peek") root.close()
    }
}
