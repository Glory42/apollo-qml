import QtQuick
import QtQuick.Shapes
import ".."

// The capsule's shape mirrored: it rises from the bottom edge to the size of its one content item.
Item {
    id: lander

    default property alias content: slot.data
    property bool open: false

    readonly property real cornerRadius: Math.min(height / 2, Theme.maxRadius)
    readonly property real fillet: Math.max(0, Math.min(Theme.fillet, height / 3))
    readonly property bool shown: open || height > 0.5
    readonly property real contentHeight: slot.height

    width: slot.width
    height: open ? slot.height : 0

    Behavior on height {
        SpringAnimation {
            spring: Theme.springStiffness
            damping: lander.open ? Theme.springDamping : Theme.springDampingClose
            epsilon: 0.4
        }
    }

    // Clicks on the lander stay with it instead of reaching whatever is behind.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Shape {
        width: lander.width
        height: lander.height
        visible: lander.height > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Theme.hull
            strokeColor: "transparent"
            startX: -lander.fillet
            startY: lander.height

            PathLine { x: lander.width + lander.fillet; y: lander.height }
            PathArc { x: lander.width; y: lander.height - lander.fillet; radiusX: lander.fillet; radiusY: lander.fillet }
            PathLine { x: lander.width; y: lander.cornerRadius }
            PathArc { x: lander.width - lander.cornerRadius; y: 0; radiusX: lander.cornerRadius; radiusY: lander.cornerRadius; direction: PathArc.Counterclockwise }
            PathLine { x: lander.cornerRadius; y: 0 }
            PathArc { x: 0; y: lander.cornerRadius; radiusX: lander.cornerRadius; radiusY: lander.cornerRadius; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: lander.height - lander.fillet }
            PathArc { x: -lander.fillet; y: lander.height; radiusX: lander.fillet; radiusY: lander.fillet }
        }
    }

    // The content hangs from the bottom edge while open, and rides the top edge down while closing so it is not cut off.
    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: slot

            y: lander.open ? parent.height - height : 0
            width: children.length > 0 ? children[0].width : 0
            height: children.length > 0 ? children[0].height : 0
            opacity: lander.open ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.fadeDuration / 2 }
            }
        }
    }
}
