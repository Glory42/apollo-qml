import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// The rice's themes and the current theme and wallpaper; a theme owns only the wallpapers its theme.json lists.
Item {
    id: root

    visible: false

    // { id, name, palette, wallpapers: [path] }
    property var themes: []
    property string current: ""
    property string wallpaper: ""

    readonly property var currentTheme: themes.find((entry) => entry.id === current) || null

    function refresh() {
        lister.running = true;
    }

    function parse(text) {
        const found = [];
        for (const block of text.split(/^@@theme /m).slice(1)) {
            const id = block.slice(0, block.indexOf("\n"));
            const parts = block.slice(block.indexOf("\n") + 1).split(/^@@palette$/m);
            try {
                const info = JSON.parse(parts[0]);
                let palette = {};
                try {
                    palette = JSON.parse(parts[1]);
                } catch (error) {
                }
                const names = [info.main_wallpaper].concat(info.wallpapers || []).filter((name) => typeof name === "string" && name !== "");
                found.push({
                    id: id,
                    name: info.name || id,
                    palette: palette,
                    wallpapers: names.map((name) => Config.themeDir + "/themes/" + id + "/wallpapers/" + name)
                });
            } catch (error) {
                console.warn("theme", id, "has an unreadable theme.json");
            }
        }
        root.themes = found;
    }

    function save() {
        store.setText(JSON.stringify({ current: root.current, wallpaper: root.wallpaper }));
    }

    function setWallpaper(path) {
        if (!path)
            return;
        Quickshell.execDetached(Config.wallpaperCommand.concat([path]));
        root.wallpaper = path;
        save();
    }

    function apply(id) {
        const next = root.themes.find((entry) => entry.id === id);
        if (!next)
            return;
        Quickshell.execDetached(["sh", "-c", 'cp "$1/themes/$2/palette.json" "$1/palette.json"; ' + Config.themeApplyCommand, "sh", Config.themeDir, id]);
        root.current = id;
        reread.restart();
        setWallpaper(next.wallpapers[0]);
        save();
    }

    Component.onCompleted: refresh()

    // In case the palette file did not exist yet to be watched.
    Timer {
        id: reread

        interval: 400
        onTriggered: Theme.reload()
    }

    Process {
        id: lister

        command: ["sh", "-c", 'for d in "$1"/themes/*/; do [ -f "$d/theme.json" ] || continue; printf "@@theme %s\\n" "$(basename "$d")"; cat "$d/theme.json"; printf "\\n@@palette\\n"; cat "$d/palette.json" 2>/dev/null; printf "\\n"; done', "sh", Config.themeDir]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    FileView {
        id: store

        path: Quickshell.statePath("theme.json")
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(store.text());
                root.current = saved.current || "";
                root.wallpaper = saved.wallpaper || "";
            } catch (error) {
            }
        }
    }
}
