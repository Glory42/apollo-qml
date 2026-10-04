import QtQuick
import Quickshell
import ".."

// Chooses a wallpaper from those belonging to the current theme, in a carousel in the middle of the screen.
Scope {
    id: root

    property var themes: null
    property string onlyScreen: ""
    readonly property bool isOpen: win.open
    readonly property var wallpapers: themes && themes.currentTheme ? themes.currentTheme.wallpapers : []

    readonly property string fill: themes && themes.currentTheme ? Theme.toneOf(themes.currentTheme.palette, "bg", "") : ""
    readonly property int start: Math.max(0, wallpapers.indexOf(themes ? themes.wallpaper : ""))

    signal opened()

    function open() {
        if (win.open)
            return;
        root.themes.refresh();
        win.show();
        aim();
        root.opened();
    }

    // Puts the current wallpaper in the middle, and the keyboard on the carousel.
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

        piece: "earthrise"
        bare: true
        onlyScreen: root.onlyScreen
        onDismissed: root.close()

        // The carousel and its pictures exist only while Earthrise is on screen.
        Loader {
            id: loader

            active: win.shown
            onLoaded: root.aim()

            sourceComponent: Carousel {
                emptyText: "Choose a theme in Visor first"
                currentIndex: root.start
                model: root.wallpapers.map((path) => ({ key: path, image: root.themes.preview(path), fill: root.fill, title: path.slice(path.lastIndexOf("/") + 1), colors: [], accent: "" }))
                onDismissed: root.close()
                onChosen: (index) => {
                    root.close();
                    root.themes.setWallpaper(root.wallpapers[index]);
                }
            }
        }
    }
}
