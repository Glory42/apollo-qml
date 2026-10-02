import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import ".."

// Slanted picture cards, the current one large and its neighbours peeking out; entries are { image, title, colors, accent }.
Item {
    id: root

    property var model: []
    property int currentIndex: 0
    property string emptyText: ""

    readonly property int bigWidth: 660
    readonly property int bigHeight: 372
    readonly property int sliceWidth: 110
    readonly property int sliceHeight: 300
    readonly property int sliceStep: 78
    readonly property int skew: 28
    readonly property var entry: model[currentIndex] || null

    signal chosen(int index)
    signal dismissed()

    function move(delta) {
        if (model.length > 0)
            currentIndex = Math.max(0, Math.min(model.length - 1, currentIndex + delta));
    }

    width: bigWidth + 6 * sliceStep + 2 * sliceWidth
    height: bigHeight + 64
    focus: true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape)
            root.dismissed();
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
            root.move(1);
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab)
            root.move(-1);
        else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.entry)
            root.chosen(root.currentIndex);
        else
            return;
        event.accepted = true;
    }

    Repeater {
        model: root.model

        Item {
            id: card

            required property var modelData
            required property int index

            readonly property int offset: index - root.currentIndex
            readonly property bool selected: offset === 0
            readonly property real bigX: (root.width - root.bigWidth) / 2

            visible: Math.abs(offset) <= 4
            x: selected ? bigX : (offset < 0 ? bigX + root.skew - root.sliceWidth + (offset + 1) * root.sliceStep : bigX + root.bigWidth - root.skew + (offset - 1) * root.sliceStep)
            y: selected ? 0 : (root.bigHeight - root.sliceHeight) / 2
            width: selected ? root.bigWidth : root.sliceWidth
            height: selected ? root.bigHeight : root.sliceHeight
            z: 100 - Math.abs(offset)

            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Item {
                id: mask

                anchors.fill: parent
                visible: false
                layer.enabled: true

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: "white"
                        strokeColor: "transparent"
                        startX: root.skew
                        startY: 0

                        PathLine { x: card.width; y: 0 }
                        PathLine { x: card.width - root.skew; y: card.height }
                        PathLine { x: 0; y: card.height }
                        PathLine { x: root.skew; y: 0 }
                    }
                }
            }

            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.smooth: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: mask
                    maskThresholdMin: 0.3
                    maskSpreadAtMin: 0.3
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.fill
                }

                Image {
                    anchors.fill: parent
                    source: card.modelData.image ? "file://" + card.modelData.image : ""
                    sourceSize.width: 1320
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.hull
                    opacity: card.selected ? 0 : 0.45

                    Behavior on opacity { NumberAnimation { duration: 220 } }
                }
            }

            // The current card is outlined in its own accent, so a theme's card previews the theme.
            Shape {
                anchors.fill: parent
                visible: card.selected
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: card.modelData.accent || Theme.accent
                    strokeWidth: 2
                    startX: root.skew
                    startY: 1

                    PathLine { x: card.width - 1; y: 1 }
                    PathLine { x: card.width - root.skew; y: card.height - 1 }
                    PathLine { x: 1; y: card.height - 1 }
                    PathLine { x: root.skew; y: 1 }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (card.selected)
                        root.chosen(card.index);
                    else
                        root.currentIndex = card.index;
                }
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: caption.width + 36
        height: 40
        radius: 20
        color: Theme.hull

        Row {
            id: caption

            anchors.centerIn: parent
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.entry ? root.entry.title : root.emptyText
                color: root.entry ? Theme.fg : Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!root.entry && !!root.entry.colors && root.entry.colors.length > 0
                spacing: 5

                Repeater {
                    model: root.entry && root.entry.colors ? root.entry.colors : []

                    Rectangle {
                        required property var modelData

                        width: 12
                        height: 12
                        radius: 6
                        color: modelData
                        border.width: 1
                        border.color: Theme.line
                    }
                }
            }
        }
    }
}
