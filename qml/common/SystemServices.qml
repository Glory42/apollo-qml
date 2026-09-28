pragma Singleton

import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

QtObject {
    id: root

    readonly property bool screenRecordingActive: false

    signal tlpStateReady(bool available, string profile, string output, string errorString)
    signal tlpSetFinished(bool success, int exitCode, string output, string errorString)
    signal brightnessSnapshotReady(real value, string errorString)
    signal brightnessSetFinished(real value, bool success, string errorString)
    signal volumeSnapshotReady(real value, bool muted, string errorString)
    signal volumeSetFinished(real value, bool success, string errorString)

    function ensureUserConfigAvailable() {}
    function requestScreenRecordingSnapshot() {}

    property Process _powerProfileListProcess: Process {
        command: ["powerprofilesctl", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                let active = "";
                let found = false;
                for (let i = 0; i < lines.length; i++) {
                    const m = lines[i].match(/^\s*(\*)?\s*([a-zA-Z0-9-]+):\s*$/);
                    if (m) {
                        found = true;
                        if (m[1]) active = m[2];
                    }
                }
                if (found)
                    root.tlpStateReady(true, active, text, "");
                else
                    root.tlpStateReady(false, "", text, "powerprofilesctl is not available.");
            }
        }
    }

    function requestPowerProfileState(driver) {
        if (_powerProfileListProcess.running) return;
        _powerProfileListProcess.running = true;
    }

    property Process _powerProfileSetProcess: Process {
        property string pendingMode: ""
        command: ["powerprofilesctl", "set", pendingMode]
        onExited: exitCode => {
            root.tlpSetFinished(exitCode === 0, exitCode, "", exitCode === 0 ? "" : "powerprofilesctl set failed.");
        }
    }

    function setPowerProfileMode(driver, mode, sudoPassword, promptForPassword) {
        _powerProfileSetProcess.pendingMode = mode;
        _powerProfileSetProcess.running = true;
    }

    function cancelPowerProfileApply() {
        if (_powerProfileSetProcess.running)
            _powerProfileSetProcess.running = false;
    }

    property PwNode _sink: Pipewire.defaultAudioSink

    property PwObjectTracker _sinkBinder: PwObjectTracker {
        objects: [root._sink]
    }

    property Connections _sinkTracker: Connections {
        target: root._sink ? root._sink.audio : null
        function onVolumeChanged() {
            Qt.callLater(() => root.volumeSnapshotReady(root._sink.audio.volume, root._sink.audio.muted, ""));
        }
        function onMutedChanged() {
            Qt.callLater(() => root.volumeSnapshotReady(root._sink.audio.volume, root._sink.audio.muted, ""));
        }
    }

    function requestVolume() {
        if (root._sink && root._sink.audio) {
            const value = root._sink.audio.volume;
            const muted = root._sink.audio.muted;
            Qt.callLater(() => root.volumeSnapshotReady(value, muted, ""));
        } else {
            Qt.callLater(() => root.volumeSnapshotReady(0, false, "No audio sink available."));
        }
    }

    function setVolume(value) {
        if (root._sink && root._sink.audio) {
            root._sink.audio.volume = value;
            Qt.callLater(() => root.volumeSetFinished(value, true, ""));
        } else {
            Qt.callLater(() => root.volumeSetFinished(value, false, "No audio sink available."));
        }
    }

    property Process _brightnessGetProcess: Process {
        command: ["sh", "-c", "brightnessctl g && brightnessctl m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 2) {
                    const value = Math.max(0, Math.min(1, parseInt(lines[0]) / parseInt(lines[1])));
                    root.brightnessSnapshotReady(value, "");
                } else {
                    root.brightnessSnapshotReady(0, "Could not read brightness.");
                }
            }
        }
    }

    function requestBrightness() {
        _brightnessGetProcess.running = true;
    }

    property Process _brightnessSetProcess: Process {
        property real pendingValue: 0
        command: ["brightnessctl", "s", Math.round(pendingValue * 100) + "%"]
        onExited: exitCode => {
            root.brightnessSetFinished(pendingValue, exitCode === 0, exitCode === 0 ? "" : "brightnessctl failed.");
        }
    }

    function setBrightness(value) {
        _brightnessSetProcess.pendingValue = value;
        _brightnessSetProcess.running = true;
    }
}
