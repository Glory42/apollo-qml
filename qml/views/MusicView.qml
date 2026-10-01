import QtQuick
import "../core"
import "../widgets"

ViewFrame {
    id: root

    readonly property var mpris: ctl ? ctl.mpris : null
    readonly property var player: mpris ? mpris.activePlayer : null
    readonly property bool hasTrack: !!player && mpris.playerHasTrackInfo(player)

    Row {
        width: parent.width
        spacing: 14

        Rectangle {
            id: art

            width: 64
            height: 64
            radius: 16
            clip: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.fill2 }
                GradientStop { position: 1; color: Theme.fill }
            }

            Image {
                id: artImage

                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                source: root.mpris ? root.mpris.currentArtUrl : ""
                visible: status === Image.Ready
            }

            Icon {
                anchors.centerIn: parent
                name: "music"
                color: Theme.faint
                visible: artImage.status !== Image.Ready
            }
        }

        Column {
            width: parent.width - art.width - controls.width - 28
            anchors.verticalCenter: art.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: root.hasTrack ? root.mpris.currentTrack : "Nothing playing"
                color: Theme.fg
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.Medium
            }

            Text {
                width: parent.width
                text: root.hasTrack ? root.mpris.currentArtist : "Start a player to see it here"
                color: Theme.dim
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        Row {
            id: controls

            anchors.verticalCenter: art.verticalCenter
            spacing: 2
            opacity: root.player ? 1 : 0.35

            Repeater {
                model: [
                    { icon: "prev", size: 32 },
                    { icon: root.player && root.player.isPlaying ? "pause" : "play", size: 38 },
                    { icon: "next", size: 32 }
                ]

                Rectangle {
                    id: btn

                    required property int index
                    required property var modelData

                    width: modelData.size
                    height: modelData.size
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: btnArea.containsMouse ? Theme.fill2 : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        name: btn.modelData.icon
                    }

                    MouseArea {
                        id: btnArea

                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !!root.player
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (btn.index === 0) root.mpris.previous();
                            else if (btn.index === 1) root.player.togglePlaying();
                            else root.player.next();
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: track

        width: parent.width
        height: 10
        radius: 5
        color: Theme.fill2

        Rectangle {
            width: parent.width * (root.mpris ? root.mpris.trackProgress : 0)
            height: parent.height
            radius: 5
            color: Theme.fg
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.player && root.player.canSeek
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                const length = Number(root.player.length) || 0;
                if (length > 0) {
                    root.player.position = length * (mouse.x / width);
                    root.mpris.syncProgress();
                }
            }
        }
    }

    Row {
        width: parent.width

        Text {
            width: parent.width / 2
            text: root.mpris ? root.mpris.timePlayed : "0:00"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        Text {
            width: parent.width / 2
            horizontalAlignment: Text.AlignRight
            text: root.mpris ? root.mpris.timeTotal : "0:00"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
}
