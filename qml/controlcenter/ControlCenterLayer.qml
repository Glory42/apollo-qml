import QtQuick
import QtQuick.Shapes
import "../common"
import "../weather"

PowerActionsController {
    id: controlCenter

    signal connectivityPanelRequested(string kind, bool open)
    signal focusModeChanged(bool enabled)
    signal weatherRequested()
    signal calendarRequested()
    signal wallpaperRequested()

    readonly property var userConfig: UserConfig

    property var weatherService: null
    property bool showCondition: false
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    // ... rest of properties ...

    scale: showCondition ? 1.0 : 0.12
    transformOrigin: Item.Top

    Behavior on scale {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuint
        }
    }
    property string currentTime: "00:00"
    property string currentDateLabel: ""
    property int batteryCapacity: 0
    property bool isCharging: false
    property int currentWorkspace: 1
    property string currentTrack: ""
    property string currentArtist: ""

    property bool wifiPanelOpen: false
    property bool bluetoothPanelOpen: false
    property bool powerPanelOpen: false
    property bool powerViewActive: false
    property bool focusEnabled: false
    property bool focusBusy: false

    readonly property color panelColor: StyleTokens.panel
    readonly property color moduleColor: StyleTokens.module
    readonly property color moduleHover: StyleTokens.moduleHover
    readonly property color trackColor: StyleTokens.track
    readonly property color textPrimary: StyleTokens.textPrimary
    readonly property color textSecondary: StyleTokens.textSecondary
    readonly property color cardAccent: StyleTokens.accent
    readonly property color cardAccentPressed: StyleTokens.accentPressed
    readonly property color cardFillActive: StyleTokens.cardFillActive
    readonly property color cardFillHover: StyleTokens.cardFillHover
    readonly property color buttonFill: StyleTokens.buttonFill
    readonly property color buttonFillHover: StyleTokens.buttonFillHover
    readonly property color buttonFillPressed: StyleTokens.buttonFillPressed
    readonly property string chargingIconGlyph: "\uf0e7"
    readonly property real roundToggleButtonSize: 58
    readonly property real roundToggleButtonGap: 18
    readonly property real controlCenterExtraHeight: tlpControlsEnabled ? (12 + batteryModeCardHeight) : 0
    readonly property real controlCenterMaximumExtraHeight: controlCenterExtraHeight
    readonly property bool hasConnectivityPrompt: wifiPendingPasswordSsid.length > 0 || bluetoothPairingActive
    readonly property bool anyConnectivityPanelOpen: wifiPanelOpen || bluetoothPanelOpen

    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }

    function trimString(value) {
        if (value === undefined || value === null) return "";
        return String(value).trim();
    }

    function toggleFocus() {
        focusEnabled = !focusEnabled;
        focusModeChanged(focusEnabled);
    }

    function isConnectivityPanelOpen(kind) {
        if (kind === "wifi") return wifiPanelOpen;
        if (kind === "bluetooth") return bluetoothPanelOpen;
        if (kind === "power") return powerPanelOpen;
        return false;
    }

    function setConnectivityPanelOpen(kind, open, emitSignal) {
        if (emitSignal === undefined)
            emitSignal = true;

        const nextOpen = !!open;
        let changed = false;

        if (kind === "wifi") {
            changed = wifiPanelOpen !== nextOpen;
            wifiPanelOpen = nextOpen;

            if (nextOpen) {
                if (showCondition) {
                    requestWifiStateRefresh();
                    if (wifiSupported && wifiEnabled)
                        requestWifiListRefresh(true);
                }
            } else {
                clearWifiPrompt();
                clearWifiMessages();
            }
        } else if (kind === "bluetooth") {
            changed = bluetoothPanelOpen !== nextOpen;
            bluetoothPanelOpen = nextOpen;

            if (nextOpen)
                startBluetoothScanForPanel();
            else
                stopBluetoothActivityForPanelClose();
        }
        else if (kind === "power") {
            changed = powerPanelOpen !== nextOpen;
            powerPanelOpen = nextOpen;
        }
        else {
            return;
        }

        if (changed && emitSignal)
            connectivityPanelRequested(kind, nextOpen);
    }

    function toggleConnectivityOverlay(kind) {
        setConnectivityPanelOpen(kind, !isConnectivityPanelOpen(kind));
    }

    function closeConnectivityPanels(emitSignals) {
        if (emitSignals === undefined)
            emitSignals = true;

        setConnectivityPanelOpen("wifi", false, emitSignals);
        setConnectivityPanelOpen("bluetooth", false, emitSignals);
        clearWifiPrompt();
        clearWifiMessages();
        clearBluetoothMessages();
    }

    anchors.fill: parent
    anchors.margins: 12
    opacity: showCondition ? 1 : 0
    visible: opacity > 0

    onShowConditionChanged: {
        if (showCondition) {
            refreshBatteryModeState();
            requestWifiStateRefresh();
            if (wifiPanelOpen && wifiSupported && wifiEnabled)
                requestWifiListRefresh(true);
        } else {
            closeConnectivityPanels();
        }
    }

    Component.onCompleted: {
        refreshBatteryModeState();
    }

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 240 : 100
            easing.type: Easing.InOutQuad
        }
    }

    ControlCenterView {
        id: controlCenterView
        controlCenter: controlCenter
    }

    PowerMenuView {
        controlCenter: controlCenter
    }
}
