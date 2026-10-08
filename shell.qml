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

        onLow: (percent) => center.post("Battery", "Battery low", percent + "% left", true)
    }

    WeatherService {
        id: weather

        online: !!net.wifiNetwork || (!!net.wiredDevice && net.wiredDevice.connected)
    }

    NotificationService {
        id: center

        onFocusModeChanged: shellRoot.announce("bell", focusMode ? "Notifications silenced" : "Notifications on")
    }

    // The night light schedule is checked on the clock's minute rather than on a timer of its own.
    Connections {
        target: clock

        function onCurrentTimeChanged() { quick.checkSchedule(); }
    }

    QuickSettingsService {
        id: quick

        onNightLightSet: (on) => shellRoot.announce("moon", on ? "Night light on" : "Night light off")
    }

    ConnectivityService {
        id: net

        wifiOpen: shellRoot.anyView("wifi")
        bluetoothOpen: shellRoot.anyView("bt")

        onWifiNameChanged: shellRoot.linkChanged("wifi", "Wi-Fi", wifiName)
        onBluetoothNameChanged: shellRoot.linkChanged("bt", "Bluetooth", bluetoothName)
    }

    // The names of what Wi-Fi and Bluetooth were last connected to, for saying what dropped.
    property var linked: ({})

    // Connectivity settles for a moment after the shell starts; what it finds then is not news.
    Timer {
        id: settling

        interval: 5000
        running: true
    }

    SoundService {
        id: sound

        watching: shellRoot.anyView("sound")
        onMicMuted: (muted) => shellRoot.announce(muted ? "mic_off" : "mic", muted ? "Microphone muted" : "Microphone on")
    }

    readonly property var services: ({
        clock: clock, mpris: mpris, system: system, weather: weather,
        center: center, quick: quick, net: net, sound: sound, recorder: recorder
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

    // A few words on every monitor's capsule, for something that changed without a view being open.
    function announce(icon, text, color) {
        for (const ctl of controllers())
            ctl.status(icon, text, color);
    }

    // `state` is a network or device name while connected, otherwise "Off", "On", "Not connected" or "No adapter".
    function linkChanged(icon, label, state) {
        const idle = ["Off", "On", "Not connected", "No adapter"];
        const before = shellRoot.linked[icon] || "";
        shellRoot.linked[icon] = idle.indexOf(state) < 0 ? state : "";
        if (settling.running)
            return;
        if (idle.indexOf(state) < 0)
            announce(icon, "Connected to " + state);
        else if (state === "Off")
            announce(icon, label + " off");
        else if (before !== "")
            announce(icon, before + " disconnected");
        else if (state === "On")
            announce(icon, label + " on");
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
        if (piece !== hasselblad)
            hasselblad.close();
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
        onSuspendRequested: idle.suspend()
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

        onUnavailable: (summary, body) => center.post("Logbook", summary, body)
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

    RecorderService {
        id: recorder

        onSaved: (file) => hasselblad.recordingSaved(file)
        onFailed: (message) => center.post("Hasselblad", "Recording failed", message)
    }

    Hasselblad {
        id: hasselblad

        recorder: recorder
        onlyScreen: shellRoot.onlyScreen
        onOpened: shellRoot.only(hasselblad)
        onAnnounce: (icon, text, color) => shellRoot.announce(icon, text, color)
        onFailed: (message) => center.post("Hasselblad", message, "")
    }

    HasselbladIpc {
        hasselblad: hasselblad
    }

    IdleService {
        id: idle

        active: !shellRoot.dev
        locked: airlock.isLocked
        secure: airlock.isSecure
        onLockRequested: airlock.lock()
        onSleptUnsecured: center.post("Airlock", "Screen did not lock before suspend", "The session may have slept unlocked.", true)
        onStayAwakeChanged: shellRoot.announce("sun", stayAwake ? "Staying awake" : "Idle on")
    }

    SwitchesIpc {
        quick: quick
        center: center
        idle: idle
    }

    Airlock {
        id: airlock

        services: shellRoot.services
        wallpaper: themes.wallpaper !== "" ? themes.wallpaper : (themes.currentTheme ? themes.currentTheme.wallpapers[0] || "" : "")
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
