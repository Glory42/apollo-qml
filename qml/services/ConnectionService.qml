import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// One network connection up close: its traffic, ping, addresses and DNS, and its Wi-Fi password to share.
// It measures only while it exists, so the connection page creates it and nothing else does.
Item {
    id: root

    visible: false

    property var device: null

    readonly property string iface: device ? device.name : ""
    readonly property bool isWifi: !!device && device.type === DeviceType.Wifi
    readonly property var network: {
        if (!device)
            return null;
        if (!isWifi)
            return device.network;
        const nets = device.networks.values;
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected)
                return nets[i];
        }
        return null;
    }

    property string uuid: ""
    property string ip: ""
    property string gateway: ""
    // "auto", "cloudflare", "google" or "custom"
    property string dns: "auto"
    property string customDns: ""
    property bool applying: false

    property real rxRate: 0
    property real txRate: 0
    property real rxTotal: -1
    property real txTotal: -1
    property real lastSample: 0

    // Recent pings in milliseconds, -1 for one that got no answer.
    property var pings: []
    readonly property real ping: {
        const answered = pings.filter((ms) => ms >= 0).slice(-5);
        return answered.length > 0 ? answered.reduce((a, b) => a + b, 0) / answered.length : -1;
    }
    readonly property int loss: pings.length > 0 ? Math.round(100 * pings.filter((ms) => ms < 0).length / pings.length) : -1

    property string password: ""
    property string qrFile: ""
    // True when the QR code could not be drawn, which usually means qrencode is not installed.
    property bool qrFailed: false

    // Prints uuid=, ip=, gateway=, fixed= and servers= lines for the device given as $1.
    readonly property string detailsScript: 'u=$(nmcli -g GENERAL.CON-UUID device show "$1" 2>/dev/null); echo "uuid=$u";'
        + ' nmcli -t -f IP4.ADDRESS,IP4.GATEWAY device show "$1" 2>/dev/null | sed -n "s/^IP4.ADDRESS\\[1\\]:/ip=/p; s/^IP4.GATEWAY:/gateway=/p";'
        + ' [ -n "$u" ] && echo "fixed=$(nmcli -g ipv4.ignore-auto-dns connection show "$u")" && echo "servers=$(nmcli -g ipv4.dns,ipv6.dns connection show "$u" | tr "\\n" ",")"'

    readonly property var providers: ({
        cloudflare: { v4: "1.1.1.1,1.0.0.1", v6: "2606:4700:4700::1111,2606:4700:4700::1001" },
        google: { v4: "8.8.8.8,8.8.4.4", v6: "2001:4860:4860::8888,2001:4860:4860::8844" }
    })

    function bytes(value) {
        if (value < 0)
            return "-";
        const units = ["B", "KB", "MB", "GB", "TB"];
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit += 1;
        }
        return (unit === 0 ? Math.round(value) : value.toFixed(value < 10 ? 2 : 1)) + " " + units[unit];
    }

    function rate(value) {
        return root.bytes(value) + "/s";
    }

    // nmcli takes "auto" back to what the network hands out, the rest as servers of this connection only.
    function setDns(mode, servers) {
        if (root.uuid === "" || root.applying)
            return;
        let v4 = "";
        let v6 = "";
        if (mode === "custom") {
            const list = String(servers || "").split(/[\s,]+/).filter((each) => each !== "");
            v4 = list.filter((each) => each.indexOf(":") < 0).join(",");
            v6 = list.filter((each) => each.indexOf(":") >= 0).join(",");
            if (v4 === "" && v6 === "")
                return;
        } else if (root.providers[mode]) {
            v4 = root.providers[mode].v4;
            v6 = root.providers[mode].v6;
        }
        const fixed = mode === "auto" ? "no" : "yes";
        root.applying = true;
        root.dns = mode;
        dnsSet.command = ["sh", "-c", 'nmcli connection modify "$1" ipv4.ignore-auto-dns "$2" ipv4.dns "$3" ipv6.ignore-auto-dns "$2" ipv6.dns "$4" && nmcli device reapply "$5"',
            "sh", root.uuid, fixed, v4, v6, root.iface];
        dnsSet.running = true;
    }

    // Reads the saved password and draws it as the QR code phones scan to join.
    function share() {
        if (!root.isWifi || root.uuid === "" || secrets.running)
            return;
        secrets.running = true;
    }

    function forgetShared() {
        root.password = "";
        if (root.qrFile !== "")
            Quickshell.execDetached(["rm", "-f", root.qrFile]);
        root.qrFile = "";
    }

    function escapeQr(text) {
        return String(text).replace(/([\\;,:"])/g, "\\$1");
    }

    function refresh() {
        if (root.iface === "" || details.running)
            return;
        details.command = ["sh", "-c", root.detailsScript, "sh", root.iface];
        details.running = true;
    }

    onIfaceChanged: {
        root.pings = [];
        root.rxTotal = -1;
        root.txTotal = -1;
        root.forgetShared();
        root.refresh();
    }

    Component.onCompleted: refresh()
    Component.onDestruction: forgetShared()

    Process {
        id: details

        stdout: StdioCollector {
            onStreamFinished: {
                const values = {};
                for (const line of text.split("\n")) {
                    const at = line.indexOf("=");
                    if (at > 0)
                        values[line.slice(0, at)] = line.slice(at + 1).trim();
                }
                root.uuid = values.uuid || "";
                root.ip = (values.ip || "").split("/")[0];
                root.gateway = values.gateway || "";
                const servers = (values.servers || "").replace(/\\:/g, ":").split(",").filter((each) => each !== "");
                if (values.fixed !== "yes" || servers.length === 0)
                    root.dns = "auto";
                else if (servers.indexOf("1.1.1.1") >= 0)
                    root.dns = "cloudflare";
                else if (servers.indexOf("8.8.8.8") >= 0)
                    root.dns = "google";
                else
                    root.dns = "custom";
                root.customDns = root.dns === "custom" ? servers.join(" ") : root.customDns;
            }
        }
    }

    Process {
        id: dnsSet

        onExited: {
            root.applying = false;
            root.refresh();
        }
    }

    Process {
        id: secrets

        command: ["nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", root.uuid]
        stdout: StdioCollector {
            onStreamFinished: {
                root.password = text.trim();
                const name = root.network ? root.network.name : "";
                const kind = root.password !== "" ? "WPA" : "nopass";
                const file = Quickshell.env("XDG_RUNTIME_DIR") + "/apollo-share-" + Date.now() + ".png";
                const payload = "WIFI:T:" + kind + ";S:" + root.escapeQr(name) + ";" + (root.password !== "" ? "P:" + root.escapeQr(root.password) + ";" : "") + ";";
                qr.command = ["qrencode", "-s", "8", "-m", "2", "-o", file, payload];
                qr.file = file;
                qr.running = true;
            }
        }
    }

    Process {
        id: qr

        property string file: ""

        onExited: (exitCode) => {
            root.qrFailed = exitCode !== 0;
            if (exitCode === 0)
                root.qrFile = qr.file;
        }
    }

    // Traffic, from the kernel's counters for the interface, once a second.
    Timer {
        interval: 1000
        running: root.iface !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            rxFile.reload();
            txFile.reload();
        }
    }

    FileView {
        id: rxFile

        path: root.iface !== "" ? "/sys/class/net/" + root.iface + "/statistics/rx_bytes" : ""
        printErrors: false
        onLoaded: {
            const total = parseFloat(text());
            const now = Date.now();
            if (root.rxTotal >= 0 && root.lastSample > 0)
                root.rxRate = Math.max(0, (total - root.rxTotal) * 1000 / Math.max(1, now - root.lastSample));
            root.rxTotal = total;
            root.lastSample = now;
        }
    }

    FileView {
        id: txFile

        path: root.iface !== "" ? "/sys/class/net/" + root.iface + "/statistics/tx_bytes" : ""
        printErrors: false
        onLoaded: {
            const total = parseFloat(text());
            if (root.txTotal >= 0)
                root.txRate = Math.max(0, total - root.txTotal);
            root.txTotal = total;
        }
    }

    // Round trips to the internet, one a second; -O reports each ping that got no answer.
    Process {
        running: root.iface !== ""
        command: ["ping", "-n", "-O", "-i", "1", "-W", "1", "1.1.1.1"]
        stdout: SplitParser {
            onRead: (line) => {
                const answered = line.match(/time=([\d.]+)/);
                let sample = null;
                if (answered)
                    sample = parseFloat(answered[1]);
                else if (line.indexOf("no answer yet") >= 0)
                    sample = -1;
                if (sample !== null)
                    root.pings = root.pings.concat([sample]).slice(-20);
            }
        }
    }
}
