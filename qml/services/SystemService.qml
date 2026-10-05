import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Battery, volume, screen and keyboard brightness state, setters for the last three, and a `changed` signal for the OSD.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    signal changed(string kind, real progress)
    signal low(int percent)

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryReady: !!battery && battery.ready
    readonly property int batteryCapacity: batteryReady ? Math.round(battery.percentage * 100) : -1
    readonly property bool isCharging: batteryReady
        && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged)

    property real currentVolume: -1
    property bool isMuted: false
    property real currentBrightness: -1
    // -1 when there is no keyboard backlight.
    property real currentKeyboard: -1

    property string lastChargeState: ""
    // A draining battery warns once at each of these levels; charging arms them again.
    readonly property var lowLevels: [20, 10, 5]
    property int warnedAt: 101
    property string backlightDevice: ""
    property int backlightMax: 0
    property string keyboardDevice: ""
    property int keyboardMax: 0

    readonly property string batteryIcon: batteryIconFor(batteryCapacity, isCharging)
    readonly property string batteryTimeText: batteryReady ? formatDuration(isCharging ? battery.timeToFull : battery.timeToEmpty) : "-"
    readonly property string batteryRateText: batteryReady && battery.changeRate !== 0 ? Math.abs(battery.changeRate).toFixed(1) + "W" : "-"
    readonly property string batteryRateLabel: isCharging ? "Charging" : "Discharging"
    readonly property string batteryTimeLabel: isCharging ? "Time to full" : "Time left"

    function batteryIconFor(percent, charging) {
        if (percent < 0)
            return "battery_unknown";
        if (charging) {
            const steps = [[25, "20"], [40, "30"], [55, "50"], [70, "60"], [85, "80"], [95, "90"]];
            for (const step of steps) {
                if (percent < step[0])
                    return "battery_charging_" + step[1];
            }
            return "battery_charging_full";
        }
        const level = Math.min(7, Math.floor(percent / 12.5));
        return level === 7 ? "battery_full" : "battery_" + level + "_bar";
    }

    function formatDuration(seconds) {
        if (!seconds || seconds <= 0)
            return "-";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

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

    // Keyboard backlights have only a few steps, so this goes to the nearest one.
    function setKeyboardBrightness(value) {
        if (!keyboardDevice || keyboardMax <= 0)
            return;
        keyboardSet.command = ["brightnessctl", "-d", keyboardDevice, "s", String(Math.round(clamp01(value) * keyboardMax))];
        keyboardSet.running = true;
    }

    // Reads both backlights again; a change made by the hardware keys is not always seen.
    function refreshBacklights() {
        if (backlightDevice)
            backlightFile.reload();
        if (keyboardDevice)
            keyboardFile.reload();
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

    function syncKeyboard() {
        if (!keyboardFile.loaded || keyboardMax <= 0)
            return;
        const raw = parseInt(keyboardFile.text().trim());
        if (!isNaN(raw))
            currentKeyboard = clamp01(raw / keyboardMax);
    }

    // The warning level a battery at this percent has reached and not yet warned at, or -1.
    function lowLevelFor(percent, warnedAt) {
        const reached = lowLevels.filter((level) => percent <= level && level < warnedAt);
        return reached.length > 0 ? Math.min(...reached) : -1;
    }

    function checkLow() {
        if (!batteryReady)
            return;
        if (isCharging) {
            warnedAt = 101;
            return;
        }
        const level = lowLevelFor(batteryCapacity, warnedAt);
        if (level < 0)
            return;
        warnedAt = level;
        low(batteryCapacity);
    }

    onBatteryCapacityChanged: checkLow()

    onIsChargingChanged: {
        if (!batteryReady)
            return;
        const label = isCharging ? "charging" : "discharging";
        if (lastChargeState !== "" && lastChargeState !== label)
            changed(label, -1);
        lastChargeState = label;
        checkLow();
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

    Process {
        id: keyboardSet

        onExited: keyboardFile.reload()
    }

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/leds 2>/dev/null | grep -m1 kbd_backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                if (name.length > 0)
                    root.keyboardDevice = name;
            }
        }
    }

    FileView {
        path: root.keyboardDevice ? "/sys/class/leds/" + root.keyboardDevice + "/max_brightness" : ""
        onTextChanged: {
            const value = parseInt(text().trim());
            root.keyboardMax = isNaN(value) ? 0 : value;
            root.syncKeyboard();
        }
    }

    FileView {
        id: keyboardFile

        path: root.keyboardDevice ? "/sys/class/leds/" + root.keyboardDevice + "/brightness" : ""
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.syncKeyboard()
    }
}
