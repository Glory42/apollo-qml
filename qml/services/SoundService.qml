import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Output and input devices, the apps playing right now, and word of the microphone being muted.
Item {
    id: root

    visible: false

    // True while the Sound view is open; only then are devices and apps followed closely.
    property bool watching: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // Sorted by type, which PipeWire reports for every node; most other details only arrive once a node is followed.
    // The lists are only built while the Sound view is open.
    readonly property var outputs: !root.watching ? [] : Pipewire.nodes.values.filter((node) => !node.isStream
        && (node.type === PwNodeType.AudioSink || node.type === PwNodeType.AudioDuplex))
    readonly property var inputs: !root.watching ? [] : Pipewire.nodes.values.filter((node) => !node.isStream
        && (node.type === PwNodeType.AudioSource || node.type === PwNodeType.AudioDuplex))
    readonly property var streams: !root.watching ? [] : Pipewire.nodes.values.filter((node) => node.type === PwNodeType.AudioOutStream)

    // One entry per app with a stream that is playing into a device: { key, name, nodes }. Filled while watching.
    readonly property var apps: {
        if (!root.watching)
            return [];
        const playing = new Set(Pipewire.linkGroups.values
            .filter((group) => group.state === PwLinkState.Active && group.source)
            .map((group) => group.source.id));
        const byName = {};
        const list = [];
        for (const node of root.streams) {
            const props = node.properties || {};
            const name = props["application.name"] || "";
            // A stream with no app behind it, such as a loopback, is plumbing rather than an app.
            if (name === "" || !playing.has(node.id))
                continue;
            if (!byName[name]) {
                byName[name] = { key: name, name: name, nodes: [] };
                list.push(byName[name]);
            }
            byName[name].nodes.push(node);
        }
        return list.sort((a, b) => a.name.localeCompare(b.name));
    }

    signal micMuted(bool muted)

    function deviceName(node) {
        return node ? (node.description || node.nickname || node.name) : "";
    }

    function setOutput(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setInput(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Apps may go louder than they play by themselves, as far as this; devices stop at 100%.
    readonly property real appMaximum: 1.5

    function setVolume(node, value, maximum) {
        if (node && node.audio)
            node.audio.volume = Math.max(0, Math.min(maximum === undefined ? 1 : maximum, value));
    }

    function toggleMute(node) {
        if (node && node.audio)
            node.audio.muted = !node.audio.muted;
    }

    function appVolume(app) {
        const node = app.nodes.find((each) => each.audio);
        return node ? node.audio.volume : 0;
    }

    function appMuted(app) {
        return app.nodes.length > 0 && app.nodes.every((node) => node.audio && node.audio.muted);
    }

    function setAppVolume(app, value) {
        for (const node of app.nodes)
            root.setVolume(node, value, root.appMaximum);
    }

    function toggleAppMute(app) {
        const muted = !root.appMuted(app);
        for (const node of app.nodes) {
            if (node.audio)
                node.audio.muted = muted;
        }
    }

    // The microphone is always followed, for its peek; the rest only while the view is open.
    PwObjectTracker {
        objects: [root.source]
    }

    PwObjectTracker {
        objects: root.watching ? root.outputs.concat(root.inputs, root.streams, Pipewire.linkGroups.values) : []
    }

    // The mute already set when a microphone first reports in is not news.
    Timer {
        id: settling

        interval: 2000
        running: true
    }

    onSourceChanged: settling.restart()

    Connections {
        target: root.source && root.source.audio ? root.source.audio : null

        function onMutedChanged() {
            if (!settling.running)
                root.micMuted(root.source.audio.muted);
        }
    }
}
