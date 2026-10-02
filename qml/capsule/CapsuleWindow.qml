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
    WlrLayershell.namespace: "apollo-capsule"
    WlrLayershell.layer: ctl.view !== "rest" ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: ctl.wantsKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Only the capsule takes input; everything else in this window falls through to what is underneath.
    mask: Region {
        x: Math.floor(capsule.x - capsule.fillet)
        y: Math.floor(capsule.y)
        width: Math.ceil(capsule.width + 2 * capsule.fillet)
        height: Math.ceil(capsule.height)
    }

    CapsuleController {
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

    Capsule {
        id: capsule

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
            const system = win.services.system;
            const icons = { volume: "volume", mute: "mute", brightness: "sun" };
            if (icons[kind])
                ctl.osd(icons[kind], progress);
            else
                ctl.status(system.batteryIcon, (kind === "charging" ? "Charging" : "On battery") + " · " + system.batteryCapacity + "%");
        }
    }
}
