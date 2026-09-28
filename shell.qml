import QtQuick
import Quickshell
import "qml/common"
import "qml/island"
import "qml/weather"
import "qml/ipc"

Scope {
    id: shellRoot

    readonly property bool screenRecordingActive: SystemServices.screenRecordingActive
    property bool focusEnabled: false
    property bool nightLightEnabled: false
    property bool shuttingDown: false
    property bool islandAutoHideRuntimeEnabled: true

    WeatherService {
        id: globalWeatherService
    }
    readonly property var weatherService: globalWeatherService

    function forEachWindow(callback) {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window)
                callback(window);
        }
    }

    function showNotificationAll(appName, summary, body) {
        if (focusEnabled)
            return;

        shellRoot.forEachWindow((window) => {
            if (window && window.showNotification)
                window.showNotification(appName, summary, body);
        });
    }

    function anyOverviewOpen() {
        if (CompositorBackend.compositor === "niri")
            return false;

        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && window.overviewPhase !== "closed")
                return true;
        }

        return false;
    }

    function prepareOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.prepareOverview());
    }

    function cancelPreparedOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.cancelPreparedOverview());
    }

    function openOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.openOverview());
    }

    function closeOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.closeOverview());
    }

    function toggleOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        if (shellRoot.anyOverviewOpen())
            shellRoot.closeOverviewAll();
        else
            shellRoot.openOverviewAll();
    }

    function anyIslandShown() {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && window.autoHideTargetVisible)
                return true;
        }

        return false;
    }

    function showIslandAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.showIslandWindow)
                window.showIslandWindow();
        });
    }

    function hideIslandAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.hideIslandWindow)
                window.hideIslandWindow();
        });
    }

    function toggleIslandAll() {
        if (shellRoot.anyIslandShown())
            shellRoot.hideIslandAll();
        else
            shellRoot.showIslandAll();
    }

    function refreshIslandAutoHideAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.refreshAutoHideWindow)
                window.refreshAutoHideWindow();
        });
    }

    function refreshOverviewWallpaperCaches(wallpaperPath) {
        shellRoot.forEachWindow((window) => {
            if (window
                    && wallpaperPath !== undefined
                    && wallpaperPath !== null
                    && String(wallpaperPath) !== "") {
                window.wallpaperPickerActiveWallpaper = String(wallpaperPath);
            }
            if (window && window.prewarmWallpaperCache)
                window.prewarmWallpaperCache();
        });
    }

    function forFocusedWindow(callback) {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        let fallbackWindow = null;
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && !fallbackWindow)
                fallbackWindow = window;
            if (window && window.monitorFocused) {
                callback(window);
                return;
            }
        }

        if (fallbackWindow)
            callback(fallbackWindow);
    }

    OverviewIpc {
        shellRoot: shellRoot
    }

    IslandIpc {
        shellRoot: shellRoot
    }

    TideIpc {
        shellRoot: shellRoot
    }

    Component.onDestruction: {
        shuttingDown = true;
    }

    Component.onCompleted: {
        SystemServices.ensureUserConfigAvailable();
        SystemServices.requestScreenRecordingSnapshot();
    }

    Variants {
        id: panelVariants

        model: Quickshell.screens

        IslandWindow {
            required property var modelData

            screen: modelData
            shellRootController: shellRoot
        }
    }
}
