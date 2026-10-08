import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import "BluetoothFormatting.js" as BluetoothFormatting
import ".."

// Headless Wi-Fi and Bluetooth state plus the connect, password, pair and forget flows.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool wifiOpen: false
    property bool bluetoothOpen: false
    property string message: ""
    property string error: ""
    property string pendingSsid: ""
    property string pendingPath: ""
    property int pendingTicks: 0
    property bool connectIssued: false
    property string attemptSsid: ""
    property bool attemptWasKnown: false
    property bool attemptSawConnecting: false
    property bool attemptConnectIssued: false
    property int attemptTicks: 0

    readonly property alias agent: agent

    readonly property var wifiDevice: {
        const devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi) return devs[i];
        return null;
    }
    // The first wired port NetworkManager looks after, built in or on an adapter; null on a machine without one.
    readonly property var wiredDevice: {
        const devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wired && devs[i].nmManaged) return devs[i];
        return null;
    }
    readonly property string wiredName: {
        if (!wiredDevice) return "";
        if (!wiredDevice.hasLink) return "Cable unplugged";
        if (!wiredDevice.connected) return "Not connected";
        return wiredDevice.linkSpeed > 0 ? "Connected · " + speedText(wiredDevice.linkSpeed) : "Connected";
    }
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var wifiNetwork: {
        if (!wifiDevice || !wifiEnabled) return null;
        const nets = wifiDevice.networks.values;
        for (let i = 0; i < nets.length; i++)
            if (nets[i].connected) return nets[i];
        return null;
    }
    // The icon for the Wi-Fi tile: bars while connected, the plain symbol otherwise.
    readonly property string wifiIcon: wifiNetwork ? signalIcon(wifiNetwork.signalStrength) : "wifi"
    readonly property string wifiName: {
        if (!wifiDevice) return "No adapter";
        if (!wifiEnabled) return "Off";
        const nets = wifiDevice.networks.values;
        for (let i = 0; i < nets.length; i++)
            if (nets[i].connected) return nets[i].name;
        return "Not connected";
    }
    // Built only while the Wi-Fi view is open, as bluetoothRows is while the Bluetooth view is.
    readonly property var wifiNetworks: {
        if (!wifiOpen || !wifiDevice || !wifiEnabled) return [];
        const seen = {};
        const list = [];
        const nets = wifiDevice.networks.values;
        for (let i = 0; i < nets.length; i++) {
            const name = String(nets[i].name || "").trim();
            if (name === "" || seen[name]) continue;
            seen[name] = true;
            list.push(nets[i]);
        }
        list.sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
        return list;
    }

    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothEnabled: bluetoothAdapter ? bluetoothAdapter.enabled : false
    readonly property bool bluetoothScanning: bluetoothAdapter ? bluetoothAdapter.discovering : false
    readonly property string bluetoothName: {
        if (!bluetoothAdapter) return "No adapter";
        if (!bluetoothEnabled) return "Off";
        const devs = bluetoothAdapter.devices.values;
        for (let i = 0; i < devs.length; i++)
            if (devs[i].connected) return deviceName(devs[i]);
        return "On";
    }
    readonly property var bluetoothRows: {
        if (!bluetoothOpen || !bluetoothAdapter || !bluetoothEnabled) return [];
        const devs = bluetoothAdapter.devices.values;
        const groups = { connected: [], paired: [], available: [] };
        for (let i = 0; i < devs.length; i++) {
            const section = sectionOf(devs[i]);
            if (section === "available" && !BluetoothFormatting.friendlyName(devs[i].name, devs[i].deviceName, devs[i].address)) continue;
            groups[section].push(devs[i]);
        }
        const rows = [];
        const titles = { connected: "Connected", paired: "Paired", available: "Available" };
        for (const key of ["connected", "paired", "available"]) {
            if (groups[key].length === 0) continue;
            rows.push({ key: key, kind: "header", text: titles[key] });
            for (const device of groups[key])
                rows.push({ key: key + " " + device.dbusPath, kind: "device", device: device, section: key });
        }
        return rows;
    }

    // Bars for a signal strength from 0 to 1.
    function signalIcon(strength) {
        const value = Number(strength) || 0;
        return "wifi_" + (value >= 0.8 ? 4 : value >= 0.6 ? 3 : value >= 0.4 ? 2 : value >= 0.2 ? 1 : 0);
    }

    function speedText(megabits) {
        return megabits >= 1000 ? (megabits / 1000) + " Gb/s" : megabits + " Mb/s";
    }

    function connectWired() {
        if (wiredDevice && wiredDevice.network)
            wiredDevice.network.connect();
    }

    function isSecure(network) {
        return !!network && network.security !== WifiSecurityType.Open;
    }

    function isUnsupported(network) {
        const s = network.security;
        return s === WifiSecurityType.StaticWep || s === WifiSecurityType.DynamicWep
            || s === WifiSecurityType.Wpa2Eap || s === WifiSecurityType.WpaEap
            || s === WifiSecurityType.Wpa3SuiteB192 || s === WifiSecurityType.Leap;
    }

    function findNetwork(ssid) {
        const nets = wifiDevice ? wifiDevice.networks.values : [];
        for (let i = 0; i < nets.length; i++)
            if (nets[i].name === ssid) return nets[i];
        return null;
    }

    function toggleWifi() {
        clearFeedback();
        pendingSsid = "";
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function connectWifi(network) {
        if (!network || network.connected) return;
        clearFeedback();
        if (network.known || !isSecure(network)) {
            beginAttempt(network);
            attemptConnectIssued = true;
            network.connect();
            return;
        }
        if (isUnsupported(network)) {
            error = "This network type has to be set up outside the shell.";
            return;
        }
        pendingSsid = network.name;
    }

    function submitWifiPassword(password) {
        if (password.length === 0) {
            error = "Enter a password first.";
            return;
        }
        const network = findNetwork(pendingSsid);
        pendingSsid = "";
        if (!network) return;
        beginAttempt(network);
        network.connectWithPsk(password);
    }

    function beginAttempt(network) {
        attemptSsid = network.name;
        attemptWasKnown = network.known;
        attemptSawConnecting = false;
        attemptTicks = 0;
        attemptConnectIssued = false;
        message = "Connecting to " + network.name;
        attemptTimer.restart();
    }

    function endAttempt() {
        attemptTimer.stop();
        attemptSsid = "";
        message = "";
    }

    function wifiConnecting(network) {
        return network.state === ConnectionState.Connecting;
    }

    function disconnectWifi(network) {
        if (network) network.disconnect();
    }

    function forgetWifi(network) {
        if (network) network.forget();
    }

    function toggleBluetooth() {
        if (!bluetoothAdapter) return;
        clearFeedback();
        bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
    }

    function sectionOf(device) {
        if (device.connected) return "connected";
        return device.paired || device.bonded ? "paired" : "available";
    }

    function deviceName(device) {
        return BluetoothFormatting.displayName(device.name, device.deviceName, device.address, device.icon);
    }

    function deviceBusy(device) {
        if (device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting)
            return true;
        return pendingPath !== "" && pendingPath !== device.dbusPath;
    }

    function deviceSubtitle(device) {
        const parts = [];
        if (device.pairing) parts.push("Pairing");
        else if (device.state === BluetoothDeviceState.Connecting) parts.push("Connecting");
        else if (device.state === BluetoothDeviceState.Disconnecting) parts.push("Disconnecting");
        else if (device.connected) parts.push("Connected");
        else if (device.paired || device.bonded) parts.push("Paired");
        else parts.push("Available");
        if (device.batteryAvailable) {
            const raw = Math.max(0, Number(device.battery) || 0);
            parts.push(Math.round(raw <= 1 ? raw * 100 : raw) + "%");
        }
        return parts.join(" · ");
    }

    function pressDevice(device) {
        clearFeedback();
        if (!bluetoothEnabled) {
            error = "Turn on Bluetooth first.";
            return;
        }
        if (device.connected) {
            device.disconnect();
            return;
        }
        pendingPath = device.dbusPath;
        pendingTicks = 0;
        connectIssued = false;
        agent.pairingInitiated = true;
        pendingTimer.restart();
        if (device.paired || device.bonded) {
            connectIssued = true;
            device.trusted = true;
            device.connect();
        } else {
            device.pair();
        }
    }

    function forgetDevice(device) {
        clearFeedback();
        device.forget();
    }

    function deviceForPath(path) {
        const devs = bluetoothAdapter ? bluetoothAdapter.devices.values : [];
        for (let i = 0; i < devs.length; i++)
            if (devs[i].dbusPath === path) return devs[i];
        return null;
    }

    function clearFeedback() {
        message = "";
        error = "";
    }

    function cancelPairing() {
        const device = deviceForPath(pendingPath);
        agent.reject();
        if (device) device.cancelPair();
        endPending();
    }

    function endPending() {
        agent.pairingInitiated = false;
        pendingTimer.stop();
        pendingPath = "";
        connectIssued = false;
    }

    onErrorChanged: if (error !== "") feedbackTimer.restart()
    onWifiOpenChanged: if (!wifiOpen) { pendingSsid = ""; clearFeedback(); }
    onBluetoothOpenChanged: if (!bluetoothOpen) { endPending(); clearFeedback(); }

    Timer {
        id: feedbackTimer

        interval: 5000
        onTriggered: root.clearFeedback()
    }

    // After a fresh pair succeeds the device still has to be connected, so poll until it is.
    Timer {
        id: pendingTimer

        interval: 500
        repeat: true
        onTriggered: {
            const device = root.deviceForPath(root.pendingPath);
            if (!device) {
                root.endPending();
                return;
            }
            root.pendingTicks += 1;
            if (device.connected) {
                root.endPending();
                return;
            }
            if (!root.connectIssued && !device.pairing && (device.paired || device.bonded)) {
                root.connectIssued = true;
                device.trusted = true;
                device.connect();
            }
            if (root.pendingTicks > 40) {
                const paired = device.paired || device.bonded;
                root.error = paired
                    ? "Paired, but the connection failed. Make sure the device is still ready to connect."
                    : "Could not pair with " + root.deviceName(device) + ".";
                root.endPending();
            }
        }
    }

    Timer {
        id: attemptTimer

        interval: 500
        repeat: true
        onTriggered: {
            const network = root.findNetwork(root.attemptSsid);
            if (!network) {
                root.endAttempt();
                return;
            }
            if (network.connected) {
                root.endAttempt();
                return;
            }
            root.attemptTicks += 1;
            if (network.state === ConnectionState.Connecting) root.attemptSawConnecting = true;
            const idle = network.state === ConnectionState.Disconnected || network.state === ConnectionState.Unknown;
            if (!root.attemptConnectIssued && network.known && idle && root.attemptTicks > 1) {
                root.attemptConnectIssued = true;
                network.connect();
                return;
            }
            const failed = root.attemptSawConnecting && idle && root.attemptConnectIssued;
            if (failed || root.attemptTicks > 30) {
                const ssid = root.attemptSsid;
                if (!root.attemptWasKnown && network.known) network.forget();
                root.endAttempt();
                root.error = "Could not connect to " + ssid + ". Check the password and try again.";
            }
        }
    }

    BluetoothAgent {
        id: agent

        active: root.bluetoothOpen && root.bluetoothEnabled
    }

    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.wifiOpen && root.wifiEnabled
        when: root.wifiDevice !== null
    }

    Binding {
        target: root.bluetoothAdapter
        property: "discovering"
        value: root.bluetoothOpen && root.bluetoothEnabled
        when: root.bluetoothAdapter !== null
    }
}
