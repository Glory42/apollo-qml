import QtQuick
import QtQuick.Effects
import Quickshell
import ".."

// Round avatar: the notification image, else the app icon, else the app's first letter.
Item {
    id: root

    property string image: ""
    property string appIcon: ""
    property string app: ""
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
        visible: !pic.visible
        text: root.app !== "" ? root.app.charAt(0).toUpperCase() : "!"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: root.size * 0.4
        font.weight: Font.Medium
    }

    Image {
        id: pic

        anchors.fill: parent
        source: root.source
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
