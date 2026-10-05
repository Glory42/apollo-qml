import QtQuick
import Quickshell
import ".."

// The ways to end or pause a session. Nothing confirms, so the highlight starts on Lock: a reflex Enter only locks.
Scope {
    id: root

    property string onlyScreen: ""
    readonly property bool isOpen: win.open

    signal opened()
    signal lockRequested()
    signal suspendRequested()

    readonly property var actions: [
        { label: "Lock", icon: "lock", command: null },
        { label: "Log out", icon: "logout", command: ["sh", "-c", Config.logoutCommand] },
        { label: "Suspend", icon: "moon", command: null },
        { label: "Restart", icon: "restart", command: ["systemctl", "reboot"] },
        { label: "Shut down", icon: "power", command: ["systemctl", "poweroff"] }
    ]

    function open() {
        if (win.open)
            return;
        row.current = 0;
        win.show();
        root.opened();
    }

    function close() {
        win.hide();
    }

    function toggle() {
        if (win.open)
            close();
        else
            open();
    }

    function run(index) {
        close();
        // Lock and Suspend have no command: Airlock locks, and IdleService suspends once the lock is up.
        if (root.actions[index].command)
            Quickshell.execDetached(root.actions[index].command);
        else if (root.actions[index].label === "Suspend")
            root.suspendRequested();
        else
            root.lockRequested();
    }

    LanderWindow {
        id: win

        piece: "splashdown"
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

                    width: 84
                    height: 76
                    radius: 18
                    color: row.current === button.index ? Theme.fill2 : "transparent"

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 16
                        size: 22
                        name: button.modelData.icon
                        color: button.modelData.icon === "power" ? Theme.danger : Theme.fg
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
