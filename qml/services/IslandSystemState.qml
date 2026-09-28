import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "../common"

Item {
    id: root

    visible: false
    width: 0
    height: 0

    signal transientRequested(string icon, real progress, string text)

    property var configuredLeftSwipeItems: []
    property string timeText: "00:00"
    property string dateText: "Mon, Jan 01"
    property string currentTrack: ""
    property string currentArtUrl: ""
    property int currentWorkspace: 1
    property bool customSwipeActive: false
    property bool lyricsCavaActive: false
    property var weatherService: null

    readonly property var customLeftItems: []
    readonly property bool hasCustomLeftItems: false
    readonly property var cavaLevels: [0, 0, 0, 0, 0, 0, 0, 0]
    readonly property real currentCpuUsage: -1
    readonly property real currentRamUsage: -1

    readonly property string volumeStatusIcon: "\u{F057E}"
    readonly property string muteStatusIcon: "\u{F075F}"
    readonly property string brightnessLowStatusIcon: "\u{F00DE}"
    readonly property string brightnessMediumStatusIcon: "\u{F00DF}"
    readonly property string brightnessHighStatusIcon: "\u{F00E0}"
    readonly property string chargingStatusIcon: ""
    readonly property string dischargingStatusIcon: ""

    readonly property var _sink: Pipewire.defaultAudioSink
    readonly property var _batteryDevice: UPower.displayDevice
    readonly property bool _batteryReady: !!_batteryDevice && _batteryDevice.ready

    readonly property int batteryCapacity: _batteryReady ? Math.round(_batteryDevice.percentage * 100) : -1
    readonly property bool isCharging: _batteryReady
        && (_batteryDevice.state === UPowerDeviceState.Charging || _batteryDevice.state === UPowerDeviceState.FullyCharged)
    property real currentVolume: -1
    property bool isMuted: false
    property real currentBrightness: -1

    property string _lastChargeState: ""
    property string _pendingVolType: ""
    property real _pendingVolVal: 0.0
    property string _lastVolType: ""
    property real _lastVolVal: -1.0
    property real _pendingBrightnessValue: 0.0
    property string _backlightDevice: ""
    property int _backlightMax: 0

    function refreshMissingValues() {}

    function statusIcon(name) {
        switch (name) {
        case "volume":
            return volumeStatusIcon;
        case "mute":
            return muteStatusIcon;
        case "brightnessLow":
            return brightnessLowStatusIcon;
        case "brightnessMedium":
            return brightnessMediumStatusIcon;
        case "brightnessHigh":
            return brightnessHighStatusIcon;
        case "charging":
            return chargingStatusIcon;
        case "discharging":
            return dischargingStatusIcon;
        default:
            return "";
        }
    }

    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }

    function brightnessStatusIcon(value) {
        if (value < 0.3) return statusIcon("brightnessLow");
        if (value < 0.7) return statusIcon("brightnessMedium");
        return statusIcon("brightnessHigh");
    }

    onIsChargingChanged: {
        if (!root._batteryReady) return;
        const stateLabel = root.isCharging ? "Charging" : "Discharging";
        if (root._lastChargeState !== "" && root._lastChargeState !== stateLabel)
            root.transientRequested(root.statusIcon(root.isCharging ? "charging" : "discharging"), -1.0, "");
        root._lastChargeState = stateLabel;
    }

    function _syncVolume() {
        if (!root._sink || !root._sink.audio) {
            root.currentVolume = -1;
            return;
        }

        const volume = root._sink.audio.volume;
        const muted = root._sink.audio.muted;
        const nextVolType = muted ? "MUTE" : "VOL";
        const nextVolValue = root.clamp01(volume);
        const unchanged = root.isMuted === muted
            && Math.abs(root.currentVolume - nextVolValue) <= 0.001
            && root._pendingVolType === nextVolType
            && Math.abs(root._pendingVolVal - nextVolValue) <= 0.001;

        root.currentVolume = nextVolValue;
        root.isMuted = muted;
        if (unchanged) return;

        root._pendingVolType = nextVolType;
        root._pendingVolVal = nextVolValue;
        volumeDebounce.restart();
    }

    function _syncBrightness() {
        if (!backlightFile.loaded || root._backlightMax <= 0) return;
        const raw = parseInt(backlightFile.text().trim());
        if (isNaN(raw)) return;

        const value = root.clamp01(raw / root._backlightMax);
        const changed = root.currentBrightness < 0 || Math.abs(root.currentBrightness - value) > 0.001;
        root.currentBrightness = value;
        if (!changed) return;

        root._pendingBrightnessValue = value;
        brightnessDebounce.restart();
    }

    Component.onCompleted: {
        _syncVolume();
    }

    Connections {
        target: root._sink ? root._sink.audio : null
        function onVolumeChanged() { root._syncVolume(); }
        function onMutedChanged() { root._syncVolume(); }
    }

    Timer {
        id: volumeDebounce
        interval: 16
        onTriggered: {
            if (root._pendingVolType !== root._lastVolType
                    || Math.abs(root._pendingVolVal - root._lastVolVal) > 0.001) {
                root._lastVolType = root._pendingVolType;
                root._lastVolVal = root._pendingVolVal;
                root.transientRequested(
                    root._pendingVolType === "MUTE" ? root.statusIcon("mute") : root.statusIcon("volume"),
                    root._pendingVolVal,
                    ""
                );
            }
        }
    }

    Timer {
        id: brightnessDebounce
        interval: 16
        onTriggered: root.transientRequested(
            root.brightnessStatusIcon(root._pendingBrightnessValue),
            root._pendingBrightnessValue,
            ""
        )
    }

    Process {
        id: backlightDeviceProcess
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                if (name.length > 0)
                    root._backlightDevice = name;
            }
        }
    }

    FileView {
        id: backlightMaxFile
        path: root._backlightDevice ? ("/sys/class/backlight/" + root._backlightDevice + "/max_brightness") : ""
        onTextChanged: {
            const value = parseInt(text().trim());
            root._backlightMax = isNaN(value) ? 0 : value;
            root._syncBrightness();
        }
    }

    FileView {
        id: backlightFile
        path: root._backlightDevice ? ("/sys/class/backlight/" + root._backlightDevice + "/brightness") : ""
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root._syncBrightness()
    }
}
