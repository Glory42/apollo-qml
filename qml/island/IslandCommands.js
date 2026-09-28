.pragma library

// Shared toggle/close for panels whose two call sites behave identically; controlCenter and expandedPlayer are excluded since each has a real behavioral difference between call sites (see README).

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
