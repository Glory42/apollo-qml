import QtQuick
import "CalendarMath.js" as CalendarMath
import "../core"
import "../widgets"

ViewFrame {
    id: root

    property int offset: 0

    readonly property date today: new Date()
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int blanks: CalendarMath.firstDayOfWeek(shown.getFullYear(), shown.getMonth())
    readonly property int dayCount: CalendarMath.daysInMonth(shown.getFullYear(), shown.getMonth())

    Item {
        width: parent.width
        height: 24

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(root.shown, "MMMM yyyy")
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: [-1, 1]

                Rectangle {
                    required property int modelData

                    width: 24
                    height: 24
                    radius: 12
                    color: navArea.containsMouse ? Theme.fill2 : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        size: 14
                        rotation: parent.modelData < 0 ? 180 : 0
                        name: "chevron"
                        color: Theme.dim
                    }

                    MouseArea {
                        id: navArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.offset += parent.modelData
                    }
                }
            }
        }
    }

    Grid {
        width: parent.width
        columns: 7

        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]

            Text {
                required property string modelData

                width: parent.width / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.faint
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        Repeater {
            model: root.blanks + root.dayCount

            Item {
                required property int index
                readonly property int day: index - root.blanks + 1
                readonly property bool isToday: offset === 0 && day === root.today.getDate()

                width: parent.width / 7
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 14
                    visible: parent.isToday
                    color: Theme.fg
                }

                Text {
                    anchors.centerIn: parent
                    visible: parent.day > 0
                    text: parent.day
                    color: parent.isToday ? Theme.tileOnInk : Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: parent.isToday ? Font.DemiBold : Font.Normal
                }
            }
        }
    }
}
