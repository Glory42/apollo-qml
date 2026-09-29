import QtQuick
import "../common"

// Power-profile / TLP state/actions; ControlCenterLayer.qml extends this (which extends ConnectivityController), so everything here is accessible as controlCenter.*.
ConnectivityController {
    id: root

    property bool batteryModeBusy: false
    property bool batteryModeStateRunning: false
    property bool batteryModeSetterRunning: false
    property bool batteryModeSliderDragging: false
    property bool batteryTlpAvailable: false
    property bool batteryTlpChecked: false
    property int batteryModeIndex: 1
    property int batteryModeAppliedIndex: 1
    property int batteryModePendingIndex: 1
    property real batteryModeDragOffset: 0
    property string batteryModeInfoMessage: ""
    property string batteryModeError: ""
    property string batteryModeLastCommandOutput: ""
    property int batteryModeRefreshPollsRemaining: 0
    readonly property var batteryModeGlyphs: ["", "", ""]
    readonly property real batteryModeCardHeight: 80
    readonly property string batteryModeStatusText: buildBatteryModeStatusText()
    readonly property string powerDriver: {
        const d = trimString(userConfig.powerProfileDriver);
        return d.length > 0 ? d : "auto";
    }
    readonly property bool tlpControlsEnabled: {
        if (powerDriver === "disabled" || powerDriver === "none") return false;
        if (powerDriver === "powerprofilesctl") return true;
        if (powerDriver === "tlp") return trimString(userConfig.tlpPermissionMode) !== "skip";
        return true;
    }
    function batteryModeLabel(index) {
        if (index <= 0) return "Power Saver";
        if (index >= 2) return "Performance";
        return "Balanced";
    }

    function batteryModeCommand(index) {
        if (index <= 0) return "power-saver";
        if (index >= 2) return "performance";
        return "balanced";
    }

    function batteryModeIndexForCommand(command) {
        const normalized = trimString(command).toLowerCase();
        if (normalized === "power-saver" || normalized === "bat") return 0;
        if (normalized === "performance" || normalized === "ac") return 2;
        return 1;
    }

    function setBatteryModeVisualIndex(index, animate) {
        const nextIndex = Math.max(0, Math.min(2, index));
        batteryModeIndex = nextIndex;
    }

    function refreshBatteryModeState() {
        if (batteryModeStateRunning)
            return;

        batteryModeStateRunning = true;
        SystemServices.requestPowerProfileState(powerDriver);
    }

    function applyBatteryModeState(available, profile, output, errorString) {
        batteryModeStateRunning = false;
        batteryTlpChecked = true;
        batteryTlpAvailable = !!available;

        if (!batteryTlpAvailable) {
            batteryModeBusy = false;
            batteryModeError = trimString(errorString).length > 0 ? errorString : "Power service not available.";
            setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
            return;
        }

        if (batteryModeError === "TLP is not installed." || batteryModeError === "Power service not available.")
            batteryModeError = "";

        let resolvedProfile = trimString(profile);
        if (resolvedProfile.length === 0) {
            const profileMatch = String(output || "").match(/TLP profile\s*=\s*([a-z-]+)/i);
            if (profileMatch)
                resolvedProfile = profileMatch[1];
        }

        if (resolvedProfile.length > 0) {
            const nextIndex = batteryModeIndexForCommand(resolvedProfile);
            batteryModeAppliedIndex = nextIndex;
            setBatteryModeVisualIndex(nextIndex, true);

            if (batteryModeRefreshPollsRemaining > 0 && nextIndex === batteryModePendingIndex) {
                batteryModeRefreshPollsRemaining = 0;
                batteryModeRefreshTimer.stop();
                batteryModeError = "";
                batteryModeInfoMessage = batteryModeLabel(nextIndex) + " active.";
            }
        }
    }

    function buildBatteryModeStatusText() {
        if (batteryModeBusy) return "Applying " + batteryModeLabel(batteryModePendingIndex);
        if (!tlpControlsEnabled) return "Power disabled";
        if (!batteryTlpChecked) return "Checking power...";
        if (!batteryTlpAvailable) return "Service not found";
        return batteryModeLabel(batteryModeIndex);
    }

    function rollbackBatteryMode(message) {
        batteryModeBusy = false;
        batteryModeError = message;
        batteryModeInfoMessage = "";
        batteryModeDragOffset = 0;
        setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
    }

    function classifyBatteryModeFailure(exitCode) {
        const details = trimString(batteryModeLastCommandOutput).toLowerCase();

        if (details.indexOf("powerprofilesctl") >= 0)
            return "powerprofilesctl failed to set profile.";
        if (details.indexOf("sorry, try again") >= 0 || details.indexOf("incorrect password attempt") >= 0)
            return "The configured sudo password did not work.";
        if (details.indexOf("pkexec") >= 0 && details.indexOf("not installed") >= 0)
            return "Install pkexec or set tlpSudoPassword in userconfig.json.";
        if (details.indexOf("sudo is not installed") >= 0)
            return "sudo is not installed.";
        if (details.indexOf("sudo:") >= 0 && details.indexOf("password") >= 0) {
            if (trimString(userConfig.tlpPermissionMode) === "ask")
                return "Install pkexec or set tlpSudoPassword in userconfig.json.";
            return "sudo needs a password; set tlpSudoPassword in userconfig.json.";
        }
        if (details.indexOf("sudo:") >= 0 && details.indexOf("no new privileges") >= 0)
            return "sudo is blocked by the current process security flags.";
        if (details.indexOf("sudo:") >= 0 && details.indexOf("a terminal is required") >= 0)
            return "sudo needs a real terminal, but the panel could not open one.";
        if (details.indexOf("missing root privilege") >= 0)
            return "Power service needs admin permission.";
        if (details.indexOf("command not found") >= 0 || details.indexOf("not found") >= 0) {
            if (details.indexOf("tlp") >= 0)
                return "TLP is not installed.";
            if (details.indexOf("powerprofilesctl") >= 0)
                return "powerprofilesctl is not installed.";
        }

        if (exitCode === 127)
            return "Power service command not found.";
        if (exitCode === 126)
            return "Authentication required to apply mode.";
        return "Could not apply power mode.";
    }

    function queueBatteryModeStateRefresh(polls) {
        batteryModeRefreshPollsRemaining = Math.max(0, polls);
        if (batteryModeRefreshPollsRemaining > 0)
            batteryModeRefreshTimer.restart();
        else
            batteryModeRefreshTimer.stop();
    }

    function selectBatteryMode(index) {
        if (batteryModeBusy) {
            if (batteryModeSetterRunning)
                SystemServices.cancelPowerProfileApply();
            batteryModeBusy = false;
            batteryModeSetterRunning = false;
        }

        queueBatteryModeStateRefresh(0);

        const nextIndex = Math.max(0, Math.min(2, index));

        if (!tlpControlsEnabled) {
            rollbackBatteryMode("Power mode switching is disabled in userconfig.json.");
            return;
        }

        if (!batteryTlpChecked) {
            refreshBatteryModeState();
            rollbackBatteryMode("Checking power service. Try again in a moment.");
            return;
        }

        if (!batteryTlpAvailable) {
            rollbackBatteryMode(batteryModeError.length > 0 ? batteryModeError : "Power service not available.");
            return;
        }

        if (nextIndex === batteryModeAppliedIndex) {
            batteryModeError = "";
            batteryModeInfoMessage = batteryModeLabel(nextIndex) + " active.";
            setBatteryModeVisualIndex(nextIndex, true);
            return;
        }

        batteryModePendingIndex = nextIndex;
        batteryModeBusy = true;
        batteryModeSetterRunning = true;
        batteryModeError = "";
        batteryModeInfoMessage = "Applying " + batteryModeLabel(nextIndex) + "...";
        setBatteryModeVisualIndex(nextIndex, true);
        batteryModeLastCommandOutput = "";
        const permissionMode = trimString(userConfig.tlpPermissionMode);
        const sudoPassword = permissionMode === "password"
            ? trimString(userConfig.tlpSudoPassword)
            : "";
        SystemServices.setPowerProfileMode(powerDriver, batteryModeCommand(nextIndex), sudoPassword, permissionMode === "ask");
    }

    function finishBatteryModeApply(success, exitCode, output, errorString) {
        batteryModeSetterRunning = false;
        batteryModeBusy = false;
        batteryModeLastCommandOutput = trimString(output);
        if (batteryModeLastCommandOutput.length === 0)
            batteryModeLastCommandOutput = trimString(errorString);

        if (!success) {
            rollbackBatteryMode(classifyBatteryModeFailure(exitCode));
            return;
        }

        batteryModeAppliedIndex = batteryModePendingIndex;
        batteryModeError = "";
        batteryModeInfoMessage = batteryModeLabel(batteryModeAppliedIndex) + " active.";
        setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
        refreshBatteryModeState();
    }

    Connections {
        target: SystemServices

        function onTlpStateReady(available, profile, output, errorString) {
            applyBatteryModeState(available, profile, output, errorString);
        }

        function onTlpSetFinished(success, exitCode, output, errorString) {
            finishBatteryModeApply(success, exitCode, output, errorString);
        }

    }

    Timer {
        id: batteryModeRefreshTimer
        interval: 1500
        repeat: true
        onTriggered: {
            if (batteryModeRefreshPollsRemaining <= 0) {
                stop();
                return;
            }

            batteryModeRefreshPollsRemaining -= 1;
            refreshBatteryModeState();

            if (batteryModeRefreshPollsRemaining <= 0)
                stop();
        }
    }
}
