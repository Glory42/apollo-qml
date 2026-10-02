import QtQuick
import Quickshell
import "qml"

// Entry point. APOLLO_DEV=1 offsets the capsule down for testing, APOLLO_SCREEN=<output> pins it to one monitor.
Scope {
    id: shellRoot

    readonly property bool dev: Quickshell.env("APOLLO_DEV") === "1"
    readonly property string onlyScreen: Quickshell.env("APOLLO_SCREEN") || ""

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

    function step(delta) {
        const target = focusedController();
        for (const ctl of controllers()) {
            if (ctl !== target)
                ctl.close();
        }
        if (target)
            target.step(delta);
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

    // One piece is open at a time, so whichever opens closes the rest (null is the capsule); peeks are left alone.
    function only(piece) {
        if (piece !== splashdown)
            splashdown.close();
        if (piece !== launchpad)
            launchpad.close();
        if (piece !== logbook)
            logbook.close();
        if (piece !== earthrise)
            earthrise.close();
        if (piece !== visor)
            visor.close();
        if (!piece)
            return;
        for (const ctl of controllers()) {
            if (ctl.isOpen)
                ctl.close();
        }
    }

    CapsuleIpc {
        shellRoot: shellRoot
    }

    Splashdown {
        id: splashdown

        onlyScreen: shellRoot.onlyScreen
        onOpened: shellRoot.only(splashdown)
        onLockRequested: airlock.lock()
    }

    SplashdownIpc {
        splashdown: splashdown
    }

    Launchpad {
        id: launchpad

        onlyScreen: shellRoot.onlyScreen
        onOpened: shellRoot.only(launchpad)
    }

    LaunchpadIpc {
        launchpad: launchpad
    }

    ClipboardService {
        id: clipboard
    }

    Logbook {
        id: logbook

        clipboard: clipboard
        onlyScreen: shellRoot.onlyScreen
        onOpened: shellRoot.only(logbook)
    }

    LogbookIpc {
        logbook: logbook
    }

    ThemeService {
        id: themes
    }

    Earthrise {
        id: earthrise

        themes: themes
        onlyScreen: shellRoot.onlyScreen
        onOpened: shellRoot.only(earthrise)
    }

    EarthriseIpc {
        earthrise: earthrise
    }

    Visor {
        id: visor

        themes: themes
        onlyScreen: shellRoot.onlyScreen
        onOpened: shellRoot.only(visor)
    }

    VisorIpc {
        visor: visor
    }

    Airlock {
        id: airlock

        services: shellRoot.services
        onOpened: shellRoot.only(airlock)
    }

    AirlockIpc {
        airlock: airlock
    }

    Variants {
        id: variants

        model: Quickshell.screens.filter((screen) => shellRoot.onlyScreen === "" || screen.name === shellRoot.onlyScreen)

        CapsuleScreen {
            required property var modelData

            screen: modelData
            services: shellRoot.services
            dev: shellRoot.dev
            onOpened: shellRoot.only(null)
        }
    }
}
