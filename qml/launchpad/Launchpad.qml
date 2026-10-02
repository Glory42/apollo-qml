import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import ".."

// Finds and starts applications, in a lander; the ones started most often rank first.
Scope {
    id: root

    property string onlyScreen: ""
    readonly property bool isOpen: win.open

    readonly property int rowHeight: 44
    readonly property int maxRows: 7

    property var counts: ({})
    // { entry, name, words, extra }: what a search compares against, lowercased once per application.
    property var index: []
    property var results: []

    signal opened()

    function open() {
        if (win.open)
            return;
        field.text = "";
        refresh();
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

    // 0 means no match; a name that starts with the query beats a word that does, which beats the rest.
    function score(item, query) {
        if (item.name.startsWith(query))
            return 4;
        if (item.words.some((word) => word.startsWith(query)))
            return 3;
        if (item.name.includes(query))
            return 2;
        return item.extra.includes(query) ? 1 : 0;
    }

    function reindex() {
        const built = [];
        for (const entry of DesktopEntries.applications.values) {
            if (entry.noDisplay)
                continue;
            const name = entry.name.toLowerCase();
            built.push({
                entry: entry,
                name: name,
                words: name.split(/[\s\-_.]+/),
                extra: [entry.genericName, entry.comment].concat(entry.keywords).join(" ").toLowerCase()
            });
        }
        root.index = built;
        refresh();
    }

    function refresh() {
        const query = field.text.trim().toLowerCase();
        const found = [];
        for (const item of root.index) {
            const rank = query === "" ? 1 : score(item, query);
            if (rank > 0)
                found.push({ entry: item.entry, rank: rank, count: root.counts[item.entry.id] || 0 });
        }
        found.sort((a, b) => b.rank - a.rank || b.count - a.count || a.entry.name.localeCompare(b.entry.name));
        root.results = found.slice(0, 50).map((item) => item.entry);
        list.currentIndex = 0;
    }

    function launch(index) {
        const entry = root.results[index];
        if (!entry)
            return;
        close();
        const next = Object.assign({}, root.counts);
        next[entry.id] = (next[entry.id] || 0) + 1;
        root.counts = next;
        store.setText(JSON.stringify(next));
        entry.execute();
    }

    // The application list is read on first use and again when something is installed or removed.
    Connections {
        target: DesktopEntries.applications

        function onValuesChanged() { root.reindex(); }
    }

    Component.onCompleted: reindex()

    FileView {
        id: store

        path: Quickshell.statePath("launchpad.json")
        printErrors: false
        onLoaded: {
            try {
                root.counts = JSON.parse(store.text());
            } catch (error) {
                root.counts = {};
            }
        }
    }

    LanderWindow {
        id: win

        piece: "launchpad"
        maxContentHeight: 72 + root.maxRows * root.rowHeight
        onlyScreen: root.onlyScreen
        onDismissed: root.close()
        onOpenChanged: if (open) field.forceActiveFocus()

        Column {
            padding: 12
            spacing: 8

            Rectangle {
                width: 396
                height: 40
                radius: 20
                color: Theme.fill

                Text {
                    anchors.fill: field
                    verticalAlignment: Text.AlignVCenter
                    visible: field.text === ""
                    text: "Search applications"
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

                    onTextEdited: root.refresh()
                    onAccepted: root.launch(list.currentIndex)

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape)
                            root.close();
                        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab)
                            list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1);
                        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab)
                            list.currentIndex = Math.max(list.currentIndex - 1, 0);
                        else
                            return;
                        event.accepted = true;
                    }
                }
            }

            ListView {
                id: list

                width: 396
                height: Math.min(count, root.maxRows) * root.rowHeight
                clip: true
                // Keeps the rows of applications that are still listed instead of rebuilding them all.
                model: ScriptModel {
                    values: root.results
                }
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    width: list.width
                    height: root.rowHeight
                    radius: 14
                    color: list.currentIndex === row.index ? Theme.fill2 : "transparent"

                    IconImage {
                        id: glyph

                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 24
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                    }

                    Text {
                        anchors.left: glyph.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.name
                        elide: Text.ElideRight
                        color: list.currentIndex === row.index ? Theme.fg : Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: list.currentIndex = row.index
                        onClicked: root.launch(row.index)
                    }
                }
            }
        }
    }
}
