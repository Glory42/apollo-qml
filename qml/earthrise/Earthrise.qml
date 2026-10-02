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

    signal opened()

    function open() {
        if (win.open)
            return;
        root.themes.refresh();
        carousel.currentIndex = Math.max(0, root.wallpapers.indexOf(root.themes.wallpaper));
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

        piece: "earthrise"
        bare: true
        onlyScreen: root.onlyScreen
        onDismissed: root.close()
        onOpenChanged: if (open) carousel.forceActiveFocus()

        Carousel {
            id: carousel

            emptyText: "Choose a theme in Visor first"
            model: root.wallpapers.map((path) => ({ image: path, title: path.slice(path.lastIndexOf("/") + 1), colors: [], accent: "" }))
            onDismissed: root.close()
            onChosen: (index) => {
                root.close();
                root.themes.setWallpaper(root.wallpapers[index]);
            }
        }
    }
}
