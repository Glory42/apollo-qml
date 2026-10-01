import QtQuick
import ".."

ViewFrame {
    id: root

    readonly property var net: ctl ? ctl.net : null
    readonly property bool prompting: !!net && net.pendingSsid !== ""

    DetailHeader {
        width: parent.width
        ctl: root.ctl
        title: "Wi-Fi"
        subtitle: root.net ? root.net.wifiName : ""
        checked: root.net && root.net.wifiEnabled
        onToggled: root.net.toggleWifi()
    }

    ListView {
        width: parent.width
        height: Math.min(contentHeight, 260)
        visible: root.net && root.net.wifiEnabled && count > 0 && !root.prompting
        clip: true
        spacing: 2
        interactive: contentHeight > height
        model: root.net ? root.net.wifiNetworks : []

        delegate: ListRow {
            required property var modelData

            width: ListView.view.width
            icon: "wifi"
            iconOpacity: 0.35 + 0.65 * (modelData.signalStrength || 0)
            title: modelData.name
            subtitle: root.net.wifiConnecting(modelData) ? "Connecting" : (modelData.connected ? "Connected" : (modelData.known ? "Saved" : (root.net.isSecure(modelData) ? "Secured" : "Open")))
            highlighted: modelData.connected
            busy: root.net.wifiConnecting(modelData)
            action: modelData.connected ? "Disconnect" : ""
            secondary: modelData.known && !modelData.connected ? "Forget" : ""
            onActivated: modelData.connected ? root.net.disconnectWifi(modelData) : root.net.connectWifi(modelData)
            onSecondaryActivated: root.net.forgetWifi(modelData)
        }
    }

    Text {
        visible: root.net && (!root.net.wifiEnabled || (root.net.wifiNetworks.length === 0 && !root.prompting))
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: 20
        bottomPadding: 20
        text: root.net && root.net.wifiEnabled ? "Searching for networks" : "Wi-Fi is off"
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
            text: root.net ? "Password for " + root.net.pendingSsid : ""
            elide: Text.ElideRight
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        Rectangle {
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
                echoMode: TextInput.Password
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                onAccepted: root.net.submitWifiPassword(text)
                Keys.onEscapePressed: root.net.pendingSsid = ""
            }
        }

        Row {
            spacing: 8

            PillButton {
                primary: true
                text: "Join"
                onClicked: root.net.submitWifiPassword(field.text)
            }

            PillButton {
                text: "Cancel"
                onClicked: root.net.pendingSsid = ""
            }
        }
    }

    onPromptingChanged: if (prompting) {
        field.text = "";
        field.forceActiveFocus();
    }

    Text {
        visible: root.net && root.net.error === "" && root.net.message !== ""
        width: parent.width
        text: root.net ? root.net.message : ""
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 11
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
