import QtQuick
import "../core"
import "../widgets"

// Shared shell for every open view: padded content column with the dock underneath.
Item {
    id: root

    property var ctl: null
    property alias spacing: body.spacing
    default property alias content: body.data

    implicitWidth: Theme.openWidth
    implicitHeight: 20 + body.implicitHeight + 6 + dock.implicitHeight + 6

    Column {
        id: body

        x: 20
        y: 20
        width: parent.width - 40
        spacing: 14
    }

    Dock {
        id: dock

        y: 20 + body.implicitHeight + 6
        ctl: root.ctl
    }
}
