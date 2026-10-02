import QtQuick
import QtQuick.Effects
import ".."

// What is behind a locked screen: the wallpaper, blurred and dimmed. It is the hull colour until that loads, or when there is none.
Item {
    id: root

    property string wallpaper: ""

    Rectangle {
        anchors.fill: parent
        color: Theme.hull
    }

    Image {
        id: picture

        anchors.fill: parent
        visible: false
        source: root.wallpaper !== "" && root.width > 0 ? "file://" + root.wallpaper : ""
        // Shown blurred, so a quarter of the screen's width is all the detail it needs.
        sourceSize.width: Math.round(root.width / 4)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    MultiEffect {
        anchors.fill: parent
        source: picture
        opacity: picture.status === Image.Ready ? 1 : 0
        blurEnabled: true
        blur: 1
        blurMax: 48
        // Without this the blur fades to nothing along the screen's edges.
        autoPaddingEnabled: false

        Behavior on opacity {
            NumberAnimation { duration: Theme.fadeDuration }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.hull
        opacity: 0.45
    }
}
