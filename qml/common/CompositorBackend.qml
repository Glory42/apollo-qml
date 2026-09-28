pragma Singleton

import Quickshell.Hyprland
import QtQuick

QtObject {
    readonly property string compositor: "hyprland"
    readonly property int revision: 0

    function isOutputFocused(outputName) {
        return Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === outputName;
    }

    function activeWorkspaceIndexForOutput(outputName) {
        const monitors = Hyprland.monitors.values;
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name === outputName && monitors[i].activeWorkspace)
                return monitors[i].activeWorkspace.id;
        }
        return 1;
    }
}
