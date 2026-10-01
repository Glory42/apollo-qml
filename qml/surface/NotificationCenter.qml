import QtQuick
import Quickshell.Services.Notifications

// The one notification server for the whole shell; every monitor listens to `received`.
QtObject {
    id: root

    property int unread: 0
    property bool focusMode: false

    readonly property var tracked: server.trackedNotifications
    readonly property int count: tracked.values.length

    signal received(string app, string summary, string body, string icon, string image, bool critical, int timeout)

    function post(app, summary, body) {
        unread += 1;
        received(app, summary, body, "", "", false, 0);
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
            notification.tracked = true;
            root.unread += 1;
            root.received(notification.appName, notification.summary, notification.body, notification.appIcon,
                notification.image, notification.urgency === NotificationUrgency.Critical, notification.expireTimeout);
        }
    }
}
