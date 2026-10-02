import QtQuick
import "../.."

// Shared shell for every open view: the dock on top with a padded content column underneath.
Item {
    id: root

    property var ctl: null
    property alias spacing: body.spacing
    default property alias content: body.data

    implicitWidth: Theme.openWidth
    implicitHeight: 4 + dock.implicitHeight + 6 + body.implicitHeight + 20

    Column {
        id: body

        x: 20
        y: dock.y + dock.implicitHeight + 6
        width: parent.width - 40
        spacing: 14
    }

    Dock {
        id: dock

        y: 4
        ctl: root.ctl
    }
}
