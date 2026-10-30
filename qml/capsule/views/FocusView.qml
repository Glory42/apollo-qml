import QtQuick
import "../.."

// What may interrupt: focus itself in the header, then staying awake, track peeks, the microphone and the touchpad.
ViewFrame {
    id: root

    readonly property var center: ctl ? ctl.center : null
    readonly property var idle: ctl ? ctl.idle : null
    readonly property var sound: ctl ? ctl.sound : null
    readonly property var quick: ctl ? ctl.quick : null
    readonly property var mic: sound && sound.source ? sound.source.audio : null
    readonly property bool focusMode: !!root.center && root.center.focusMode

    spacing: 10

    DetailHeader {
        width: parent.width
        ctl: root.ctl
        title: "Focus"
        subtitle: root.focusMode ? "Alerts silenced" : "Alerts on"
        checked: root.focusMode
        onToggled: root.center.focusMode = !root.center.focusMode
    }

    Column {
        width: parent.width

        SwitchRow {
            icon: "visibility"
            title: "Stay awake"
            subtitle: "No screen off, lock or sleep"
            checked: !!root.idle && root.idle.stayAwake
            onToggled: root.idle.stayAwake = !root.idle.stayAwake
        }

        SwitchRow {
            icon: "music"
            title: "Track pop-ups"
            subtitle: "A peek when a song starts or changes"
            checked: !!root.center && root.center.trackPeeks
            onToggled: root.center.setTrackPeeks(!root.center.trackPeeks)
        }

        SwitchRow {
            visible: !!root.mic
            icon: root.mic && root.mic.muted ? "mic_off" : "mic"
            title: "Microphone muted"
            subtitle: root.sound && root.sound.source ? (root.sound.source.description || root.sound.source.name) : ""
            checked: !!root.mic && root.mic.muted
            onToggled: root.sound.toggleMute(root.sound.source)
        }

        SwitchRow {
            icon: root.quick && root.quick.touchpadOff ? "touchpad_off" : "touchpad"
            title: "Touchpad off"
            subtitle: "The F6 key flips it too"
            checked: !!root.quick && root.quick.touchpadOff
            onToggled: root.quick.toggleTouchpad()
        }
    }
}
