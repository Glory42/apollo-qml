import QtQuick
import Quickshell
import "../.."

// Where sound goes and comes from: output devices, each app that is playing, and microphones.
ViewFrame {
    id: root

    readonly property var sound: ctl ? ctl.sound : null
    readonly property var sink: sound ? sound.sink : null
    readonly property var source: sound ? sound.source : null

    spacing: 10

    // A device to pick: the one in use is filled in.
    component DeviceRow: Rectangle {
        id: row

        required property var modelData
        property bool current: false
        signal picked()

        width: parent ? parent.width : 0
        height: 34
        radius: 12
        color: row.current ? Theme.fill : (rowArea.containsMouse ? Theme.fill : "transparent")

        Rectangle {
            id: dot

            x: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: row.current ? Theme.fg : "transparent"
            border.width: row.current ? 0 : 1.5
            border.color: Theme.faint
        }

        Text {
            anchors.left: dot.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.sound ? root.sound.deviceName(row.modelData) : ""
            elide: Text.ElideRight
            color: row.current ? Theme.fg : Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: row.current ? Font.Medium : Font.Normal
        }

        MouseArea {
            id: rowArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.picked()
        }
    }

    component SectionLabel: Text {
        leftPadding: 4
        topPadding: 6
        color: Theme.faint
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    DetailHeader {
        width: parent.width
        ctl: root.ctl
        title: "Sound"
        subtitle: root.sink ? root.sound.deviceName(root.sink) : "No output"
        checked: !!root.sink && !!root.sink.audio && !root.sink.audio.muted
        onToggled: root.sound.toggleMute(root.sink)
    }

    Flickable {
        width: parent.width
        height: Math.min(contentHeight, 380)
        contentHeight: sections.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: sections

            width: parent.width
            spacing: 4

            SectionLabel {
                text: "Output"
            }

            QuietSlider {
                width: parent.width
                icon: root.sink && root.sink.audio && root.sink.audio.muted ? "mute" : "volume"
                value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                iconClickable: true
                onMoved: (v) => root.sound.setVolume(root.sink, v)
                onIconClicked: root.sound.toggleMute(root.sink)
            }

            Repeater {
                model: ScriptModel {
                    values: root.sound ? root.sound.outputs : []
                }

                DeviceRow {
                    current: modelData === root.sink
                    onPicked: root.sound.setOutput(modelData)
                }
            }

            SectionLabel {
                visible: appList.count > 0
                text: "Apps"
            }

            Repeater {
                id: appList

                model: ScriptModel {
                    values: root.sound ? root.sound.apps : []
                    objectProp: "key"
                }

                // One row per app: its name, and one slider for all its streams.
                Item {
                    id: app

                    required property var modelData
                    readonly property bool muted: root.sound.appMuted(modelData)

                    width: parent.width
                    height: 34

                    Text {
                        id: appName

                        x: 4
                        anchors.verticalCenter: parent.verticalCenter
                        // The same for every app, so their sliders line up; a long name is cut short.
                        width: 72
                        text: app.modelData.name
                        elide: Text.ElideRight
                        color: app.muted ? Theme.faint : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    QuietSlider {
                        anchors.left: appName.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        icon: app.muted ? "mute" : "volume"
                        value: root.sound.appVolume(app.modelData)
                        maximum: root.sound.appMaximum
                        iconClickable: true
                        onMoved: (v) => root.sound.setAppVolume(app.modelData, v)
                        onIconClicked: root.sound.toggleAppMute(app.modelData)
                    }
                }
            }

            SectionLabel {
                text: "Input"
            }

            QuietSlider {
                visible: !!root.source
                width: parent.width
                icon: root.source && root.source.audio && root.source.audio.muted ? "mic_off" : "mic"
                value: root.source && root.source.audio ? root.source.audio.volume : 0
                iconClickable: true
                onMoved: (v) => root.sound.setVolume(root.source, v)
                onIconClicked: root.sound.toggleMute(root.source)
            }

            Repeater {
                model: ScriptModel {
                    values: root.sound ? root.sound.inputs : []
                }

                DeviceRow {
                    current: modelData === root.source
                    onPicked: root.sound.setInput(modelData)
                }
            }
        }
    }
}
