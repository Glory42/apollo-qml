import QtQuick
import Quickshell
import ".."

// Clipboard history in an orbiter: search and list on the left, the highlighted entry in full on the right.
Scope {
    id: root

    property var clipboard: null
    property string onlyScreen: ""
    readonly property bool isOpen: win.open

    readonly property int rowHeight: 40
    readonly property int maxRows: 100
    // Empty while Logbook is away, so no row or picture is held for a window nobody sees.
    // A search makes no lowercased copy of the history and stops at the last row it can show; the history can hold megabytes.
    readonly property var rows: {
        if (!win.shown)
            return [];
        const all = root.clipboard ? root.clipboard.history : [];
        const query = field.text.trim();
        if (query === "")
            return all.slice(0, root.maxRows);
        const pattern = new RegExp(query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
        const found = [];
        for (let i = 0; i < all.length && found.length < root.maxRows; i++) {
            if (pattern.test(root.label(all[i])))
                found.push(all[i]);
        }
        return found;
    }
    readonly property var current: rows[list.currentIndex] || null

    signal opened()

    function label(entry) {
        if (entry.type === "image")
            return "Image from " + Qt.formatDateTime(new Date(entry.at), "dddd HH:mm");
        return entry.text;
    }

    function open() {
        if (win.open)
            return;
        field.text = "";
        win.show();
        list.currentIndex = 0;
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

    function choose(entry, paste) {
        if (!entry)
            return;
        close();
        root.clipboard.put(entry, paste);
    }

    OrbiterWindow {
        id: win

        piece: "logbook"
        onlyScreen: root.onlyScreen
        onDismissed: root.close()
        onOpenChanged: if (open) field.forceActiveFocus()

        Row {
            padding: 14
            spacing: 14

            Column {
                id: left

                width: 340
                spacing: 8

                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 20
                    color: Theme.fill

                    Text {
                        anchors.fill: field
                        verticalAlignment: Text.AlignVCenter
                        visible: field.text === ""
                        text: "Search clipboard"
                        color: Theme.faint
                        font: field.font
                    }

                    TextInput {
                        id: field

                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        focus: true
                        color: Theme.fg
                        selectionColor: Theme.fill2
                        selectedTextColor: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 13

                        onTextEdited: list.currentIndex = 0

                        Keys.onPressed: (event) => {
                            const shift = event.modifiers & Qt.ShiftModifier;
                            if (event.key === Qt.Key_Escape)
                                root.close();
                            else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab)
                                list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1);
                            else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab)
                                list.currentIndex = Math.max(list.currentIndex - 1, 0);
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                root.choose(root.current, !shift);
                            else if (event.key === Qt.Key_Delete && shift && root.current)
                                root.clipboard.remove(root.current);
                            else
                                return;
                            event.accepted = true;
                        }
                    }
                }

                ListView {
                    id: list

                    width: parent.width
                    height: 9 * root.rowHeight
                    clip: true
                    model: ScriptModel {
                        values: root.rows
                    }
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0

                    delegate: Rectangle {
                        id: row

                        required property var modelData
                        required property int index

                        readonly property bool image: modelData.type === "image"

                        width: list.width
                        height: root.rowHeight
                        radius: 14
                        color: list.currentIndex === row.index ? Theme.fill2 : "transparent"

                        Image {
                            id: thumb

                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.image
                            width: row.image ? 32 : 0
                            height: 22
                            source: row.image ? "file://" + row.modelData.path : ""
                            sourceSize.width: 64
                            sourceSize.height: 44
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Text {
                            anchors.left: thumb.right
                            anchors.leftMargin: row.image ? 10 : 0
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.label(row.modelData).slice(0, 200).replace(/\s+/g, " ").trim()
                            elide: Text.ElideRight
                            color: list.currentIndex === row.index ? Theme.fg : Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: list.currentIndex = row.index
                            onClicked: root.choose(row.modelData, true)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        text: field.text === "" ? "Nothing copied yet" : "No matches"
                        color: Theme.faint
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                }
            }

            Rectangle {
                width: 380
                height: left.height
                radius: 18
                color: Theme.fill
                clip: true

                Text {
                    anchors.fill: parent
                    anchors.margins: 16
                    visible: !!root.current && root.current.type === "text"
                    text: root.current && root.current.type === "text" ? root.current.text.slice(0, 4000) : ""
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    lineHeight: 1.3
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 12
                    visible: !!root.current && root.current.type === "image"
                    source: root.current && root.current.type === "image" ? "file://" + root.current.path : ""
                    // Decoded at twice the panel, not at the size of the screenshot.
                    sourceSize.width: 2 * width
                    sourceSize.height: 2 * height
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
            }
        }
    }
}
