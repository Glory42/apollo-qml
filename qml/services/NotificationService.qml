import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The one notification server for the whole shell; every monitor listens to `received`.
QtObject {
    id: root

    property int unread: 0
    // Past this many listed, the oldest is dismissed, so a long session does not keep every one and its image.
    readonly property int limit: 50
    property bool focusMode: false

    readonly property var tracked: server.trackedNotifications
    readonly property int count: tracked.values.length

    // `source` is the notification itself; `symbol` is the Material symbol a notification from inside the shell carries.
    signal received(string app, string summary, string body, string icon, string image, bool critical, int timeout, var source, string symbol)

    // The hint that carries a shell notification's Material symbol; read it with symbolOf().
    readonly property string symbolHint: "x-apollo-symbol"

    // The shell's own notifications go through this server like any other, so each one is listed as well as counted.
    function post(app, summary, body, critical, symbol) {
        const command = ["notify-send", "-a", app, "-u", critical === true ? "critical" : "normal"];
        if (symbol)
            command.push("-h", "string:" + symbolHint + ":" + symbol);
        command.push("--", summary, body || "");
        Quickshell.execDetached(command);
    }

    function symbolOf(notification) {
        const hints = notification ? notification.hints : null;
        return hints && hints[symbolHint] ? String(hints[symbolHint]) : "";
    }

    // Runs the newest notification's main action and dismisses it, as clicking it would.
    function invokeLast() {
        const list = tracked.values;
        for (let i = list.length - 1; i >= 0; i--) {
            const actions = list[i].actions || [];
            for (let j = 0; j < actions.length; j++) {
                if (actions[j].identifier === "default") {
                    actions[j].invoke();
                    list[i].dismiss();
                    return;
                }
            }
        }
    }

    function dismissAll() {
        const list = [...tracked.values];
        for (const notification of list)
            notification.dismiss();
    }

    property NotificationServer server: NotificationServer {
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodySupported: true

        onNotification: (notification) => {
            // A transient one, such as "screenshot taken", only peeks: it is not listed or counted as unread.
            notification.tracked = !notification.transient;
            const list = root.tracked.values;
            for (let i = 0; i < list.length - root.limit; i++)
                list[i].dismiss();
            if (!notification.transient)
                root.unread += 1;
            root.received(notification.appName, notification.summary, notification.body, notification.appIcon,
                notification.image, notification.urgency === NotificationUrgency.Critical, notification.expireTimeout, notification, root.symbolOf(notification));
        }
    }
}
