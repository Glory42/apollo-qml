import QtQuick
import Quickshell.Io

// IpcHandler reflects every property declared directly on it as an
// IPC-facing property (and warns loudly at startup if the type isn't
// marshalable, which a plain object reference like shellRoot never is).
// Wrapping it in a QtObject keeps shellRoot off the handler itself --
// only the handler's own functions end up IPC-facing.
QtObject {
    id: wrapper

    required property var shellRoot

    property IpcHandler handler: IpcHandler {
        target: "overview"

        function toggle() {
            wrapper.shellRoot.toggleOverviewAll();
        }

        function open() {
            wrapper.shellRoot.openOverviewAll();
        }

        function close() {
            wrapper.shellRoot.closeOverviewAll();
        }

        function refreshWallpaperCache() {
            wrapper.shellRoot.refreshOverviewWallpaperCaches();
        }
    }
}
