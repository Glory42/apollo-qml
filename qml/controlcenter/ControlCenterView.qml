import QtQuick
import "../common"
import "../weather"

    Column {
        id: mainContent

        property var controlCenter: null

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
            width: parent.width
            height: 80

            Rectangle {
                id: actionsCard
                anchors.fill: parent
                radius: 20
                color: StyleTokens.clearBlack
                clip: true
                readonly property real toggleIconTop: 12
                readonly property real toggleIconBoxHeight: 32
                readonly property real toggleLabelTop: 55

                MatteSurface {
                    anchors.fill: parent
                    radius: parent.radius
                    hovered: wallpaperButtonMouse.containsMouse || powerButtonMouse.containsMouse
                    pressed: wallpaperButtonMouse.pressed || powerButtonMouse.pressed
                }

                Rectangle {
                    x: parent.width / 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: parent.height - 34
                    radius: 1
                    color: "#1cffffff"
                }

                Rectangle {
                    x: parent.width * 2 / 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: parent.height - 34
                    radius: 1
                    color: "#1cffffff"
                }

                Item {
                    id: themeButton
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 3

                    Item {
                        id: themeIconSlot
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: actionsCard.toggleIconTop
                        width: parent.width
                        height: actionsCard.toggleIconBoxHeight

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: StyleTokens.textDisabled
                            font.pixelSize: 18
                            font.family: controlCenter.iconFontFamily
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: actionsCard.toggleLabelTop
                        width: parent.width
                        text: "Theme"
                        color: StyleTokens.textDisabled
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 10
                        font.family: controlCenter.textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }

                Item {
                    id: wallpaperButton
                    x: parent.width / 3
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 3

                    MouseArea {
                        id: wallpaperButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: controlCenter.wallpaperRequested()
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 16
                        color: wallpaperButtonMouse.containsMouse ? "#08ffffff" : StyleTokens.clearBlack

                        Behavior on color {
                            ColorAnimation {
                                duration: StyleTokens.durationFast
                            }
                        }
                    }

                    Item {
                        id: wallpaperIconSlot
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: actionsCard.toggleIconTop
                        width: parent.width
                        height: actionsCard.toggleIconBoxHeight

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: StyleTokens.textPrimaryBright
                            font.pixelSize: 18
                            font.family: controlCenter.iconFontFamily
                            scale: wallpaperButtonMouse.pressed ? 0.94 : 1.0

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
                        y: actionsCard.toggleLabelTop
                        width: parent.width
                        text: "Wallpaper"
                        color: StyleTokens.textMuted
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 10
                        font.family: controlCenter.textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }

                Item {
                    id: powerButton
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 3

                    MouseArea {
                        id: powerButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: controlCenter.powerViewActive = true
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 16
                        color: powerButtonMouse.containsMouse ? "#08ffffff" : StyleTokens.clearBlack

                        Behavior on color {
                            ColorAnimation {
                                duration: StyleTokens.durationFast
                            }
                        }
                    }

                    Item {
                        id: powerIconSlot
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: actionsCard.toggleIconTop
                        width: parent.width
                        height: actionsCard.toggleIconBoxHeight

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: StyleTokens.textPrimaryBright
                            font.pixelSize: 18
                            font.family: controlCenter.iconFontFamily
                            scale: powerButtonMouse.pressed ? 0.94 : 1.0

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
                        y: actionsCard.toggleLabelTop
                        width: parent.width
                        text: "Power"
                        color: StyleTokens.textMuted
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 10
                        font.family: controlCenter.textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Item {
            id: batteryDrawer
            readonly property real modeSlotWidth: 44

            visible: controlCenter.tlpControlsEnabled
            width: parent.width
            height: controlCenter.tlpControlsEnabled ? controlCenter.batteryModeCardHeight : 0

            Rectangle {
                id: batteryModeCard
                anchors.fill: parent
                radius: 20
                color: StyleTokens.clearBlack
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
        }

    }
