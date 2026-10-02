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

        // Pausing keeps the angle, so the record carries on from where it stopped.
        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 9000
            loops: Animation.Infinite
            running: root.ready
            paused: running && !root.spinning
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
