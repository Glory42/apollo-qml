import QtQuick
import QtQuick.Shapes
import "../common"
import "../weather"

    Column {
        id: mainContent

        property var controlCenter: null
        readonly property alias brightnessCardPressed: brightnessCard.pressed
        readonly property alias volumeCardPressed: volumeCard.pressed

        anchors.fill: parent
        visible: !controlCenter.powerViewActive
        spacing: 12

        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Item {
            width: parent.width
            height: 28

            Item {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 220
                height: parent.height

                Text {
                    id: timeLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: controlCenter.currentTime
                    color: StyleTokens.textPrimaryBright
                    font.pixelSize: 19
                    font.family: controlCenter.heroFontFamily
                    font.weight: Font.Bold
                    font.letterSpacing: -0.45
                }

                Text {
                    id: dateLabel
                    anchors.left: timeLabel.right
                    anchors.leftMargin: 10
                    anchors.baseline: timeLabel.baseline
                    text: controlCenter.currentDateLabel
                    color: dateMouse.containsMouse ? StyleTokens.textPrimaryBright : controlCenter.textSecondary
                    font.pixelSize: 12
                    font.family: controlCenter.textFontFamily
                    font.weight: Font.Medium

                    Behavior on color { ColorAnimation { duration: 100 } }

                    MouseArea {
                        id: dateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlCenter.calendarRequested()
                    }
                }

                Rectangle {
                    id: weatherChip
                    anchors.left: dateLabel.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    height: 22
                    width: weatherChipRow.implicitWidth + 14
                    radius: 11
                    color: weatherHover.containsMouse ? StyleTokens.moduleHover : StyleTokens.module
                    visible: controlCenter.weatherService && controlCenter.weatherService.hasData && controlCenter.userConfig.weatherEnabled

                    Row {
                        id: weatherChipRow
                        anchors.centerIn: parent
                        spacing: 4

                        WeatherIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            weatherType: controlCenter.weatherService ? controlCenter.weatherService.weatherType : "sunny"
                            iconColor: controlCenter.weatherService ? controlCenter.weatherService.iconColor : "#f4c542"
                            glyph: controlCenter.weatherService ? controlCenter.weatherService.iconGlyph : "\ue30d"
                            iconFontFamily: controlCenter.iconFontFamily
                            iconSize: 14
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: controlCenter.weatherService ? controlCenter.weatherService.tempString : ""
                            color: StyleTokens.textPrimary
                            font.pixelSize: 11
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: weatherHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlCenter.weatherRequested()
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Text {
                    text: controlCenter.chargingIconGlyph
                    color: StyleTokens.white
                    font.pixelSize: 13
                    font.family: controlCenter.iconFontFamily
                    visible: controlCenter.isCharging
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: controlCenter.batteryCapacity + "%"
                    color: StyleTokens.white
                    font.pixelSize: 13
                    font.family: controlCenter.textFontFamily
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: 28
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        anchors.rightMargin: 2
                        radius: 4
                        color: StyleTokens.transparent
                        border.color: StyleTokens.textSecondary
                        border.width: 1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 2
                            radius: 2
                            width: (parent.width - 4) * (controlCenter.batteryCapacity / 100.0)
                            color: {
                                if (controlCenter.batteryCapacity <= 10) return StyleTokens.danger;
                                if (controlCenter.batteryCapacity <= 20) return StyleTokens.warning;
                                return StyleTokens.success;
                            }

                            Behavior on width {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 2
                        height: 6
                        radius: 1
                        color: StyleTokens.textSecondary
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 80

            Row {
                id: connectivityCardsRow
                anchors.fill: parent
                spacing: 12

                Rectangle {
                    id: wifiCard
                    width: (connectivityCardsRow.width - connectivityCardsRow.spacing) / 2
                    height: connectivityCardsRow.height
                    radius: 20
                    color: StyleTokens.clearBlack
                    clip: true

                    MatteSurface {
                        anchors.fill: parent
                        radius: parent.radius
                        hovered: wifiCardMouse.containsMouse || controlCenter.wifiPanelOpen
                    }

                    MouseArea {
                        id: wifiCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        text: controlCenter.wifiGlyph
                        color: controlCenter.wifiEnabled ? controlCenter.cardAccent : StyleTokens.textDisabled
                        font.pixelSize: 18
                        font.family: controlCenter.iconFontFamily
                    }

                    Rectangle {
                        id: wifiSwitchTrack
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        width: 34
                        height: 20
                        radius: 10
                        color: controlCenter.wifiEnabled ? StyleTokens.success : StyleTokens.switchOff

                        Behavior on color {
                            ColorAnimation {
                                duration: StyleTokens.durationFast
                            }
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            y: 2
                            x: controlCenter.wifiEnabled ? 16 : 2
                            color: StyleTokens.white

                            Behavior on x {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            id: wifiToggleArea
                            anchors.fill: parent
                            enabled: controlCenter.wifiSupported && controlCenter.wifiAvailable && !controlCenter.wifiBusy
                            onClicked: controlCenter.toggleWifiEnabled()
                        }
                    }

                    Item {
                        id: wifiDetailButton
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 8
                        height: 30

                        Text {
                            anchors.left: parent.left
                            anchors.right: wifiChevron.left
                            anchors.rightMargin: 8
                            anchors.top: parent.top
                            text: "Wi-Fi"
                            color: controlCenter.textPrimary
                            font.pixelSize: 13
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: wifiChevron.left
                            anchors.rightMargin: 8
                            anchors.bottom: parent.bottom
                            text: controlCenter.wifiStatusText
                            color: StyleTokens.textMuted
                            font.pixelSize: 10
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            id: wifiChevron
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: controlCenter.wifiPanelOpen ? "#c7c9cf" : StyleTokens.textSubtle
                            font.pixelSize: 17
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: controlCenter.toggleConnectivityOverlay("wifi")
                        }
                    }
                }

                Rectangle {
                    id: bluetoothCard
                    width: (connectivityCardsRow.width - connectivityCardsRow.spacing) / 2
                    height: connectivityCardsRow.height
                    radius: 20
                    color: StyleTokens.clearBlack
                    clip: true

                    MatteSurface {
                        anchors.fill: parent
                        radius: parent.radius
                        hovered: bluetoothCardMouse.containsMouse || controlCenter.bluetoothPanelOpen
                    }

                    MouseArea {
                        id: bluetoothCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        text: controlCenter.bluetoothGlyph
                        color: controlCenter.bluetoothEnabled ? controlCenter.cardAccent : StyleTokens.textDisabled
                        font.pixelSize: 18
                        font.family: controlCenter.iconFontFamily
                    }

                    Rectangle {
                        id: bluetoothSwitchTrack
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        width: 34
                        height: 20
                        radius: 10
                        color: controlCenter.bluetoothEnabled ? StyleTokens.success : StyleTokens.switchOff

                        Behavior on color {
                            ColorAnimation {
                                duration: StyleTokens.durationFast
                            }
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            y: 2
                            x: controlCenter.bluetoothEnabled ? 16 : 2
                            color: StyleTokens.white

                            Behavior on x {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            id: bluetoothToggleArea
                            anchors.fill: parent
                            enabled: controlCenter.bluetoothAvailable && !controlCenter.bluetoothBusy
                            onClicked: controlCenter.toggleBluetoothEnabled()
                        }
                    }

                    Item {
                        id: bluetoothDetailButton
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 8
                        height: 30

                        Text {
                            anchors.left: parent.left
                            anchors.right: bluetoothChevron.left
                            anchors.rightMargin: 8
                            anchors.top: parent.top
                            text: "Bluetooth"
                            color: controlCenter.textPrimary
                            font.pixelSize: 13
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: bluetoothChevron.left
                            anchors.rightMargin: 8
                            anchors.bottom: parent.bottom
                            text: controlCenter.bluetoothStatusText
                            color: StyleTokens.textMuted
                            font.pixelSize: 10
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            id: bluetoothChevron
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: controlCenter.bluetoothPanelOpen ? "#c7c9cf" : StyleTokens.textSubtle
                            font.pixelSize: 17
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: controlCenter.toggleConnectivityOverlay("bluetooth")
                        }
                    }
                }
            }
        }

        Item {
            id: batteryDrawer
            readonly property real cardWidth: (width - connectivityCardsRow.spacing) / 2
            readonly property real modeSlotWidth: 44
            readonly property real openDistance: controlCenter.batteryModeCardHeight
                + controlCenter.batteryDrawerContentGap

            width: parent.width
            height: controlCenter.batteryDrawerHandleHeight
                + controlCenter.batteryDrawerProgress * openDistance
            clip: true

            Rectangle {
                id: batteryModeCard
                anchors.left: parent.left
                y: -height + controlCenter.batteryDrawerProgress * height
                width: batteryDrawer.cardWidth
                height: controlCenter.batteryModeCardHeight
                radius: 20
                color: StyleTokens.clearBlack
                visible: controlCenter.tlpControlsEnabled
                opacity: controlCenter.tlpControlsEnabled ? Math.min(1, controlCenter.batteryDrawerProgress * 1.35) : 0
                clip: true

                MatteSurface {
                    anchors.fill: parent
                    radius: parent.radius
                    hovered: controlCenter.batteryModeSliderDragging
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.top: parent.top
                    anchors.topMargin: 11
                    text: "Battery"
                    color: controlCenter.textPrimary
                    font.pixelSize: 13
                    font.family: controlCenter.textFontFamily
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    width: Math.max(0, parent.width - 88)
                    text: controlCenter.batteryModeError.length > 0
                        ? controlCenter.batteryModeError
                        : (controlCenter.batteryModeInfoMessage.length > 0
                            ? controlCenter.batteryModeInfoMessage
                            : controlCenter.batteryModeStatusText)
                    color: controlCenter.batteryModeError.length > 0 ? StyleTokens.error : StyleTokens.textMuted
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: 9
                    font.family: controlCenter.textFontFamily
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Item {
                    id: batteryModeCarousel
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    height: 34
                    clip: true

                    Item {
                        id: batteryModeItems
                        width: batteryDrawer.modeSlotWidth * 3
                        height: parent.height
                        x: batteryModeCarousel.width / 2
                            - batteryDrawer.modeSlotWidth / 2
                            - controlCenter.batteryModeIndex * batteryDrawer.modeSlotWidth
                            + controlCenter.batteryModeDragOffset

                        Behavior on x {
                            enabled: !controlCenter.batteryModeSliderDragging

                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        Repeater {
                            model: 3

                            delegate: Item {
                                x: index * batteryDrawer.modeSlotWidth
                                width: batteryDrawer.modeSlotWidth
                                height: batteryModeCarousel.height
                                opacity: index === controlCenter.batteryModeIndex ? 1 : 0.42

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: index === controlCenter.batteryModeIndex ? 32 : 28
                                    height: index === controlCenter.batteryModeIndex ? 28 : 24
                                    radius: 12
                                    color: index === controlCenter.batteryModeIndex ? StyleTokens.textPrimary : "#292a2f"

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 140
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 140
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 140
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: controlCenter.batteryModeGlyphs[index]
                                        color: index === controlCenter.batteryModeIndex ? StyleTokens.module : StyleTokens.textDim
                                        font.pixelSize: index === controlCenter.batteryModeIndex ? 15 : 13
                                        font.family: controlCenter.iconFontFamily
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 22
                        height: 2
                        radius: 1
                        color: "#5d6068"
                        opacity: 0.75
                    }

                    MouseArea {
                        anchors.fill: parent
                        property real startX: 0
                        property int startIndex: 1
                        property bool moved: false

                        function clampDrag(delta) {
                            return Math.max(-batteryDrawer.modeSlotWidth, Math.min(batteryDrawer.modeSlotWidth, delta));
                        }

                        onPressed: function(mouse) {
                            startX = mouse.x;
                            startIndex = controlCenter.batteryModeIndex;
                            moved = false;
                            controlCenter.batteryModeInfoMessage = "";
                            controlCenter.batteryModeError = "";
                            controlCenter.batteryModeSliderDragging = true;
                            controlCenter.batteryModeDragOffset = 0;
                        }

                        onPositionChanged: function(mouse) {
                            if (!pressed)
                                return;

                            const delta = mouse.x - startX;
                            if (!moved && Math.abs(delta) < 4)
                                return;

                            moved = true;
                            controlCenter.batteryModeDragOffset = clampDrag(delta);
                        }

                        onReleased: function(mouse) {
                            const delta = mouse.x - startX;
                            let nextIndex = startIndex;

                            if (delta <= -18)
                                nextIndex = Math.min(2, startIndex + 1);
                            else if (delta >= 18)
                                nextIndex = Math.max(0, startIndex - 1);
                            else if (mouse.x < width / 2 - batteryDrawer.modeSlotWidth / 2)
                                nextIndex = Math.max(0, startIndex - 1);
                            else if (mouse.x > width / 2 + batteryDrawer.modeSlotWidth / 2)
                                nextIndex = Math.min(2, startIndex + 1);

                            controlCenter.batteryModeSliderDragging = false;
                            controlCenter.batteryModeDragOffset = 0;
                            controlCenter.selectBatteryMode(nextIndex);
                        }

                        onCanceled: {
                            controlCenter.batteryModeSliderDragging = false;
                            controlCenter.batteryModeDragOffset = 0;
                            controlCenter.setBatteryModeVisualIndex(controlCenter.batteryModeAppliedIndex, true);
                        }
                    }
                }
            }

            Rectangle {
                id: quickTogglesCard
                x: controlCenter.tlpControlsEnabled ? batteryDrawer.cardWidth + connectivityCardsRow.spacing : 0
                y: batteryModeCard.y
                width: batteryDrawer.cardWidth
                height: controlCenter.batteryModeCardHeight
                radius: 20
                color: StyleTokens.clearBlack
                opacity: Math.min(1, controlCenter.batteryDrawerProgress * 1.35)
                clip: true
                readonly property real toggleIconTop: 12
                readonly property real toggleIconBoxHeight: 32
                readonly property real toggleLabelTop: 55

                Behavior on x {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                MatteSurface {
                    anchors.fill: parent
                    radius: parent.radius
                    hovered: focusButtonMouse.containsMouse || nightLightButtonMouse.containsMouse
                    pressed: focusButtonMouse.pressed || nightLightButtonMouse.pressed
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: parent.height - 34
                    radius: 1
                    color: "#1cffffff"
                }

                Item {
                    id: focusButton
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 2
                    property real slashProgress: controlCenter.focusEnabled ? 1 : 0
                    property color iconColor: controlCenter.focusEnabled ? StyleTokens.textPrimaryBright : "#c8cad1"

                    Behavior on slashProgress {
                        NumberAnimation {
                            duration: 830
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 16
                        color: focusButtonMouse.containsMouse ? "#08ffffff" : StyleTokens.clearBlack

                        Behavior on color {
                            ColorAnimation {
                                duration: StyleTokens.durationFast
                            }
                        }
                    }

                    MouseArea {
                        id: focusButtonMouse
                        anchors.fill: parent
                        enabled: !controlCenter.focusBusy
                        hoverEnabled: true
                        onClicked: controlCenter.toggleFocus()
                    }

                    Item {
                        id: focusIconSlot
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: quickTogglesCard.toggleIconTop
                        width: parent.width
                        height: quickTogglesCard.toggleIconBoxHeight

                        Shape {
                            id: focusIcon
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            scale: focusButtonMouse.pressed ? 0.94 : 1.0
                            opacity: controlCenter.focusBusy ? 0.5 : 1.0
                            preferredRendererType: Shape.CurveRenderer

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }

                            ShapePath {
                                fillColor: StyleTokens.transparent
                                strokeColor: focusButton.iconColor
                                strokeWidth: 2
                                capStyle: ShapePath.RoundCap
                                joinStyle: ShapePath.RoundJoin

                                PathSvg {
                                    path: "M22 17H2a3 3 0 0 0 3-3V9a7 7 0 0 1 14 0v5a3 3 0 0 0 3 3zm-8.27 4a2 2 0 0 1-3.46 0"
                                }
                            }

                            ShapePath {
                                fillColor: StyleTokens.transparent
                                strokeColor: focusButton.iconColor
                                strokeWidth: 2.1
                                capStyle: ShapePath.RoundCap
                                joinStyle: ShapePath.RoundJoin

                                PathMove {
                                    x: 1
                                    y: 1
                                }

                                PathLine {
                                    x: 1 + 22 * focusButton.slashProgress
                                    y: 1 + 22 * focusButton.slashProgress
                                }
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: quickTogglesCard.toggleLabelTop
                        width: parent.width
                        text: "Silent"
                        color: controlCenter.focusEnabled ? StyleTokens.textPrimaryBright : StyleTokens.textMuted
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 10
                        font.family: controlCenter.textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        opacity: controlCenter.focusBusy ? 0.5 : 1.0
                    }
                }

                Item {
                    id: nightLightButton
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 2

                    MouseArea {
                        id: nightLightButtonMouse
                        anchors.fill: parent
                        enabled: !controlCenter.nightLightBusy
                        hoverEnabled: true
                        onClicked: controlCenter.toggleNightLight()
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 16
                        color: nightLightButtonMouse.containsMouse ? "#08ffffff" : StyleTokens.clearBlack

                        Behavior on color {
                            ColorAnimation {
                                duration: StyleTokens.durationFast
                            }
                        }
                    }

                    Item {
                        id: nightLightIconSlot
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: quickTogglesCard.toggleIconTop
                        width: parent.width
                        height: quickTogglesCard.toggleIconBoxHeight

                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1
                            text: controlCenter.nightLightGlyph
                            color: "#45000000"
                            font.pixelSize: 29
                            font.family: controlCenter.iconFontFamily
                            scale: nightLightButtonMouse.pressed ? 0.94 : 1.0
                            opacity: controlCenter.nightLightBusy ? 0.1 : 0.22
                        }

                        Text {
                            id: nightLightIcon
                            anchors.centerIn: parent
                            text: controlCenter.nightLightGlyph
                            color: controlCenter.nightLightEnabled ? StyleTokens.textPrimaryBright : "#c8cad1"
                            font.pixelSize: 29
                            font.family: controlCenter.iconFontFamily
                            scale: nightLightButtonMouse.pressed ? 0.94 : 1.0
                            opacity: controlCenter.nightLightBusy ? 0.5 : 1.0

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: quickTogglesCard.toggleLabelTop
                        width: parent.width
                        text: "Night mode"
                        color: controlCenter.nightLightEnabled ? StyleTokens.textPrimaryBright : StyleTokens.textMuted
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 10
                        font.family: controlCenter.textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        opacity: controlCenter.nightLightBusy ? 0.5 : 1.0
                    }
                }
            }

            Rectangle {
                id: batteryDrawerTunnelShade
                anchors.left: parent.left
                anchors.top: parent.top
                width: batteryDrawer.cardWidth
                height: Math.max(1, controlCenter.batteryDrawerContentGap * 0.35)
                z: 6
                opacity: Math.min(0.34, controlCenter.batteryDrawerProgress * 0.45)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#9a000000"
                    }
                    GradientStop {
                        position: 1
                        color: StyleTokens.clearBlack
                    }
                }
            }

            Item {
                id: batteryDrawerHandle
                anchors.left: parent.left
                anchors.right: parent.right
                y: controlCenter.batteryDrawerProgress * batteryDrawer.openDistance
                height: controlCenter.batteryDrawerHandleHeight
                z: 10

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 8
                    width: 48
                    height: 5
                    radius: 3
                    color: controlCenter.batteryDrawerOpen ? "#d4d6dc" : StyleTokens.textSubtle
                    opacity: 0.88
                }

                MouseArea {
                    id: batteryDrawerHandleArea
                    anchors.fill: parent
                    property real pointerGrabOffset: 0
                    property bool moved: false
                    property bool suppressClick: false

                    function pointerY(mouse) {
                        return batteryDrawerHandle.mapToItem(controlCenter, mouse.x, mouse.y).y;
                    }

                    function itemTop(item) {
                        return item.mapToItem(controlCenter, 0, 0).y;
                    }

                    onPressed: function(mouse) {
                        controlCenter.stopBatteryDrawerSettle();
                        controlCenter.batteryDrawerSettling = false;
                        pointerGrabOffset = pointerY(mouse) - itemTop(batteryDrawerHandle);
                        moved = false;
                        suppressClick = false;
                        controlCenter.batteryDrawerDragging = true;
                    }

                    onPositionChanged: function(mouse) {
                        const nextHandleY = pointerY(mouse) - pointerGrabOffset - itemTop(batteryDrawer);
                        if (!moved && Math.abs(nextHandleY - batteryDrawerHandle.y) < 4)
                            return;

                        moved = true;
                        suppressClick = true;
                        controlCenter.batteryDrawerProgress = controlCenter.clamp01(nextHandleY / batteryDrawer.openDistance);
                    }

                    onReleased: {
                        controlCenter.batteryDrawerDragging = false;
                        if (moved)
                            controlCenter.setBatteryDrawerOpen(controlCenter.batteryDrawerProgress >= 0.55);
                    }

                    onCanceled: {
                        controlCenter.batteryDrawerDragging = false;
                        controlCenter.setBatteryDrawerOpen(controlCenter.batteryDrawerOpen);
                    }

                    onClicked: {
                        if (suppressClick) {
                            suppressClick = false;
                            return;
                        }

                        controlCenter.toggleBatteryDrawer();
                    }
                }
            }
        }

        ControlSliderCard {
            id: brightnessCard
            width: parent.width
            height: 76
            title: "Display"
            iconText: controlCenter.brightnessIconGlyph
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            value: controlCenter.displayedBrightness
            knobSize: controlCenter.sliderKnobSize
            moduleColor: controlCenter.moduleColor
            moduleHover: controlCenter.moduleHover
            trackColor: controlCenter.trackColor
            textPrimary: controlCenter.textPrimary
            textSecondary: controlCenter.textSecondary

            onInteractionStarted: {
                if (controlCenter.sliderIntroPending) {
                    sliderIntroTimer.stop();
                    controlCenter.sliderIntroPending = false;
                    controlCenter.displayedBrightness = controlCenter.localBrightness;
                    controlCenter.displayedVolume = controlCenter.localVolume;
                }
            }
            onValueMoved: function(value) {
                controlCenter.queueBrightness(value);
            }
            onCommitRequested: {
                brightnessApplyTimer.stop();
                controlCenter.flushBrightness(true);
            }
            onCancelRequested: SystemServices.requestBrightness()
        }

        ControlSliderCard {
            id: volumeCard
            width: parent.width
            height: 76
            title: "Sound"
            iconText: controlCenter.volumeIconGlyph
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            value: controlCenter.displayedVolume
            knobSize: controlCenter.sliderKnobSize
            moduleColor: controlCenter.moduleColor
            moduleHover: controlCenter.moduleHover
            trackColor: controlCenter.trackColor
            textPrimary: controlCenter.textPrimary
            textSecondary: controlCenter.textSecondary

            onInteractionStarted: {
                if (controlCenter.sliderIntroPending) {
                    sliderIntroTimer.stop();
                    controlCenter.sliderIntroPending = false;
                    controlCenter.displayedBrightness = controlCenter.localBrightness;
                    controlCenter.displayedVolume = controlCenter.localVolume;
                }
            }
            onValueMoved: function(value) {
                controlCenter.queueVolume(value);
            }
            onCommitRequested: {
                volumeApplyTimer.stop();
                controlCenter.flushVolume(true);
            }
            onCancelRequested: SystemServices.requestVolume()
        }
    }
