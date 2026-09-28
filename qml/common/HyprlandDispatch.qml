pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

QtObject {
    id: root

    function luaString(value) {
        const text = String(value === undefined || value === null ? "" : value);
        return "\"" + text
            .replace(/\\/g, "\\\\")
            .replace(/"/g, "\\\"")
            .replace(/\n/g, "\\n")
            .replace(/\r/g, "\\r")
            .replace(/\t/g, "\\t") + "\"";
    }

    function workspaceExpression(value) {
        if (typeof value === "number" && isFinite(value))
            return String(Math.trunc(value));

        const text = String(value === undefined || value === null ? "" : value).trim();
        if (/^[1-9][0-9]*$/.test(text))
            return text;

        return luaString(text);
    }

    function dispatchExpression(expression) {
        const text = String(expression === undefined || expression === null ? "" : expression).trim();
        if (text === "")
            return false;

        Hyprland.dispatch(text);
        return true;
    }

    function focusWorkspace(workspace) {
        return dispatchExpression("hl.dsp.focus({ workspace = " + workspaceExpression(workspace) + " })");
    }
}
