.pragma library

// Shared "toggle a simple panel" shape used by both the IPC wrapper functions
// (IslandWindow.qml's root, called from shell.qml's IpcHandlers) and
// handleConfiguredClickAction() (islandContainer's click-action switch).
// Only covers panels where both call sites behave identically: state === key
// closes it via smartRestoreState(), anything else opens it via showFn().
//
// Deliberately NOT covering every panel here:
// - controlCenter's root-level toggleControlCenterWindow() also resets
//   controlCenterLoader.item.powerViewActive on open; its click-action
//   counterpart does not. That's a real, pre-existing behavioral difference
//   between the two call sites, not incidental duplication -- unifying it
//   would silently change one of them.
// - expandedPlayer's click-action path also calls autoHideTimer.stop()
//   before closing; its root-level counterpart does not. Same reasoning.
// Both stay hand-written at their call sites so those differences stay
// intentional and visible instead of being flattened into "one true toggle".

var PANEL_STATES = {
    controlCenter: "control_center",
    notificationCenter: "notification_center",
    wallpaperPicker: "wallpaper_picker",
    weather: "weather",
    calendar: "calendar"
};

function isOpen(container, key) {
    return container.islandState === PANEL_STATES[key];
}

function toggle(container, key, showFn) {
    if (isOpen(container, key))
        container.smartRestoreState();
    else
        showFn();
}

function close(container, key) {
    if (isOpen(container, key))
        container.smartRestoreState();
}
