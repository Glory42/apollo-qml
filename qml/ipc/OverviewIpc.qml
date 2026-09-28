import QtQuick
import Quickshell.Io

// IpcHandler reflects its own properties as IPC-facing and warns if they aren't marshalable, so shellRoot lives on this wrapping QtObject instead.
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
