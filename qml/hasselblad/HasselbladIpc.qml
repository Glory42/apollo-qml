import QtQuick
import Quickshell.Io

// `houston hasselblad <function>`: the menu, a screenshot straight away, recording on or off, the editor, a colour.
QtObject {
    id: wrapper

    required property var hasselblad

    property IpcHandler handler: IpcHandler {
        target: "hasselblad"

        function toggle() { wrapper.hasselblad.toggle(); }
        function open() { wrapper.hasselblad.open("capture"); }
        function close() { wrapper.hasselblad.close(); }
        function screenshot() { wrapper.hasselblad.screenshot(); }
        function record() { wrapper.hasselblad.recordKey(); }
        function edit() { wrapper.hasselblad.edit(); }
        function colour() { wrapper.hasselblad.colour(); }
    }
}
