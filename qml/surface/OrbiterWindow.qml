import QtQuick
import Quickshell
import ".."

// An orbiter on its screen: it floats in the middle, sized to its one content item.
SurfaceWindow {
    id: win

    default property alias content: slot.data
    // A bare orbiter has no hull of its own: its content floats directly over the screen.
    property bool bare: false

    piece: "orbiter"
    shown: win.open || hull.opacity > 0
    // A little larger than the orbiter, for its spring to overshoot into.
    implicitWidth: Math.ceil(slot.width * 1.08)
    implicitHeight: Math.ceil(slot.height * 1.08)

    // Only the orbiter takes input; the rest of this window falls through to what is underneath.
    mask: Region {
        x: Math.floor(hull.x)
        y: Math.floor(hull.y)
        width: Math.ceil(hull.width)
        height: Math.ceil(hull.height)
    }

    Rectangle {
        id: hull

        anchors.centerIn: parent
        width: slot.width
        height: slot.height
        radius: Theme.maxRadius
        color: win.bare ? "transparent" : Theme.hull
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.96

        Behavior on opacity {
            NumberAnimation { duration: Theme.fadeDuration / 2 }
        }

        Behavior on scale {
            SpringAnimation {
                spring: Theme.springStiffness
                damping: Theme.springDampingClose
                epsilon: 0.001
            }
        }

        // Clicks on the orbiter stay with it instead of reaching whatever is behind.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Item {
            id: slot

            width: children.length > 0 ? children[0].width : 0
            height: children.length > 0 ? children[0].height : 0
        }
    }
}
