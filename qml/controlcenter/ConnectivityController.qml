import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import "../common/BluetoothFormatting.js" as BluetoothFormatting

// Wifi + Bluetooth state and actions, factored out of ControlCenterLayer.qml.
// ControlCenterLayer.qml's root object extends this type (via QML component
// inheritance), so everything declared here is directly accessible as
// controlCenter.* -- this is what lets the ConnectivityDetailPanel family's
// "provider" contract (40+ wifi/bluetooth members) keep working unchanged
// even though the implementation now lives in a separate file.
Item {
    id: root

    property string wifiLocalInfoMessage: ""
    property string wifiLocalError: ""
    property string wifiPendingPasswordSsid: ""
    property string wifiPendingPasswordValue: ""

    property string bluetoothInfoMessage: ""
    property string bluetoothError: ""
    property string bluetoothPairAndConnectPath: ""
    property string bluetoothPendingSecretValue: ""
    readonly property var wifiDevice: {
        const devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi) return devs[i];
        return null;
    }
    readonly property var wifiNetworks: wifiDevice ? [...wifiDevice.networks.values] : []
    readonly property string wifiGlyph: ""
    readonly property string bluetoothGlyph: ""
    readonly property bool bluetoothAvailable: !!bluetoothAdapter
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var bluetoothDeviceValues: bluetoothAdapter ? bluetoothAdapter.devices.values : []
    readonly property bool wifiSupported: true
    readonly property bool wifiReadOnly: false
    readonly property bool wifiAvailable: wifiDevice !== null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiBusy: false
    readonly property bool wifiListRunning: wifiDevice ? wifiDevice.scannerEnabled : false
    readonly property string wifiCurrentSsid: {
        if (!wifiDevice) return "";
        const nets = wifiDevice.networks.values;
        for (let i = 0; i < nets.length; i++)
            if (nets[i].connected) return nets[i].name;
        return "";
    }
    readonly property string wifiInfoMessage: wifiLocalInfoMessage
    readonly property string wifiError: wifiLocalError
    readonly property string wifiUnsupportedReason: ""
    readonly property string wifiAvailabilityMessage: {
        if (wifiSupported && !wifiAvailable) return "No Wi-Fi device is available.";
        return "";
    }
    readonly property bool bluetoothEnabled: bluetoothAdapter ? bluetoothAdapter.enabled : false
    readonly property bool bluetoothBusy: bluetoothAdapter
        ? bluetoothAdapter.state === BluetoothAdapterState.Enabling
            || bluetoothAdapter.state === BluetoothAdapterState.Disabling
        : false
    readonly property bool bluetoothPairingActive: false
    readonly property bool bluetoothPairingRequiresInput: false
    readonly property bool bluetoothPairingNumericInput: false
    readonly property bool bluetoothPairingRequiresConfirmation: false
    readonly property string bluetoothPairingTitle: ""
    readonly property string bluetoothPairingMessage: ""
    readonly property string bluetoothPairingDisplayedCode: ""
    readonly property string wifiStatusText: {
        if (!wifiAvailable) return "Unavailable";
        if (!wifiEnabled) return "Off";
        return wifiCurrentSsid.length > 0 ? wifiCurrentSsid : "Not Connected";
    }
    readonly property string bluetoothStatusText: buildBluetoothStatusText()
    readonly property string bluetoothAvailabilityMessage: bluetoothAvailable ? "" : "No Bluetooth adapter is available."
    function clearWifiPrompt() {
        wifiPendingPasswordSsid = "";
        wifiPendingPasswordValue = "";
        wifiLocalInfoMessage = "";
        wifiLocalError = "";
    }

    function clearWifiMessages() {
        wifiLocalInfoMessage = "";
        wifiLocalError = "";
    }

    function clearBluetoothMessages() {
        bluetoothInfoMessage = "";
        bluetoothError = "";
    }

    function submitBluetoothPairingSecret() {
        bluetoothPendingSecretValue = "";
    }

    function confirmBluetoothPairing() {
        bluetoothError = "";
    }

    function cancelBluetoothPairing() {
        bluetoothPendingSecretValue = "";
    }

    function findWifiNetworkBySsid(ssid) {
        if (!wifiDevice) return null;
        const nets = wifiDevice.networks.values;
        for (let i = 0; i < nets.length; i++)
            if (nets[i].name === ssid) return nets[i];
        return null;
    }

    function requestWifiStateRefresh() {
    }

    function requestWifiListRefresh(rescan) {
        if (!showCondition || !wifiDevice) return;
        if (!wifiSupported || !wifiAvailable || !wifiEnabled) return;
        if (rescan) wifiDevice.scannerEnabled = true;
    }

    function toggleWifiEnabled() {
        clearWifiPrompt();
        clearWifiMessages();
        Networking.wifiEnabled = !wifiEnabled;
    }

    function disconnectWifi() {
        if (!wifiSupported || !wifiAvailable) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "No Wi-Fi device is available.";
            return;
        }

        clearWifiPrompt();
        clearWifiMessages();
        const ssid = wifiCurrentSsid;
        const network = ssid ? findWifiNetworkBySsid(ssid) : null;
        if (network) network.disconnect();
    }

    function wifiNetworkIsSecure(network) {
        return !!network && network.security !== WifiSecurityType.Open;
    }

    function wifiNetworkIsWep(network) {
        return !!network
            && (network.security === WifiSecurityType.StaticWep || network.security === WifiSecurityType.DynamicWep);
    }

    function wifiNetworkIsEnterprise(network) {
        return !!network
            && (network.security === WifiSecurityType.Wpa2Eap
                || network.security === WifiSecurityType.WpaEap
                || network.security === WifiSecurityType.Wpa3SuiteB192
                || network.security === WifiSecurityType.Leap);
    }

    function wifiNetworkSignalPercent(network) {
        return network ? Math.round((network.signalStrength || 0) * 100) : 0;
    }

    function connectWifiNetwork(network) {
        if (!network) return;
        if (!wifiSupported) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "Wi-Fi control is unavailable.";
            return;
        }
        if (!wifiAvailable) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "No Wi-Fi device is available.";
            return;
        }
        if (!wifiEnabled) {
            wifiLocalError = "Turn on Wi-Fi first.";
            return;
        }
        if (network.connected) return;

        const ssid = trimString(network.name);
        const known = !!network.known;

        if (!ssid) {
            wifiLocalError = "Hidden networks are not supported in this panel yet.";
            return;
        }

        if (!known && wifiNetworkIsWep(network)) {
            wifiLocalError = "WEP networks aren't supported by this panel.";
            return;
        }

        if (!known && wifiNetworkIsEnterprise(network)) {
            wifiLocalError = "802.1X networks need to be provisioned first.";
            return;
        }

        clearWifiPrompt();
        clearWifiMessages();

        if (known) {
            network.connect();
            return;
        }

        if (!wifiNetworkIsSecure(network)) {
            network.connect();
            return;
        }

        wifiPendingPasswordSsid = ssid;
        wifiPendingPasswordValue = "";
        wifiLocalInfoMessage = "Enter the password for " + ssid + ".";
    }

    function submitWifiPassword() {
        const ssid = trimString(wifiPendingPasswordSsid);
        if (!ssid) return;

        if (trimString(wifiPendingPasswordValue).length === 0) {
            wifiLocalError = "Enter a password first.";
            return;
        }

        const password = wifiPendingPasswordValue;
        clearWifiPrompt();
        clearWifiMessages();
        const network = findWifiNetworkBySsid(ssid);
        if (network) network.connectWithPsk(password);
    }
    function bluetoothDeviceName(device) {
        if (!device) return "Unknown device";
        return BluetoothFormatting.displayName(
            device.name,
            device.deviceName,
            device.address,
            device.icon
        );
    }

    function bluetoothDeviceHasFriendlyName(device) {
        if (!device) return false;
        return BluetoothFormatting.friendlyName(
            device.name,
            device.deviceName,
            device.address
        ).length > 0;
    }

    function bluetoothDeviceAddress(device) {
        return device ? BluetoothFormatting.addressLabel(device.address) : "";
    }

    function bluetoothDeviceStateText(device) {
        if (!device) return "";
        if (device.pairing) return "Pairing";

        switch (device.state) {
        case BluetoothDeviceState.Connecting:
            return "Connecting";
        case BluetoothDeviceState.Connected:
            return "Connected";
        case BluetoothDeviceState.Disconnecting:
            return "Disconnecting";
        default:
            break;
        }

        if (device.paired || device.bonded) return "Paired";
        return "Available";
    }

    function bluetoothDeviceSubtitle(device) {
        const parts = [];
        const stateLabel = bluetoothDeviceStateText(device);
        if (stateLabel.length > 0) parts.push(stateLabel);
        if (device && device.batteryAvailable) parts.push(bluetoothBatteryPercent(device) + "%");
        if (device && !bluetoothDeviceHasFriendlyName(device)) {
            const address = bluetoothDeviceAddress(device);
            if (address.length > 0) parts.push(address);
        }
        return parts.join(" • ");
    }

    function bluetoothBatteryPercent(device) {
        if (!device || !device.batteryAvailable)
            return -1;

        const rawValue = Math.max(0, Number(device.battery) || 0);
        return Math.max(0, Math.min(100, Math.round(rawValue <= 1 ? rawValue * 100 : rawValue)));
    }

    function bluetoothDeviceMatchesSection(device, section) {
        if (!device) return false;

        const paired = device.paired || device.bonded;
        if (section === "connected") return device.connected;
        if (section === "paired") return !device.connected && paired;
        if (section === "available") return !paired;
        return false;
    }

    function buildBluetoothStatusText() {
        if (!bluetoothAvailable) return "Unavailable";
        if (!bluetoothEnabled) return "Off";

        const devices = bluetoothDeviceValues || [];
        const connectedNames = [];

        for (let index = 0; index < devices.length; index++) {
            const device = devices[index];
            if (device && device.connected)
                connectedNames.push(bluetoothDeviceName(device));
        }

        if (connectedNames.length === 1) return connectedNames[0];
        if (connectedNames.length > 1) return connectedNames[0] + " +" + (connectedNames.length - 1);
        if (bluetoothAdapter.discovering) return "Scanning";
        return bluetoothBusy ? "Working..." : "On";
    }

    function toggleBluetoothEnabled() {
        if (!bluetoothAdapter) {
            bluetoothError = "No Bluetooth adapter is available.";
            return;
        }

        bluetoothError = "";
        bluetoothInfoMessage = "";
        bluetoothPairAndConnectPath = "";

        if (bluetoothAdapter.discovering)
            bluetoothAdapter.discovering = false;

        bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
    }

    function toggleBluetoothScan() {
        if (!bluetoothAdapter) {
            bluetoothError = "No Bluetooth adapter is available.";
            return;
        }
        if (!bluetoothEnabled) {
            bluetoothError = "Turn on Bluetooth first.";
            return;
        }

        bluetoothError = "";
        if (bluetoothAdapter.discovering) {
            bluetoothAdapter.discovering = false;
            bluetoothInfoMessage = "";
            bluetoothScanStopTimer.stop();
        } else {
            bluetoothAdapter.discovering = true;
            bluetoothInfoMessage = "Scanning for nearby devices...";
            bluetoothScanStopTimer.restart();
        }
    }

    function handleBluetoothDevicePressed(device) {
        if (!device) return;
        if (!bluetoothAdapter || !bluetoothEnabled) {
            bluetoothError = "Turn on Bluetooth first.";
            return;
        }

        bluetoothError = "";

        if (device.connected) {
            bluetoothInfoMessage = "Disconnecting from " + bluetoothDeviceName(device) + "...";
            bluetoothMessageClearTimer.restart();
            device.disconnect();
            return;
        }

        if (device.paired || device.bonded) {
            bluetoothPairAndConnectPath = device.dbusPath;
            bluetoothInfoMessage = "Connecting to " + bluetoothDeviceName(device) + "...";
            device.trusted = true;
            bluetoothConnectionTimeoutTimer.restart();
            device.connect();
            return;
        }

        bluetoothPairAndConnectPath = device.dbusPath;
        bluetoothInfoMessage = "Pairing " + bluetoothDeviceName(device) + "...";
        bluetoothConnectionTimeoutTimer.restart();
        device.pair();
    }

    function bluetoothDeviceForPath(path) {
        const devices = bluetoothDeviceValues || [];
        for (let index = 0; index < devices.length; index++) {
            const device = devices[index];
            if (device && device.dbusPath === path)
                return device;
        }
        return null;
    }

    function finishBluetoothConnection(device) {
        if (!device || bluetoothPairAndConnectPath !== device.dbusPath)
            return;

        if (device.paired || device.bonded)
            device.trusted = true;

        bluetoothConnectAfterPairTimer.stop();
        bluetoothConnectionTimeoutTimer.stop();
        bluetoothPairAndConnectPath = "";
        bluetoothInfoMessage = "";
        bluetoothError = "";
    }

    function continueBluetoothPairAndConnect(device) {
        if (!device || bluetoothPairAndConnectPath !== device.dbusPath)
            return;
        if (device.pairing)
            return;

        if (!(device.paired || device.bonded)) {
            bluetoothConnectAfterPairTimer.stop();
            bluetoothConnectionTimeoutTimer.stop();
            bluetoothPairAndConnectPath = "";
            bluetoothInfoMessage = "";
            if (!bluetoothPairingActive)
                bluetoothError = "Pairing failed or was canceled.";
            return;
        }

        device.trusted = true;
        if (device.connected) {
            finishBluetoothConnection(device);
            return;
        }

        bluetoothInfoMessage = "Connecting to " + bluetoothDeviceName(device) + "...";
        bluetoothConnectAfterPairTimer.restart();
    }

    function handleBluetoothConnectionStateChanged(device) {
        if (!device || bluetoothPairAndConnectPath !== device.dbusPath)
            return;

        if (device.connected) {
            if (device.pairing)
                return;
            finishBluetoothConnection(device);
            return;
        }

        if (!device.pairing
                && (device.paired || device.bonded)
                && device.state === BluetoothDeviceState.Disconnected
                && !bluetoothConnectAfterPairTimer.running) {
            bluetoothConnectionTimeoutTimer.stop();
            bluetoothPairAndConnectPath = "";
            bluetoothInfoMessage = "";
            bluetoothError = "Paired successfully, but the connection failed. Make sure the device is still ready to connect.";
        }
    }

    function forgetBluetoothDevice(device) {
        if (!device) return;
        const name = bluetoothDeviceName(device);
        if (bluetoothPairAndConnectPath === device.dbusPath) {
            bluetoothConnectAfterPairTimer.stop();
            bluetoothConnectionTimeoutTimer.stop();
            bluetoothPairAndConnectPath = "";
        }
        device.forget();
        bluetoothError = "";
        bluetoothInfoMessage = "Forgot " + name + ".";
        bluetoothMessageClearTimer.restart();
    }

    // Timer ids below are only visible within this file (QML id scoping is
    // per-document, not inherited), so callers in derived types (e.g.
    // ControlCenterLayer.qml's setConnectivityPanelOpen) go through these
    // wrapper functions instead of referencing the timers directly.
    function startBluetoothScanForPanel() {
        if (bluetoothAdapter && bluetoothEnabled && !bluetoothAdapter.discovering) {
            bluetoothAdapter.discovering = true;
            bluetoothInfoMessage = "Scanning for nearby devices...";
            bluetoothScanStopTimer.restart();
        }
    }

    function stopBluetoothActivityForPanelClose() {
        if (bluetoothPairingActive)
            cancelBluetoothPairing();
        if (bluetoothAdapter && bluetoothAdapter.discovering)
            bluetoothAdapter.discovering = false;
        bluetoothScanStopTimer.stop();
        bluetoothConnectAfterPairTimer.stop();
        bluetoothConnectionTimeoutTimer.stop();
        bluetoothPairAndConnectPath = "";
        bluetoothPendingSecretValue = "";
        clearBluetoothMessages();
    }

    Timer {
        id: bluetoothScanStopTimer
        interval: 8000
        repeat: false
        onTriggered: {
            if (bluetoothAdapter && bluetoothAdapter.discovering)
                bluetoothAdapter.discovering = false;
            bluetoothInfoMessage = "";
        }
    }

    Timer {
        id: bluetoothConnectAfterPairTimer
        interval: 350
        repeat: false
        onTriggered: {
            const device = bluetoothDeviceForPath(bluetoothPairAndConnectPath);
            if (!device)
                return;
            if (device.connected) {
                finishBluetoothConnection(device);
                return;
            }
            device.connect();
        }
    }

    Timer {
        id: bluetoothConnectionTimeoutTimer
        interval: 30000
        repeat: false
        onTriggered: {
            if (bluetoothPairAndConnectPath.length === 0)
                return;
            bluetoothConnectAfterPairTimer.stop();
            bluetoothPairAndConnectPath = "";
            bluetoothInfoMessage = "";
            bluetoothError = "Bluetooth pairing or connection timed out. Put the device back in pairing mode and try again.";
        }
    }

    Timer {
        id: bluetoothMessageClearTimer
        interval: 2500
        repeat: false
        onTriggered: {
            if (bluetoothPairAndConnectPath.length === 0)
                bluetoothInfoMessage = "";
        }
    }
    Connections {
        target: Networking

        function onWifiEnabledChanged() {
            if (!wifiEnabled)
                clearWifiPrompt();
        }
    }
    Connections {
        target: bluetoothAdapter

        function onEnabledChanged() {
            if (!bluetoothAdapter.enabled) {
                bluetoothPairAndConnectPath = "";
                bluetoothInfoMessage = "";
                bluetoothError = "";
                bluetoothScanStopTimer.stop();
                bluetoothConnectAfterPairTimer.stop();
                bluetoothConnectionTimeoutTimer.stop();
            }
        }

        function onDiscoveringChanged() {
            if (!bluetoothAdapter.discovering)
                bluetoothScanStopTimer.stop();
        }
    }
    // Keep device state observers outside the filtered UI rows. A device moves
    // from "available" to "paired" during first-time pairing, which destroys
    // its old row before a row-local PairedChanged handler can reliably finish
    // the trust-and-connect sequence.
    Repeater {
        model: bluetoothDeviceValues

        delegate: Item {
            width: 0
            height: 0
            visible: false

            property var bluetoothDevice: modelData

            Connections {
                target: bluetoothDevice
                ignoreUnknownSignals: true

                function onPairedChanged() {
                    continueBluetoothPairAndConnect(bluetoothDevice);
                }

                function onBondedChanged() {
                    continueBluetoothPairAndConnect(bluetoothDevice);
                }

                function onPairingChanged() {
                    continueBluetoothPairAndConnect(bluetoothDevice);
                }

                function onConnectedChanged() {
                    handleBluetoothConnectionStateChanged(bluetoothDevice);
                }

                function onStateChanged() {
                    handleBluetoothConnectionStateChanged(bluetoothDevice);
                }
            }
        }
    }
}
