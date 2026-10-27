import QtQuick
import Quickshell.Services.Mpris

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool expanded: false

    signal nowPlaying(string title, string artist, string artUrl)

    property string lastActivePlayerDbusName: ""
    property var playersList: Mpris.players.values
    property var activePlayer: resolveActivePlayer()

    readonly property string currentTrack: activePlayer ? (activePlayer.trackTitle || "Unknown") : ""
    readonly property string currentArtist: {
        if (!activePlayer) return "";
        let artist = activePlayer.artist;
        if (!artist && activePlayer.metadata) artist = activePlayer.metadata["xesam:artist"];
        if (artist) return Array.isArray(artist) ? artist.join(", ") : String(artist);
        return "Unknown";
    }
    readonly property string currentArtUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""

    property real trackProgress: 0
    property string timePlayed: "0:00"
    property string timeTotal: "0:00"

    property var playerStates: ({})
    property var announcedKeys: ({})
    property var pendingPlayer: null
    property bool tracking: false

    // What a player is playing, noted without being announced.
    function remember(player) {
        if (!player || !player.dbusName)
            return;
        playerStates[player.dbusName] = player.playbackState === MprisPlaybackState.Playing;
        announcedKeys[player.dbusName] = (player.trackTitle || "") + "|" + String(player.trackArtist || "");
    }

    // What plays as the shell starts is not news, including a player that only turns up a moment later.
    function playerChanged(player) {
        if (!tracking) {
            remember(player);
            return;
        }
        pendingPlayer = player;
        announceTimer.restart();
    }

    function announce() {
        const player = pendingPlayer;
        pendingPlayer = null;
        if (!player || !player.dbusName)
            return;
        const name = player.dbusName;
        const playing = player.playbackState === MprisPlaybackState.Playing;
        const started = playing && !playerStates[name];
        playerStates[name] = playing;
        const title = player.trackTitle || "";
        if (!playing || title === "")
            return;
        const artist = String(player.trackArtist || "");
        const key = title + "|" + artist;
        if (!started && key === announcedKeys[name])
            return;
        announcedKeys[name] = key;
        lastActivePlayerDbusName = name;
        nowPlaying(title, artist, player.trackArtUrl || "");
    }

    Component.onCompleted: {
        for (const player of (playersList || []))
            remember(player);
    }

    Timer {
        id: announceTimer

        interval: 700
        onTriggered: root.announce()
    }

    Timer {
        interval: 3000
        running: true
        onTriggered: root.tracking = true
    }

    Instantiator {
        model: Mpris.players

        delegate: Connections {
            required property var modelData

            target: modelData
            ignoreUnknownSignals: true

            function onPlaybackStateChanged() { root.playerChanged(modelData); }
            function onTrackTitleChanged() { root.playerChanged(modelData); }
            function onTrackArtistChanged() { root.playerChanged(modelData); }
        }

        onObjectAdded: (index, object) => root.playerChanged(object.modelData)
    }

    onActivePlayerChanged: {
        Qt.callLater(function() {
            const nextDbusName = root.activePlayer && root.activePlayer.dbusName
                ? root.activePlayer.dbusName
                : "";
            if (root.lastActivePlayerDbusName !== nextDbusName)
                root.lastActivePlayerDbusName = nextDbusName;
        });
    }

    function formatTime(value) {
        const totalSeconds = Math.floor(Number(value));
        if (isNaN(totalSeconds) || totalSeconds <= 0) return "0:00";

        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor(totalSeconds % 3600 / 60);
        const seconds = totalSeconds % 60;
        const pad = n => (n < 10 ? "0" : "") + n;
        return hours > 0 ? hours + ":" + pad(minutes) + ":" + pad(seconds) : minutes + ":" + pad(seconds);
    }

    function syncProgress(positionOverride) {
        let player = root.activePlayer;
        if (!player) {
            root.trackProgress = 0;
            root.timePlayed = "0:00";
            root.timeTotal = "0:00";
            return;
        }

        const currentPosition = positionOverride === undefined
            ? Number(player.position) || 0
            : Number(positionOverride) || 0;
        let totalLength = Number(player.length) || 0;
        if (totalLength <= 0 && player.metadata && player.metadata["mpris:length"])
            totalLength = Number(player.metadata["mpris:length"]) / 1000000;

        if (totalLength > 0) {
            root.trackProgress = Math.max(0, Math.min(1, currentPosition / totalLength));
            root.timePlayed = root.formatTime(currentPosition);
            root.timeTotal = root.formatTime(totalLength);
        } else {
            root.trackProgress = 0;
            root.timePlayed = root.formatTime(currentPosition);
            root.timeTotal = "0:00";
        }
    }

    function syncToTrackStart(player) {
        if (player && player.canSeek && player.positionSupported)
            player.position = 0;

        syncProgress(0);
    }

    function previous() {
        let player = root.activePlayer;
        if (!player) return;

        player.previous();
        syncToTrackStart(player);
    }

    function playerHasTrackInfo(player) {
        if (!player) return false;
        if ((player.trackTitle || "") !== "") return true;
        if (!player.metadata) return false;
        return Boolean(
            player.metadata["xesam:title"]
            || player.metadata["mpris:trackid"]
            || player.metadata["xesam:url"]
        );
    }

    function findPlayerByDbusName(dbusName) {
        if (!playersList || !dbusName) return null;
        for (let index = 0; index < playersList.length; index++) {
            if (playersList[index].dbusName === dbusName)
                return playersList[index];
        }
        return null;
    }

    function resolveActivePlayer() {
        if (!playersList || playersList.length === 0) return null;

        const latest = findPlayerByDbusName(lastActivePlayerDbusName);
        if (latest && latest.playbackState === MprisPlaybackState.Playing)
            return latest;

        for (let index = 0; index < playersList.length; index++) {
            if (playersList[index].playbackState === MprisPlaybackState.Playing)
                return playersList[index];
        }

        const rememberedPlayer = findPlayerByDbusName(lastActivePlayerDbusName);
        if (rememberedPlayer && (playerHasTrackInfo(rememberedPlayer) || rememberedPlayer.canControl))
            return rememberedPlayer;

        for (let index = 0; index < playersList.length; index++) {
            if (playersList[index].playbackState === MprisPlaybackState.Paused && playerHasTrackInfo(playersList[index]))
                return playersList[index];
        }

        for (let index = 0; index < playersList.length; index++) {
            if (playersList[index].canControl)
                return playersList[index];
        }

        return playersList[0];
    }

    Timer {
        id: progressPoller

        interval: 1000
        running: root.activePlayer !== null && root.expanded && root.activePlayer.isPlaying
        repeat: true

        onRunningChanged: root.syncProgress()
        onTriggered: root.syncProgress()
    }
}
