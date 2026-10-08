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
    property string listing: ""
    // { original path: preview path }, for the wallpapers whose preview has been made.
    property var previews: ({})

    readonly property var currentTheme: themes.find((entry) => entry.id === current) || null

    function refresh() {
        lister.running = true;
    }

    // A small picture to show in place of a wallpaper; the original until its preview exists.
    function preview(path) {
        return root.previews[path] || path;
    }

    // Makes the missing previews in the background; a wallpaper that changed gets a new one.
    function makePreviews() {
        if (previewer.running) {
            previewer.again = true;
            return;
        }
        const paths = [];
        for (const entry of root.themes)
            paths.push(...entry.wallpapers);
        if (paths.length === 0)
            return;
        previewer.found = {};
        previewer.command = ["sh", "-c", previewer.script, "sh", Quickshell.cachePath("previews")].concat(paths);
        previewer.running = true;
    }

    function publishPreviews() {
        if (JSON.stringify(previewer.found) !== JSON.stringify(root.previews))
            root.previews = Object.assign({}, previewer.found);
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
            // An unchanged listing leaves the themes alone, so nothing showing them is rebuilt.
            onStreamFinished: {
                if (text !== root.listing) {
                    root.listing = text;
                    root.parse(text);
                    root.makePreviews();
                    return;
                }
                const originals = [];
                for (const entry of root.themes)
                    originals.push(...entry.wallpapers);
                const made = originals.map((path) => root.previews[path]);
                if (originals.length === 0 || made.some((path) => !path)) {
                    root.makePreviews();
                    return;
                }
                checker.originals = originals;
                checker.command = ["stat", "-c", "%n\t%Y-%s"].concat(originals, made);
                checker.running = true;
            }
        }
    }

    // With every preview made, one stat checks they all still exist and each wallpaper's time and size match its preview's name.
    Process {
        id: checker

        property var originals: []

        stdout: StdioCollector {
            // A missing file prints no line, so its stamp is undefined and it counts as stale.
            onStreamFinished: {
                const stamps = {};
                for (const line of text.split("\n")) {
                    const tab = line.lastIndexOf("\t");
                    if (tab > 0)
                        stamps[line.slice(0, tab)] = line.slice(tab + 1);
                }
                const stale = checker.originals.some((path) => {
                    const made = root.previews[path];
                    return !stamps[made] || !made.endsWith("-" + stamps[path] + ".jpg");
                });
                if (stale)
                    root.makePreviews();
            }
        }
    }

    // Prints "original<TAB>preview" for each wallpaper, the ones already made first.
    Process {
        id: previewer

        property var found: ({})
        property bool again: false
        readonly property string script: 'dir="$1"; shift; mkdir -p "$dir" || exit 0; missing=""; '
            + 'name() { printf "%s/%s-%s.jpg" "$dir" "$(printf "%s" "$1" | sha1sum | cut -c1-16)" "$(stat -c "%Y-%s" "$1")"; }; '
            + 'for f; do [ -f "$f" ] || continue; out=$(name "$f"); if [ -f "$out" ]; then printf "%s\\t%s\\n" "$f" "$out"; else missing=1; fi; done; '
            + '[ -n "$missing" ] || exit 0; '
            + 'for f; do [ -f "$f" ] || continue; out=$(name "$f"); [ -f "$out" ] && continue; tmp="$dir/.tmp-$$.jpg"; '
            + 'nice -n 19 vipsthumbnail "$f" --size 1320x1320 -o "$tmp[Q=85]" 2>/dev/null || nice -n 19 magick "$f" -thumbnail 1320x -quality 85 "$tmp" 2>/dev/null; '
            + '[ -s "$tmp" ] && mv "$tmp" "$out" && printf "%s\\t%s\\n" "$f" "$out"; rm -f "$tmp"; done'

        stdout: SplitParser {
            onRead: (line) => {
                const tab = line.indexOf("\t");
                if (tab <= 0)
                    return;
                previewer.found[line.slice(0, tab)] = line.slice(tab + 1);
                publish.restart();
            }
        }
        onExited: {
            publish.stop();
            root.publishPreviews();
            if (again) {
                again = false;
                root.makePreviews();
            }
        }
    }

    // Previews that are already made arrive together, so they are shown in one go.
    Timer {
        id: publish

        interval: 100
        onTriggered: root.publishPreviews()
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
