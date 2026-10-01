import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Battery, volume and brightness state, setters for the last two, and a `changed` signal for the OSD.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    signal changed(string kind, real progress)

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryReady: !!battery && battery.ready
    readonly property int batteryCapacity: batteryReady ? Math.round(battery.percentage * 100) : -1
    readonly property bool isCharging: batteryReady
        && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged)

    property real currentVolume: -1
    property bool isMuted: false
    property real currentBrightness: -1

    property string lastChargeState: ""
    property string backlightDevice: ""
    property int backlightMax: 0

    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }

    function setVolume(value) {
        if (sink && sink.audio)
            sink.audio.volume = clamp01(value);
    }

    function setBrightness(value) {
        brightnessSet.command = ["brightnessctl", "s", Math.round(clamp01(value) * 100) + "%"];
        brightnessSet.running = true;
    }

    function syncVolume() {
        if (!sink || !sink.audio) {
            currentVolume = -1;
            return;
        }
        const volume = clamp01(sink.audio.volume);
        const muted = sink.audio.muted;
        const first = currentVolume < 0;
        const unchanged = !first && isMuted === muted && Math.abs(currentVolume - volume) <= 0.001;
        currentVolume = volume;
        isMuted = muted;
        if (!first && !unchanged)
            changed(muted ? "mute" : "volume", volume);
    }

    function syncBrightness() {
        if (!backlightFile.loaded || backlightMax <= 0)
            return;
        const raw = parseInt(backlightFile.text().trim());
        if (isNaN(raw))
            return;
        const value = clamp01(raw / backlightMax);
        const first = currentBrightness < 0;
        const unchanged = !first && Math.abs(currentBrightness - value) <= 0.001;
        currentBrightness = value;
        if (!first && !unchanged)
            changed("brightness", value);
    }

    onIsChargingChanged: {
        if (!batteryReady)
            return;
        const label = isCharging ? "charging" : "discharging";
        if (lastChargeState !== "" && lastChargeState !== label)
            changed(label, -1);
        lastChargeState = label;
    }

    Component.onCompleted: syncVolume()

    PwObjectTracker {
        objects: [root.sink]
    }

    Connections {
        target: root.sink ? root.sink.audio : null

        function onVolumeChanged() { root.syncVolume(); }
        function onMutedChanged() { root.syncVolume(); }
    }

    Process {
        id: brightnessSet
    }

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                if (name.length > 0)
                    root.backlightDevice = name;
            }
        }
    }

    FileView {
        path: root.backlightDevice ? "/sys/class/backlight/" + root.backlightDevice + "/max_brightness" : ""
        onTextChanged: {
            const value = parseInt(text().trim());
            root.backlightMax = isNaN(value) ? 0 : value;
            root.syncBrightness();
        }
    }

    FileView {
        id: backlightFile

        path: root.backlightDevice ? "/sys/class/backlight/" + root.backlightDevice + "/brightness" : ""
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.syncBrightness()
    }
}
