import QtQuick
import "../common"
import "../controlcenter"

Item {
    id: timerRoot

    signal controlPressed()
    signal keyboardFocusRequested()
    signal timerToggleRequested(int hours, int minutes)
    signal timerResetRequested()
    signal timerDurationRequested(int hours, int minutes)

    readonly property var userConfig: UserConfig

    property string textFontFamily: userConfig.textFontFamily
    property int timerSelectedHours: 0
    property int timerSelectedMinutes: 5
    property int timerTotalSeconds: 300
    property int timerRemainingSeconds: 0
    property bool timerRunning: false
    property bool timerActive: false
    property real animatedProgress: 0
    property string focusTarget: "hour"

    readonly property int displaySeconds: timerActive ? timerRemainingSeconds : 0
    readonly property real targetProgress: timerActive && timerTotalSeconds > 0 ? timerRemainingSeconds / timerTotalSeconds : 0
    readonly property bool canStart: inputTotalSeconds() > 0 && (!timerActive || timerRemainingSeconds > 0)
    readonly property string timeText: {
        const hours = Math.floor(displaySeconds / 3600);
        const minutes = Math.floor((displaySeconds % 3600) / 60);
        const seconds = displaySeconds % 60;
        const minuteText = minutes < 10 ? "0" + minutes : "" + minutes;
        const secondText = seconds < 10 ? "0" + seconds : "" + seconds;

        if (hours > 0)
            return hours + ":" + minuteText + ":" + secondText;
        return minuteText + ":" + secondText;
    }

    function clampInt(value, minValue, maxValue) {
        const parsed = parseInt(value, 10);
        if (isNaN(parsed)) return minValue;
        return Math.max(minValue, Math.min(maxValue, parsed));
    }

    function inputHours() {
        return clampInt(hourInput.text, 0, 23);
    }

    function inputMinutes() {
        return clampInt(minuteInput.text, 0, 59);
    }

    function inputTotalSeconds() {
        return inputHours() * 3600 + inputMinutes() * 60;
    }

    function syncDurationFromInputs() {
        timerDurationRequested(inputHours(), inputMinutes());
        progressRing.requestPaint();
    }

    function normalizeInputs() {
        hourInput.text = "" + timerSelectedHours;
        minuteInput.text = timerSelectedMinutes < 10 ? "0" + timerSelectedMinutes : "" + timerSelectedMinutes;
    }

    function resetTimer() {
        timerResetRequested();
        progressRing.requestPaint();
    }

    function toggleTimer() {
        timerToggleRequested(inputHours(), inputMinutes());
    }

    function grabKeyboardFocus() {
        if (focusTarget === "minute")
            minuteInput.grabKeyboardFocus();
        else
            hourInput.grabKeyboardFocus();
    }

    onTargetProgressChanged: animatedProgress = targetProgress
    onAnimatedProgressChanged: progressRing.requestPaint()
    onTimerSelectedHoursChanged: normalizeInputs()
    onTimerSelectedMinutesChanged: normalizeInputs()
    Component.onCompleted: normalizeInputs()

    Behavior on animatedProgress {
        NumberAnimation {
            duration: 700
            easing.type: Easing.InOutCubic
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 18

        Item {
            width: 116
            height: parent.height

            Canvas {
                id: progressRing

                anchors.centerIn: parent
                width: 104
                height: 104

                onPaint: {
                    const ctx = getContext("2d");
                    const centerX = width / 2;
                    const centerY = height / 2;
                    const lineWidth = 5;
                    const radius = Math.min(width, height) / 2 - lineWidth / 2;
                    const startAngle = -Math.PI / 2;
                    const progress = Math.max(0, Math.min(1, timerRoot.animatedProgress));
                    const endAngle = startAngle - Math.PI * 2 * progress;

                    ctx.clearRect(0, 0, width, height);
                    ctx.lineCap = "round";
                    ctx.lineWidth = lineWidth;

                    ctx.beginPath();
                    ctx.strokeStyle = "#2b2e35";
                    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                    ctx.stroke();

                    if (progress > 0) {
                        ctx.beginPath();
                        ctx.strokeStyle = "#ff9f0a";
                        ctx.arc(centerX, centerY, radius, startAngle, endAngle, true);
                        ctx.stroke();
                    }
                }
            }

            Text {
                anchors.centerIn: progressRing
                text: timerRoot.timeText
                color: "#ffffff"
                font.pixelSize: timerRoot.displaySeconds >= 3600 ? timerRoot.userConfig.bodyFontSize + 2 : timerRoot.userConfig.bodyFontSize + 8
                font.family: timerRoot.textFontFamily
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Column {
            width: parent.width - 173
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Row {
                width: parent.width
                height: 42
                spacing: 8

                TimerInput {
                    id: hourInput

                    width: (parent.width - 8) / 2
                    height: parent.height
                    label: "时"
                    text: "0"
                    textFontFamily: timerRoot.textFontFamily
                    onKeyboardFocusRequested: {
                        timerRoot.focusTarget = "hour";
                        timerRoot.keyboardFocusRequested();
                    }
                    onEditingFinished: {
                        timerRoot.syncDurationFromInputs();
                        timerRoot.normalizeInputs();
                    }
                }

                TimerInput {
                    id: minuteInput

                    width: (parent.width - 8) / 2
                    height: parent.height
                    label: "分"
                    text: "05"
                    textFontFamily: timerRoot.textFontFamily
                    onKeyboardFocusRequested: {
                        timerRoot.focusTarget = "minute";
                        timerRoot.keyboardFocusRequested();
                    }
                    onEditingFinished: {
                        timerRoot.syncDurationFromInputs();
                        timerRoot.normalizeInputs();
                    }
                }
            }

            Row {
                width: parent.width
                height: 34
                spacing: 8

                TimerButton {
                    width: (parent.width - 8) / 2
                    height: parent.height
                    label: timerRoot.timerRunning ? "Stop" : (timerRoot.timerActive && timerRoot.timerRemainingSeconds < timerRoot.timerTotalSeconds && timerRoot.timerRemainingSeconds > 0 ? "Continue" : "Start")
                    enabled: timerRoot.timerRunning || timerRoot.canStart
                    accent: true
                    textFontFamily: timerRoot.textFontFamily
                    onClicked: timerRoot.toggleTimer()
                    onPressed: timerRoot.controlPressed()
                }

                TimerButton {
                    width: (parent.width - 8) / 2
                    height: parent.height
                    label: "Reset"
                    textFontFamily: timerRoot.textFontFamily
                    onClicked: timerRoot.resetTimer()
                    onPressed: timerRoot.controlPressed()
                }
            }
        }
    }

    component TimerInput: Item {
        id: inputRoot

        signal editingFinished()
        signal keyboardFocusRequested()

        property alias text: input.text
        property string label: ""
        property string textFontFamily: ""
        property int focusAttempts: 0

        function grabKeyboardFocus() {
            inputRoot.keyboardFocusRequested();
            focusAttempts = 4;
            input.forceActiveFocus();
            input.selectAll();
            focusRetryTimer.restart();
        }

        Timer {
            id: focusRetryTimer

            interval: 16
            repeat: true
            onTriggered: {
                input.forceActiveFocus();
                input.selectAll();
                inputRoot.focusAttempts -= 1;
                if (inputRoot.focusAttempts <= 0)
                    stop();
            }
        }

        Item {
            anchors.fill: parent

            MatteSurface {
                anchors.fill: parent
                radius: 10
                hovered: input.activeFocus || inputMouseArea.containsMouse
                pressed: inputMouseArea.pressed
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 9
                color: StyleTokens.transparent
                border.width: 1
                border.color: input.activeFocus ? "#ff9f0a" : "#2b2e35"
            }

            MouseArea {
                id: inputMouseArea

                anchors.fill: parent
                z: 2
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                preventStealing: true
                onPressed: (mouse) => {
                    inputRoot.grabKeyboardFocus();
                    mouse.accepted = true;
                }
                onClicked: (mouse) => {
                    mouse.accepted = true;
                }
            }

            Row {
                z: 1
                anchors.centerIn: parent
                spacing: 4

                TextInput {
                    id: input

                    width: 42
                    property bool sanitizing: false
                    color: "#f5f5f7"
                    selectionColor: "#ff9f0a"
                    selectedTextColor: "#111111"
                    font.pixelSize: UserConfig.bodyFontSize + 2
                    font.family: inputRoot.textFontFamily
                    font.weight: Font.DemiBold
                    horizontalAlignment: TextInput.AlignRight
                    validator: IntValidator {
                        bottom: 0
                        top: 99
                    }
                    inputMethodHints: Qt.ImhDigitsOnly
                    cursorVisible: activeFocus
                    onActiveFocusChanged: if (activeFocus) inputRoot.keyboardFocusRequested()
                    onTextChanged: {
                        if (sanitizing)
                            return;

                        const digits = text.replace(/[^0-9]/g, "").slice(0, 2);
                        if (digits !== text) {
                            sanitizing = true;
                            text = digits;
                            sanitizing = false;
                        }
                    }
                    onEditingFinished: inputRoot.editingFinished()
                    Keys.onReturnPressed: inputRoot.editingFinished()
                    Keys.onEnterPressed: inputRoot.editingFinished()
                }

                Text {
                    text: inputRoot.label
                    color: "#9b9da4"
                    font.pixelSize: UserConfig.bodyFontSize - 3
                    font.family: inputRoot.textFontFamily
                    font.weight: Font.Medium
                }
            }
        }
    }

    component TimerButton: Item {
        id: buttonRoot

        signal pressed()
        signal clicked()

        property string label: ""
        property bool accent: false
        property string textFontFamily: ""

        opacity: enabled ? 1.0 : 0.45
        scale: buttonArea.pressed ? 0.96 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 90
                easing.type: Easing.OutCubic
            }
        }

        Item {
            anchors.fill: parent

            MatteSurface {
                anchors.fill: parent
                radius: 10
                hovered: buttonArea.containsMouse
                pressed: buttonArea.pressed
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 9
                color: buttonRoot.accent
                    ? (buttonArea.pressed ? "#d98500" : "#ff9f0a")
                    : StyleTokens.transparent
                border.width: 1
                border.color: buttonRoot.accent ? "#ff9f0a" : "#2b2e35"
            }
        }

        Text {
            anchors.centerIn: parent
            text: buttonRoot.label
            color: buttonRoot.accent ? "#111111" : "#f5f5f7"
            font.pixelSize: UserConfig.bodyFontSize - 2
            font.family: buttonRoot.textFontFamily
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: buttonArea

            anchors.fill: parent
            enabled: buttonRoot.enabled
            hoverEnabled: true
            preventStealing: true
            onPressed: (mouse) => {
                buttonRoot.pressed();
                mouse.accepted = true;
            }
            onClicked: buttonRoot.clicked()
        }
    }
}
