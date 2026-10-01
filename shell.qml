import QtQuick
import Quickshell
import "qml"

// Entry point. UMBRA_DEV=1 offsets the pill down for testing, UMBRA_SCREEN=<output> pins it to one monitor.
Scope {
    id: shellRoot

    readonly property bool dev: Quickshell.env("UMBRA_DEV") === "1"
    readonly property string onlyScreen: Quickshell.env("UMBRA_SCREEN") || ""

    ClockService {
        id: clock

        clockFormat: Config.clockFormat
    }

    MprisService {
        id: mpris

        expanded: shellRoot.anyView("music")
    }

    SystemService {
        id: system
    }

    WeatherService {
        id: weather
    }

    NotificationService {
        id: center
    }

    QuickSettingsService {
        id: quick
    }

    ConnectivityService {
        id: net

        wifiOpen: shellRoot.anyView("wifi")
        bluetoothOpen: shellRoot.anyView("bt")
    }

    TimerService {
        id: countdown

        onFinished: center.post("Timer", "Timer finished", "")
    }

    readonly property var services: ({
        clock: clock, mpris: mpris, system: system, weather: weather,
        center: center, quick: quick, net: net, countdown: countdown
    })

    function controllers() {
        const list = [];
        for (const screen of variants.instances) {
            if (screen)
                list.push(screen.controller);
        }
        return list;
    }

    function anyView(name) {
        return controllers().some((ctl) => ctl.view === name);
    }

    function focusedController() {
        let fallback = null;
        for (const screen of variants.instances) {
            if (!screen)
                continue;
            if (!fallback)
                fallback = screen;
            if (screen.monitorFocused)
                return screen.controller;
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

    PillIpc {
        shellRoot: shellRoot
    }

    Variants {
        id: variants

        model: Quickshell.screens.filter((screen) => shellRoot.onlyScreen === "" || screen.name === shellRoot.onlyScreen)

        PillScreen {
            required property var modelData

            screen: modelData
            services: shellRoot.services
            dev: shellRoot.dev
        }
    }
}
