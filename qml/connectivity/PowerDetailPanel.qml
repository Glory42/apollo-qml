import QtQuick
import "../common"

Item {
    id: root

    property var provider: null
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property string heroFontFamily: textFontFamily
    property real presentationProgress: 1

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: StyleTokens.module
        opacity: 0.9
    }

    Item {
        id: contentRoot
        anchors.fill: parent
        anchors.margins: 16
        opacity: 0.45 + root.presentationProgress * 0.55

        Behavior on opacity {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        Flickable {
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: contentColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: contentColumn
                width: parent.width

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Repeater {
                        model: [
                            { glyph: "", action: "triggerLock" },
                            { glyph: "", action: "triggerSleep" },
                            { glyph: "", action: "triggerRestart" },
                            { glyph: "", action: "triggerShutdown" }
                        ]

                        delegate: Rectangle {
                            width: 48
                            height: 48
                            radius: 14
                            color: StyleTokens.secondaryButton

                            Text {
                                anchors.centerIn: parent
                                text: modelData.glyph
                                color: StyleTokens.textPrimary
                                font.pixelSize: 17
                                font.family: root.iconFontFamily
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (root.provider && root.provider[modelData.action])
                                        root.provider[modelData.action]();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
