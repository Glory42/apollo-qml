import QtQuick
import Quickshell.Io

// See OverviewIpc.qml for why shellRoot lives on a wrapping QtObject instead of directly on the IpcHandler.
QtObject {
    id: wrapper

    required property var shellRoot

    property IpcHandler handler: IpcHandler {
        target: "island"

        function show() {
            wrapper.shellRoot.showIslandAll();
        }

        function open() {
            wrapper.shellRoot.showIslandAll();
        }

        function reveal() {
            wrapper.shellRoot.showIslandAll();
        }

        function hide() {
            wrapper.shellRoot.hideIslandAll();
        }

        function toggle() {
            wrapper.shellRoot.toggleIslandAll();
        }

        function enableAutoHide() {
            wrapper.shellRoot.islandAutoHideRuntimeEnabled = true;
            wrapper.shellRoot.refreshIslandAutoHideAll();
        }

        function disableAutoHide() {
            wrapper.shellRoot.islandAutoHideRuntimeEnabled = false;
            wrapper.shellRoot.showIslandAll();
        }
    }
}
