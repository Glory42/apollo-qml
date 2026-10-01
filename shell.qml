import QtQuick
import Quickshell
import "qml/common"
import "qml/services"
import "qml/weather"
import "qml/surface"

// Entry point. SURFACE_DEV=1 offsets the surface down for testing, SURFACE_SCREEN=<output> pins it to one monitor.
Scope {
    id: shellRoot

    readonly property bool dev: Quickshell.env("SURFACE_DEV") === "1"
    readonly property string onlyScreen: Quickshell.env("SURFACE_SCREEN") || ""

    IslandClock {
        id: clock

        clockFormat: UserConfig.clockFormat
    }

    IslandMprisController {
        id: mpris

        expanded: shellRoot.anyView("music")
    }

    IslandSystemState {
        id: system
    }

    WeatherService {
        id: weather
    }

    NotificationCenter {
        id: center
    }

    QuickSettingsState {
        id: quick
    }

    ConnectivityState {
        id: net

        wifiOpen: shellRoot.anyView("wifi")
        bluetoothOpen: shellRoot.anyView("bt")
    }

    TimerState {
        id: countdown

        onFinished: center.post("Timer", "Timer finished", "")
    }

    readonly property var services: ({
        clock: clock, mpris: mpris, system: system, weather: weather,
        center: center, quick: quick, net: net, countdown: countdown
    })

    function controllers() {
        const list = [];
        for (const window of variants.instances) {
            if (window)
                list.push(window.controller);
        }
        return list;
    }

    function anyView(name) {
        return controllers().some((ctl) => ctl.view === name);
    }

    function focusedController() {
        let fallback = null;
        for (const window of variants.instances) {
            if (!window)
                continue;
            if (!fallback)
                fallback = window;
            if (window.monitorFocused)
                return window.controller;
        }
        return fallback ? fallback.controller : null;
    }

    function show(view, toggle) {
        const target = focusedController();
        for (const ctl of controllers()) {
            if (ctl !== target)
                ctl.close();
        }
        if (!target)
            return;
        if (toggle)
            target.toggle(view);
        else
            target.open(view);
    }

    function closeAll() {
        for (const ctl of controllers())
            ctl.close();
    }

    SurfaceIpc {
        shellRoot: shellRoot
    }

    Variants {
        id: variants

        model: Quickshell.screens.filter((screen) => shellRoot.onlyScreen === "" || screen.name === shellRoot.onlyScreen)

        SurfaceWindow {
            required property var modelData

            screen: modelData
            services: shellRoot.services
            dev: shellRoot.dev
        }
    }
}
