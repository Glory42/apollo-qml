import QtQuick
import ".."

// A lander on its screen: content given to this window is shown in the lander.
SurfaceWindow {
    id: win

    default property alias content: lander.content

    piece: "lander"
    shown: lander.shown

    Lander {
        id: lander

        open: win.open
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }
}
