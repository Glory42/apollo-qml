import QtQuick
import "../common"

Item {
    id: powerMenuView

    property var controlCenter: null

    anchors.fill: parent
    visible: controlCenter && controlCenter.powerViewActive

    Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    Row {
        anchors.centerIn: parent
        spacing: 26

        Repeater {
            model: [
                { glyph: "", action: "triggerLock" },
                { glyph: "", action: "triggerSleep" },
                { glyph: "", action: "triggerRestart" },
                { glyph: "", action: "triggerShutdown" }
            ]

            delegate: Item {
                width: 56
                height: 56

                Text {
                    anchors.centerIn: parent
                    text: modelData.glyph
                    color: StyleTokens.textPrimary
                    font.pixelSize: 38
                    font.family: powerMenuView.controlCenter ? powerMenuView.controlCenter.iconFontFamily : ""
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (powerMenuView.controlCenter && powerMenuView.controlCenter[modelData.action])
                            powerMenuView.controlCenter[modelData.action]();
                    }
                }
            }
        }
    }
}
