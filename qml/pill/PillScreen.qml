import QtQuick
import Quickshell
import ".."

// Everything one monitor needs: the pill window and the click-outside catcher beneath it.
Scope {
    id: root

    property var screen: null
    property var services: null
    property bool dev: false

    readonly property var controller: window.controller
    readonly property bool monitorFocused: window.monitorFocused

    PillWindow {
        id: window

        screen: root.screen
        services: root.services
        dev: root.dev
    }

    DismissCatcher {
        screen: root.screen
        active: window.controller.isOpen
        onDismissed: window.controller.close()
    }
}
