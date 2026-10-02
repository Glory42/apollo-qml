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
    readonly property int start: Math.max(0, list.findIndex((entry) => entry.id === themes.current))
    readonly property var swatches: ["bg", "fg", "accent", "regular1", "regular2", "regular3", "regular4", "regular5", "regular6"]

    signal opened()

    function open() {
        if (win.open)
            return;
        root.themes.refresh();
        win.show();
        aim();
        root.opened();
    }

    // Puts the current theme in the middle, and the keyboard on the carousel.
    function aim() {
        if (!loader.item)
            return;
        loader.item.currentIndex = root.start;
        loader.item.forceActiveFocus();
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

        // The carousel and its pictures exist only while Visor is on screen.
        Loader {
            id: loader

            active: win.shown
            onLoaded: root.aim()

            sourceComponent: Carousel {
                emptyText: "No themes in " + Config.themeDir + "/themes"
                currentIndex: root.start
                model: root.list.map((entry) => ({
                    key: entry.id,
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
}
