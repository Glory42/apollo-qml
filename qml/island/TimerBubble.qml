import QtQuick
import "../common"

Item {
    id: timerBubble

    property var root: null
    property var islandContainer: null
    property var mainCapsule: null

    property bool mounted: false
    property real reveal: islandContainer && islandContainer.timerBubbleWanted ? 1 : 0
    readonly property int bubbleSize: 34
    readonly property real hiddenX: mainCapsule ? mainCapsule.x + mainCapsule.width - width * 0.62 : 0
    readonly property real shownX: mainCapsule ? mainCapsule.x + mainCapsule.width + 8 : 0
    readonly property real centerY: mainCapsule ? mainCapsule.y + mainCapsule.height / 2 - height / 2 : 0

    width: bubbleSize
    height: bubbleSize
    x: hiddenX + (shownX - hiddenX) * reveal
    y: centerY + (1 - reveal) * 10
    z: 6
    visible: mounted
    opacity: reveal * (root ? root.autoHideProgress : 1)
    scale: (0.55 + reveal * 0.45) * (0.96 + (root ? root.autoHideProgress : 1) * 0.04) * (1 + (islandContainer ? islandContainer.timerCompletionPulse : 0) * 0.12)
    transformOrigin: Item.Center

    Connections {
        target: islandContainer

        function onTimerBubbleWantedChanged() {
            timerBubbleShowAnimation.stop();
            timerBubbleHideAnimation.stop();

            if (islandContainer.timerBubbleWanted) {
                timerBubble.mounted = true;
                timerBubbleShowAnimation.restart();
            } else {
                timerBubbleHideAnimation.restart();
            }
        }

        function onTimerProgressChanged() {
            timerBubbleRing.requestPaint();
        }

        function onTimerRemainingSecondsChanged() {
            timerBubbleRing.requestPaint();
        }

        function onTimerTotalSecondsChanged() {
            timerBubbleRing.requestPaint();
        }

        function onTimerCompletionAnimatingChanged() {
            timerBubbleRing.requestPaint();
        }

        function onTimerCompletionFlashChanged() {
            timerBubbleRing.requestPaint();
        }
    }

    NumberAnimation {
        id: timerBubbleShowAnimation

        target: timerBubble
        property: "reveal"
        from: timerBubble.reveal
        to: 1
        duration: 360
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: timerBubbleHideAnimation

        target: timerBubble
        property: "reveal"
        from: timerBubble.reveal
        to: 0
        duration: 280
        easing.type: Easing.InCubic
        onStopped: {
            if (!islandContainer.timerBubbleWanted && timerBubble.reveal <= 0.001)
                timerBubble.mounted = false;
        }
    }

    SequentialAnimation {
        id: timerBubbleCompletionAnimation

        running: islandContainer ? islandContainer.timerCompletionAnimating : false

        onStarted: {
            timerBubbleShowAnimation.stop();
            timerBubbleHideAnimation.stop();
            timerBubble.mounted = true;
            timerBubble.reveal = 1;
        }

        onStopped: {
            if (islandContainer.timerCompletionAnimating)
                islandContainer.timerCompletionAnimating = false;
            islandContainer.timerCompletionPulse = 0;
            islandContainer.timerCompletionFlash = 0;
            timerBubbleRing.requestPaint();
        }

        ParallelAnimation {
            NumberAnimation {
                target: islandContainer
                property: "timerCompletionPulse"
                from: 0
                to: 1
                duration: 140
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: islandContainer
                property: "timerCompletionFlash"
                from: 0
                to: 1
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: islandContainer
                property: "timerCompletionPulse"
                from: 1
                to: 0
                duration: 380
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: islandContainer
                property: "timerCompletionFlash"
                from: 1
                to: 0
                duration: 380
                easing.type: Easing.InOutQuad
            }
        }

        PauseAnimation {
            duration: 380
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: width / 2
        color: StyleTokens.black
    }

    Canvas {
        id: timerBubbleRing

        anchors.fill: parent
        anchors.margins: 1

        Component.onCompleted: requestPaint()
        onVisibleChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            const centerX = width / 2;
            const centerY = height / 2;
            const completionActive = islandContainer.timerCompletionAnimating;
            const flash = Math.max(0, Math.min(1, islandContainer.timerCompletionFlash));
            const lineWidth = completionActive ? 3 + flash : 3;
            const radius = Math.min(width, height) / 2 - lineWidth / 2;
            const progress = Math.max(0, Math.min(1, islandContainer.timerProgress));
            const startAngle = -Math.PI / 2;
            const endAngle = startAngle - Math.PI * 2 * progress;

            ctx.clearRect(0, 0, width, height);
            ctx.lineCap = "round";
            ctx.lineWidth = lineWidth;

            ctx.beginPath();
            ctx.strokeStyle = "#303036";
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
            ctx.stroke();

            if (completionActive) {
                if (flash > 0) {
                    ctx.beginPath();
                    ctx.lineWidth = lineWidth + 1.5;
                    ctx.strokeStyle = "rgba(255, 204, 0, " + (0.18 * flash) + ")";
                    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                    ctx.stroke();
                }

                ctx.beginPath();
                ctx.lineWidth = lineWidth;
                ctx.strokeStyle = "rgba(255, 204, 0, " + (0.72 + 0.28 * flash) + ")";
                ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                ctx.stroke();
            } else if (progress > 0) {
                ctx.beginPath();
                ctx.strokeStyle = "#ffcc00";
                ctx.arc(centerX, centerY, radius, startAngle, endAngle, true);
                ctx.stroke();
            }
        }
    }

    Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -1
        text: "\u{F051B}"
        color: "white"
        font.pixelSize: root ? root.iconFontSize - 1 : 13
        font.family: root ? root.iconFontFamily : ""
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        anchors.fill: parent
        enabled: timerBubble.mounted && root && root.autoHideProgress > 0.5
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            if (root && root.autoHideEnabled) {
                root.autoHidePointerInside = true;
                root.showAutoHiddenIsland();
            }
        }
        onExited: {
            if (root && root.autoHideEnabled) {
                root.autoHidePointerInside = false;
                root.scheduleAutoHide();
            }
        }
        onClicked: if (islandContainer) islandContainer.showExpandedTimerPage()
    }
}
