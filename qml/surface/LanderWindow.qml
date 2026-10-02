import QtQuick
import Quickshell
import ".."

// A lander on its screen: content given to this window is shown in the lander.
SurfaceWindow {
    id: win

    default property alias content: lander.content
    // The tallest the content gets, for content that changes height; 0 means it never does.
    property int maxContentHeight: 0
    // Room above the lander for its spring to overshoot into.
    readonly property int headroom: 24

    piece: "lander"
    shown: lander.shown
    anchors.bottom: true
    implicitWidth: Math.ceil(lander.width + 2 * Theme.fillet)
    implicitHeight: Math.ceil(Math.max(win.maxContentHeight, lander.contentHeight)) + win.headroom

    // Only the lander takes input; the rest of this window falls through to what is underneath.
    mask: Region {
        x: Math.floor(lander.x - lander.fillet)
        y: Math.floor(lander.y)
        width: Math.ceil(lander.width + 2 * lander.fillet)
        height: Math.ceil(lander.height)
    }

    Lander {
        id: lander

        open: win.open
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }
}
