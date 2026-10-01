import QtQuick
import "../.."

ViewFrame {
    id: root

    readonly property var net: ctl ? ctl.net : null
    readonly property var agent: net ? net.agent : null
    readonly property bool prompting: !!agent && agent.promptKind !== ""
    readonly property bool needsInput: !!agent && (agent.promptKind === "passkey" || agent.promptKind === "pin")

    DetailHeader {
        width: parent.width
        ctl: root.ctl
        title: "Bluetooth"
        subtitle: root.net ? (root.net.bluetoothScanning ? "Scanning for devices" : root.net.bluetoothName) : ""
        checked: root.net && root.net.bluetoothEnabled
        onToggled: root.net.toggleBluetooth()
    }

    ListView {
        width: parent.width
        height: Math.min(contentHeight, 260)
        visible: root.net && root.net.bluetoothEnabled && count > 0 && !root.prompting
        clip: true
        spacing: 2
        interactive: contentHeight > height
        model: root.net ? root.net.bluetoothRows : []

        delegate: Item {
            id: row

            required property var modelData
            readonly property bool isHeader: modelData.kind === "header"
            readonly property var device: modelData.device

            width: ListView.view.width
            height: isHeader ? 26 : 52

            Text {
                visible: row.isHeader
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                text: row.isHeader ? row.modelData.text : ""
                color: Theme.faint
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }

            ListRow {
                visible: !row.isHeader
                anchors.fill: parent
                icon: "bt"
                title: row.device ? root.net.deviceName(row.device) : ""
                subtitle: row.device ? root.net.deviceSubtitle(row.device) : ""
                highlighted: row.modelData.section === "connected"
                busy: row.device ? root.net.deviceBusy(row.device) : false
                action: row.modelData.section === "connected" ? "Disconnect" : (row.modelData.section === "paired" ? "Connect" : "Pair")
                secondary: row.modelData.section === "paired" ? "Forget" : ""
                onActivated: root.net.pressDevice(row.device)
                onSecondaryActivated: root.net.forgetDevice(row.device)
            }
        }
    }

    Text {
        visible: root.net && !root.prompting && (!root.net.bluetoothEnabled || root.net.bluetoothRows.length === 0)
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: 20
        bottomPadding: 20
        text: !root.net || !root.net.bluetoothAdapter ? "No Bluetooth adapter" : (root.net.bluetoothEnabled ? "Searching for devices" : "Bluetooth is off")
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }

    Column {
        visible: root.prompting
        width: parent.width
        spacing: 10

        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: {
                if (!root.agent) return "";
                if (root.agent.promptKind === "confirm") return "Does this code match the one on the device?";
                if (root.agent.promptKind === "display") return "Enter this code on the device";
                return root.agent.promptKind === "pin" ? "Enter the PIN for the device" : "Enter the passkey shown on the device";
            }
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        Text {
            visible: root.agent && root.agent.promptCode !== ""
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.agent ? root.agent.promptCode : ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 32
            font.letterSpacing: 4
        }

        Rectangle {
            visible: root.needsInput
            width: parent.width
            height: 40
            radius: 14
            color: Theme.fill

            TextInput {
                id: field

                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                onAccepted: root.agent.answer(text)
                Keys.onEscapePressed: root.net.cancelPairing()
            }
        }

        Row {
            spacing: 8

            PillButton {
                visible: root.agent && root.agent.promptKind !== "display"
                primary: true
                text: root.needsInput ? "Pair" : "Confirm"
                onClicked: root.needsInput ? root.agent.answer(field.text) : root.agent.answer("yes")
            }

            PillButton {
                text: "Cancel"
                onClicked: root.net.cancelPairing()
            }
        }
    }

    onNeedsInputChanged: if (needsInput) {
        field.text = "";
        field.forceActiveFocus();
    }

    Text {
        visible: root.net && root.net.error !== ""
        width: parent.width
        wrapMode: Text.Wrap
        text: root.net ? root.net.error : ""
        color: Theme.danger
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }
}
