import QtQuick
import QtQuick.Effects
import Quickshell
import ".."

// Round avatar: the notification image, else the app icon, else a symbol from the shell, else the app's first letter.
Item {
    id: root

    property string image: ""
    property string appIcon: ""
    property string app: ""
    property string symbol: ""
    property int size: 36

    readonly property string source: {
        if (image !== "") return image;
        if (appIcon === "") return "";
        return appIcon.indexOf("/") >= 0 ? appIcon : Quickshell.iconPath(appIcon, true);
    }

    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.fill2
    }

    Text {
        anchors.centerIn: parent
        visible: !pic.visible && root.symbol === ""
        text: root.app !== "" ? root.app.charAt(0).toUpperCase() : "!"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: root.size * 0.4
        font.weight: Font.Medium
    }

    Icon {
        anchors.centerIn: parent
        visible: !pic.visible && root.symbol !== ""
        name: root.symbol
        size: root.size * 0.55
    }

    Image {
        id: pic

        anchors.fill: parent
        source: root.source
        sourceSize.width: 2 * root.size
        sourceSize.height: 2 * root.size
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    Rectangle {
        id: mask

        anchors.fill: parent
        radius: width / 2
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: pic
        maskEnabled: true
        maskSource: mask
        visible: pic.status === Image.Ready
    }
}
