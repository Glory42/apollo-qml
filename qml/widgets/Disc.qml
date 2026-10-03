import QtQuick
import QtQuick.Effects
import ".."

// Cover art as a record: round, with a spindle hole, turning while its music plays.
Item {
    id: root

    property string source: ""
    property int size: 64
    property bool spinning: false

    readonly property bool ready: pic.status === Image.Ready
    readonly property int turnSeconds: 9
    readonly property int stepsPerSecond: 12

    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.fill2
    }

    Icon {
        anchors.centerIn: parent
        visible: !root.ready
        name: "music"
        size: root.size * 0.4
        color: Theme.faint
    }

    Item {
        id: spinner

        anchors.fill: parent
        visible: root.ready

        Image {
            id: pic

            anchors.fill: parent
            source: root.source
            sourceSize.width: 2 * root.size
            sourceSize.height: 2 * root.size
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        Rectangle {
            id: mask

            anchors.fill: parent
            radius: width / 2
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            source: pic
            maskEnabled: true
            maskSource: mask
            // Lets the rim fade over a pixel instead of cutting hard, which shows as it turns.
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        // Turned in small steps a dozen times a second rather than every frame, which keeps the capsule
        // from being redrawn nonstop while music plays. Stopping keeps the angle, so it carries on from there.
        Timer {
            interval: 1000 / root.stepsPerSecond
            running: root.ready && root.spinning
            repeat: true
            onTriggered: spinner.rotation = (spinner.rotation + 360 / (root.turnSeconds * root.stepsPerSecond)) % 360
        }
    }

    Rectangle {
        anchors.centerIn: parent
        visible: root.ready
        width: Math.round(root.size * 0.16)
        height: width
        radius: width / 2
        color: Theme.hull
    }
}
