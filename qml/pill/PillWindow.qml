import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

PanelWindow {
    id: win

    property var services: null
    property bool dev: false

    readonly property alias controller: ctl
    readonly property bool monitorFocused: !!ctl.monitor && !!Hyprland.focusedMonitor && ctl.monitor.name === Hyprland.focusedMonitor.name

    color: "transparent"
    anchors.top: true
    margins.top: win.dev ? 60 : 0
    implicitWidth: Theme.windowWidth
    implicitHeight: Theme.windowHeight
    exclusiveZone: win.dev ? 0 : Theme.topMargin + Theme.restHeight + Config.windowGap
    WlrLayershell.namespace: "apollo-pill"
    WlrLayershell.layer: ctl.view !== "rest" ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: ctl.wantsKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Only the pill takes input; everything else in this window falls through to what is underneath.
    mask: Region {
        x: Math.floor(pill.x - pill.fillet)
        y: Math.floor(pill.y)
        width: Math.ceil(pill.width + 2 * pill.fillet)
        height: Math.ceil(pill.height)
    }

    PillController {
        id: ctl

        screen: win.screen
        clock: win.services ? win.services.clock : null
        mpris: win.services ? win.services.mpris : null
        system: win.services ? win.services.system : null
        weather: win.services ? win.services.weather : null
        center: win.services ? win.services.center : null
        quick: win.services ? win.services.quick : null
        net: win.services ? win.services.net : null
        countdown: win.services ? win.services.countdown : null
    }

    Pill {
        id: pill

        ctl: ctl
        x: Math.round((win.width - width) / 2)
        y: Theme.topMargin
    }

    // Every monitor shows every event.
    Connections {
        target: win.services ? win.services.center : null

        function onReceived(app, summary, body, icon, image, critical, timeout) {
            ctl.notify(app, summary, body, icon, image, critical, timeout);
        }
    }

    Connections {
        target: win.services ? win.services.mpris : null

        function onNowPlaying(title, artist, artUrl) {
            if (Config.mediaPeek)
                ctl.media(title, artist, artUrl);
        }
    }

    Connections {
        target: win.services ? win.services.system : null

        function onChanged(kind, progress) {
            const icons = { volume: "volume", mute: "mute", brightness: "sun" };
            ctl.osd(icons[kind] || win.services.system.batteryIcon, progress);
        }
    }
}
