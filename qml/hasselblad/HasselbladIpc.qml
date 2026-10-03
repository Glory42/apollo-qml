import QtQuick
import Quickshell.Io
import ".."

// `houston hasselblad <function>`: the menu, a screenshot straight away, recording on or off, the editor, a colour.
// For a keybind, also `apollo:hasselblad-toggle`, `apollo:hasselblad-screenshot`, `apollo:hasselblad-record`, `apollo:hasselblad-edit`, `apollo:hasselblad-colour`.
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

    property Keybind toggle: Keybind {
        name: "hasselblad-toggle"
        onPressed: wrapper.hasselblad.toggle()
    }

    property Keybind screenshot: Keybind {
        name: "hasselblad-screenshot"
        onPressed: wrapper.hasselblad.screenshot()
    }

    property Keybind record: Keybind {
        name: "hasselblad-record"
        onPressed: wrapper.hasselblad.recordKey()
    }

    property Keybind edit: Keybind {
        name: "hasselblad-edit"
        onPressed: wrapper.hasselblad.edit()
    }

    property Keybind colour: Keybind {
        name: "hasselblad-colour"
        onPressed: wrapper.hasselblad.colour()
    }
}
