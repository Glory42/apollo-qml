import QtQuick
import Quickshell
import ".."

// Chooses the current theme from a carousel of main wallpapers.
Scope {
    id: root

    property var themes: null
    property string onlyScreen: ""
    readonly property bool isOpen: win.open
    readonly property var list: themes ? themes.themes : []
    readonly property var swatches: ["bg", "fg", "accent", "regular1", "regular2", "regular3", "regular4", "regular5", "regular6"]

    signal opened()

    function open() {
        if (win.open)
            return;
        root.themes.refresh();
        carousel.currentIndex = Math.max(0, root.list.findIndex((entry) => entry.id === root.themes.current));
        win.show();
        root.opened();
    }

    function close() {
        win.hide();
    }

    function toggle() {
        if (win.open)
            close();
        else
            open();
    }

    OrbiterWindow {
        id: win

        piece: "visor"
        bare: true
        onlyScreen: root.onlyScreen
        onDismissed: root.close()
        onOpenChanged: if (open) carousel.forceActiveFocus()

        Carousel {
            id: carousel

            emptyText: "No themes in " + Config.themeDir + "/themes"
            model: root.list.map((entry) => ({
                image: entry.wallpapers[0] || "",
                title: entry.name,
                colors: root.swatches.map((key) => Theme.toneOf(entry.palette, key, "")).filter((value) => value !== ""),
                accent: Theme.toneOf(entry.palette, "accent", "")
            }))
            onDismissed: root.close()
            onChosen: (index) => {
                root.close();
                root.themes.apply(root.list[index].id);
            }
        }
    }
}
