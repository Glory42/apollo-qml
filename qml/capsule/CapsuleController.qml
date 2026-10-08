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
    property var sound: null
    property var recorder: null

    property string view: "rest"
    // The network device the connection page is about.
    property var detailDevice: null
    // Set by a view while it shows a text field, so the capsule takes the keyboard.
    property bool typing: false
    property string lastOpened: "music"

    property string peekKind: ""
    property string peekApp: ""
    property string peekSummary: ""
    property string peekBody: ""
    property string peekAppIcon: ""
    property string peekImage: ""
    property string peekIcon: ""
    property real peekProgress: -1
    // The notification behind a notify peek, while it still exists; a transient one is gone at once.
    property var peekSource: null
    // A colour shown in place of the icon in a status peek, such as one just picked.
    property string peekColor: ""

    readonly property var dock: [
        { id: "quick", label: "Quick settings", icon: "sliders" },
        { id: "music", label: "Music", icon: "music" },
        { id: "weather", label: "Weather", icon: "cloud" },
        { id: "calendar", label: "Calendar", icon: "cal" },
        { id: "notifications", label: "Notifications", icon: "bell" }
    ]
    readonly property var openViews: ["music", "quick", "weather", "calendar", "notifications", "wifi", "bt", "sound", "display", "connection"]
    readonly property bool isOpen: openViews.indexOf(view) >= 0
    // The detail views belong to the quick settings tab.
    readonly property string dockCurrent: ["wifi", "bt", "sound", "display", "connection"].indexOf(view) >= 0 ? "quick" : view
    readonly property int unread: center && view !== "notifications" ? center.unread : 0
    readonly property bool wantsKeyboard: typing || !!net && ((view === "wifi" && net.pendingSsid !== "")
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
        typing = false;
        // Opened by name rather than from a row, the connection page shows whichever connection is in use.
        if (target === "connection" && !detailDevice && net)
            detailDevice = net.wiredDevice && net.wiredDevice.connected ? net.wiredDevice : net.wifiDevice;
        view = target;
    }

    function openConnection(device) {
        detailDevice = device;
        open("connection");
    }

    function step(delta) {
        if (!isOpen) {
            open(lastOpened);
            return;
        }
        const index = dock.findIndex((entry) => entry.id === dockCurrent);
        open(dock[(index + delta + dock.length) % dock.length].id);
    }

    function close() {
        peekTimer.stop();
        peekKind = "";
        typing = false;
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

    function notify(app, summary, body, icon, image, critical, timeout, source) {
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
        peekSource = source || null;
        startPeek("notify", timeout > 0 ? Math.max(3000, Math.min(timeout, 10000)) : 5000);
    }

    // Clicking a notification's peek does what clicking the notification would: its main action, else the list.
    function activatePeek() {
        const source = peekSource;
        const actions = source && source.actions ? source.actions : [];
        let action = null;
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default")
                action = actions[i];
        }
        if (peekKind === "notify" && action) {
            action.invoke();
            source.dismiss();
            close();
        } else {
            open(peekKind === "media" ? "music" : (peekKind === "osd" ? "quick" : "notifications"));
        }
    }

    function media(title, artist, artUrl) {
        if (isOpen || (view === "peek" && peekKind === "notify") || (center && center.focusMode))
            return;
        peekApp = "\u266a";
        peekSummary = title;
        peekBody = artist;
        peekAppIcon = "";
        peekImage = artUrl;
        startPeek("media", 4000);
    }

    function osd(icon, progress) {
        if (isOpen)
            return;
        // A notification matters more than a volume tick, so let it finish.
        if (view === "peek" && peekKind === "notify")
            return;
        peekIcon = icon;
        peekProgress = progress;
        peekSummary = "";
        peekColor = "";
        startPeek("osd", 1600);
    }

    // The same small peek with a few words in place of a level, for a switch flipped from a keybind.
    function status(icon, text, color) {
        if (isOpen || (view === "peek" && peekKind === "notify"))
            return;
        peekColor = color || "";
        peekIcon = icon;
        peekProgress = -1;
        peekSummary = text;
        startPeek("osd", 1600);
    }

    Timer {
        id: peekTimer

        onTriggered: if (root.view === "peek") root.close()
    }
}
