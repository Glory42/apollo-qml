import QtQuick
import Quickshell
import ".."

// Everything one monitor needs: the capsule window and the click-outside catcher beneath it.
Scope {
    id: root

    property var screen: null
    property var services: null
    property bool dev: false

    readonly property var controller: window.controller
    readonly property bool monitorFocused: window.monitorFocused

    signal opened()

    Connections {
        target: window.controller

        function onIsOpenChanged() {
            if (window.controller.isOpen)
                root.opened();
        }
    }

    CapsuleWindow {
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
