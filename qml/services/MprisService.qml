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
    property var playersList: Mpris.players.values !== undefined ? Mpris.players.values : Mpris.players
    property var activePlayer: resolveActivePlayer()

    readonly property string currentTrack: activePlayer ? (activePlayer.trackTitle || activePlayer.title || "Unknown") : ""
    readonly property string currentArtist: {
        if (!activePlayer) return "";
        let artist = activePlayer.artist;
        if (!artist && activePlayer.metadata) artist = activePlayer.metadata["xesam:artist"];
        if (artist) return Array.isArray(artist) ? artist.join(", ") : String(artist);
        return "Unknown";
    }
    readonly property string currentArtUrl: activePlayer ? (activePlayer.trackArtUrl || activePlayer.artUrl || "") : ""

    property real trackProgress: 0
    property string timePlayed: "0:00"
    property string timeTotal: "0:00"

    property var playerStates: ({})
    property var announcedKeys: ({})
    property var pendingPlayer: null
    property bool tracking: false

    function playerChanged(player) {
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
        const title = player.trackTitle || player.title || "";
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
        for (const player of (playersList || [])) {
            playerStates[player.dbusName] = player.playbackState === MprisPlaybackState.Playing;
            announcedKeys[player.dbusName] = (player.trackTitle || "") + "|" + String(player.trackArtist || "");
        }
        Qt.callLater(() => root.tracking = true);
    }

    Timer {
        id: announceTimer

        interval: 700
        onTriggered: root.announce()
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

        onObjectAdded: (index, object) => {
            if (root.tracking)
                root.playerChanged(object.modelData);
        }
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
        const numberValue = Number(value);
        if (isNaN(numberValue) || numberValue <= 0) return "0:00";

        let totalSeconds = 0;
        if (numberValue < 10000) totalSeconds = Math.floor(numberValue);
        else if (numberValue < 100000000) totalSeconds = Math.floor(numberValue / 1000);
        else totalSeconds = Math.floor(numberValue / 1000000);

        const minutes = Math.floor(totalSeconds / 60);
        const seconds = Math.floor(totalSeconds % 60);
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
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
            totalLength = Number(player.metadata["mpris:length"]);

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
        if ((player.trackTitle || player.title || "") !== "") return true;
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

        interval: 500
        running: root.activePlayer !== null && root.expanded
        repeat: true

        onTriggered: root.syncProgress()
    }
}
