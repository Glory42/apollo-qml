import QtQuick
import Quickshell.Io
import Quickshell.Widgets
import "../common"
import "WallpaperConfig.js" as WallpaperConfig

FocusScope {
    id: root

    signal closeRequested
    signal wallpaperApplied(string filePath)
    signal wallpaperApplySucceeded(string filePath)

    property bool showCondition: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    readonly property var userConfig: UserConfig

    property bool pywalEnabled: userConfig.wallpaperPywalEnabled
    property bool customCommandEnabled: userConfig.wallpaperCustomCommandEnabled === true
    property string customCommand: userConfig.wallpaperCustomCommand === undefined || userConfig.wallpaperCustomCommand === null ? "" : String(userConfig.wallpaperCustomCommand)
    property int transitionFps: WallpaperConfig.boundedInt(userConfig.wallpaperTransitionFps, 60, 1, 240)
    property int transitionStep: WallpaperConfig.boundedInt(userConfig.wallpaperTransitionStep, 5, 1, 255)
    property real transitionDuration: WallpaperConfig.boundedReal(userConfig.wallpaperTransitionDuration, 3.0, 0, 120)
    property int transitionAngle: WallpaperConfig.boundedInt(userConfig.wallpaperTransitionAngle, 45, 0, 360)
    property string transitionPosition: WallpaperConfig.nonEmptyString(userConfig.wallpaperTransitionPosition, "center")
    property string transitionBezier: WallpaperConfig.nonEmptyString(userConfig.wallpaperTransitionBezier, ".54,0,.34,.99")
    property string transitionWave: WallpaperConfig.nonEmptyString(userConfig.wallpaperTransitionWave, "20,20")
    property bool transitionInvertY: userConfig.wallpaperTransitionInvertY
    property string wallpaperDir: userConfig.wallpaperLibraryPath
    property string targetWallpaperPath: userConfig.wallpaperPath

    property bool wallpapersLoaded: false
    property string activeWallpaper: ""
    property string latestAppliedWallpaper: ""
    property bool acceptingScanResults: false
    property bool closeAfterApply: false
    property bool releasingResources: false
    property var wallpaperIndexByPath: ({})

    property string searchQuery: ""
    property var filteredIndexByPath: ({})

    ListModel {
        id: filteredWallpapers
    }

    function matchesSearch(fileName) {
        if (root.searchQuery === "")
            return true;
        return fileName.toLowerCase().indexOf(root.searchQuery.toLowerCase()) >= 0;
    }

    function rebuildFilteredWallpapers() {
        filteredWallpapers.clear();
        filteredIndexByPath = ({});
        for (let i = 0; i < allWallpapers.count; i++) {
            const item = allWallpapers.get(i);
            if (matchesSearch(item.fileName)) {
                filteredIndexByPath[item.filePath] = filteredWallpapers.count;
                filteredWallpapers.append(item);
            }
        }
        syncCurrentIndex();
    }

    function syncFilteredEntry(filePath) {
        const sourceIndex = wallpaperIndexByPath[filePath];
        if (sourceIndex === undefined)
            return;
        const item = allWallpapers.get(sourceIndex);
        const matches = matchesSearch(item.fileName);
        const existingIndex = filteredIndexByPath[filePath];

        if (matches) {
            if (existingIndex === undefined) {
                filteredIndexByPath[filePath] = filteredWallpapers.count;
                filteredWallpapers.append(item);
            } else {
                filteredWallpapers.set(existingIndex, item);
            }
        } else if (existingIndex !== undefined) {
            filteredWallpapers.remove(existingIndex);
            delete filteredIndexByPath[filePath];
            for (const path in filteredIndexByPath) {
                if (filteredIndexByPath[path] > existingIndex)
                    filteredIndexByPath[path]--;
            }
        }
    }

    onSearchQueryChanged: rebuildFilteredWallpapers()

    readonly property string effectiveActiveWallpaper: latestAppliedWallpaper !== "" ? latestAppliedWallpaper : activeWallpaper
    readonly property string scanScriptPath: Qt.resolvedUrl("scripts/scan_wallpapers.py").toString().replace("file://", "")
    readonly property string applyScriptPath: Qt.resolvedUrl("scripts/apply_wallpaper.py").toString().replace("file://", "")

    readonly property var transitionTypes: ["none", "simple", "fade", "left", "right", "top", "bottom", "wipe", "wave", "grow", "center", "any", "outer", "random"]
    readonly property string configuredTransitionType: WallpaperConfig.validTransitionType(userConfig.wallpaperTransitionType, transitionTypes)

    focus: showCondition
    activeFocusOnTab: true
    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 240 : 120
            easing.type: Easing.InOutQuad
        }
    }

    onShowConditionChanged: {
        if (showCondition) {
            if (!wallpapersLoaded)
                startScan();
            else
                syncCurrentIndex();
            root.grabKeyboardFocus();
        } else {
            releaseResources();
        }
    }

    Component.onDestruction: releaseResources()

    function startScan() {
        releasingResources = false;
        acceptingScanResults = true;
        wallpapersLoaded = false;
        wallpaperIndexByPath = ({});
        allWallpapers.clear();
        filteredWallpapers.clear();
        filteredIndexByPath = ({});
        if (scanProcess.running)
            scanProcess.running = false;
        scanProcess.running = true;
    }

    function releaseResources() {
        if (releasingResources)
            return;
        releasingResources = true;
        acceptingScanResults = false;
        closeAfterApply = false;
        if (scanProcess.running)
            scanProcess.running = false;
        if (applyProcess.running)
            applyProcess.running = false;
        if (customApplyProcess.running)
            customApplyProcess.running = false;
        wallpapersLoaded = false;
        wallpaperIndexByPath = ({});
        allWallpapers.clear();
        filteredWallpapers.clear();
        filteredIndexByPath = ({});
        releasingResources = false;
    }

    function toFileUrl(localFile) {
        return localFile === "" ? "" : ("file://" + encodeURI(localFile));
    }

    function displayPath(path) {
        return path === "" ? "wallpaperLibraryPath" : path;
    }

    function upsertWallpaper(record) {
        if (!record || !record.filePath)
            return;

        const filePath = String(record.filePath);
        const existingIndex = wallpaperIndexByPath[filePath];
        const modelItem = {
            filePath: filePath,
            fileName: String(record.fileName || filePath),
            thumbnailSource: toFileUrl(filePath),
            thumbnailReady: true,
            thumbnailRequested: true
        };

        if (existingIndex === undefined) {
            wallpaperIndexByPath[filePath] = allWallpapers.count;
            allWallpapers.append(modelItem);
        } else {
            allWallpapers.set(existingIndex, modelItem);
        }

        syncFilteredEntry(filePath);
    }

    function syncCurrentIndex() {
        if (root.effectiveActiveWallpaper === "")
            return;
        for (let i = 0; i < filteredWallpapers.count; i++) {
            if (filteredWallpapers.get(i).filePath === root.effectiveActiveWallpaper) {
                pathView.currentIndex = i;
                return;
            }
        }
    }

    function grabKeyboardFocus() {
        root.focus = true;
        root.forceActiveFocus();
    }

    function focusSearch() {
        searchBar.expanded = true;
        searchInput.forceActiveFocus();
    }

    function moveNext() {
        pathView.incrementCurrentIndex();
    }

    function movePrevious() {
        pathView.decrementCurrentIndex();
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            root.closeRequested();
            event.accepted = true;
            break;
        case Qt.Key_Slash:
            root.focusSearch();
            event.accepted = true;
            break;
        case Qt.Key_Right:
        case Qt.Key_L:
        case Qt.Key_Tab:
            root.moveNext();
            event.accepted = true;
            break;
        case Qt.Key_Left:
        case Qt.Key_H:
        case Qt.Key_Backtab:
            root.movePrevious();
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (filteredWallpapers.count > 0)
                root.applyWallpaper(filteredWallpapers.get(pathView.currentIndex).filePath);
            event.accepted = true;
            break;
        }
    }

    ListModel {
        id: allWallpapers
    }

    function applyWallpaper(filePath) {
        const targetPath = root.targetWallpaperPath;
        const commandText = root.customCommand.trim();
        const useCustomCommand = root.customCommandEnabled && commandText.length > 0;
        if (filePath === "")
            return;
        latestAppliedWallpaper = filePath;
        wallpaperApplied(filePath);
        closeAfterApply = true;
        if (applyProcess.running)
            applyProcess.running = false;
        if (customApplyProcess.running)
            customApplyProcess.running = false;
        if (useCustomCommand) {
            customApplyProcess.wallpaperPath = filePath;
            customApplyProcess.targetPath = targetPath;
            customApplyProcess.commandText = root.customCommand;
            customApplyProcess.running = true;
            return;
        }
        applyProcess.wallpaperPath = filePath;
        applyProcess.targetPath = targetPath;
        applyProcess.transitionType = configuredTransitionType;
        applyProcess.running = true;
    }

    Process {
        id: scanProcess
        command: ["python3", root.scanScriptPath, root.wallpaperDir]
        stdout: SplitParser {
            onRead: data => {
                if (!root.acceptingScanResults)
                    return;
                try {
                    root.upsertWallpaper(JSON.parse(data));
                } catch (error) {
                }
            }
        }
        onExited: {
            if (!root.acceptingScanResults)
                return;
            root.acceptingScanResults = false;
            root.wallpapersLoaded = true;
            root.syncCurrentIndex();
        }
    }

    Process {
        id: applyProcess
        property string wallpaperPath: ""
        property string targetPath: ""
        property string transitionType: "center"
        command: [
            "python3", root.applyScriptPath,
            wallpaperPath,
            targetPath,
            transitionType,
            String(root.transitionStep),
            String(root.transitionDuration),
            String(root.transitionFps),
            String(root.transitionAngle),
            root.transitionPosition,
            root.transitionBezier,
            root.transitionWave,
            root.transitionInvertY ? "true" : "false",
            root.pywalEnabled ? "true" : "false"
        ]
        onExited: function(exitCode) {
            running = false;
            if (exitCode === 0)
                root.wallpaperApplySucceeded(wallpaperPath);
            if (root.closeAfterApply) {
                root.closeAfterApply = false;
                root.closeRequested();
            }
        }
    }

    Process {
        id: customApplyProcess
        property string wallpaperPath: ""
        property string targetPath: ""
        property string commandText: ""
        command: [
            "bash", "-c", commandText,
            "tide-island-wallpaper",
            wallpaperPath,
            targetPath
        ]
        onExited: function(exitCode) {
            running = false;
            if (exitCode === 0)
                root.wallpaperApplySucceeded(wallpaperPath);
            if (root.closeAfterApply) {
                root.closeAfterApply = false;
                root.closeRequested();
            }
        }
    }

    readonly property real topPad: 14
    readonly property real botPad: 8
    readonly property real hPad: 12
    readonly property real headerH: 34
    readonly property real headerGap: 6
    readonly property real labelH: 22
    readonly property real labelGap: 5

    readonly property real cardW: Math.round(slotW * 1.15)
    readonly property real cardH: Math.round(cardW * 0.58)
    readonly property real spacing: slotW * 1.20

    readonly property real sideScale: 0.78

    readonly property real slotW: (width - hPad * 2) / 5

    readonly property real cardAreaH: height - topPad - headerH - headerGap - botPad
    readonly property real cardPathY: cardAreaH / 2

    // ── UI ────────────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.topMargin: root.topPad
        anchors.leftMargin: root.hPad
        anchors.rightMargin: root.hPad
        anchors.bottomMargin: root.botPad
        spacing: 6

        // ── Search bar (collapsible) ──────────────────────────────────────
        Item {
            id: searchBar
            property bool expanded: false

            width: parent.width
            height: 34

            Rectangle {
                id: searchBg
                width: searchBar.expanded ? parent.width : 34
                height: 34
                anchors.right: parent.right
                radius: 10
                color: Qt.rgba(1, 1, 1, searchBar.expanded ? 0.06 : (iconMouse.containsMouse ? 0.10 : 0.06))
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: "#60a5fa"

                Behavior on width {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Rectangle {
                id: iconButton
                width: 34
                height: 34
                anchors.right: parent.right
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf002"
                    font.family: root.iconFontFamily
                    font.pixelSize: 12
                    color: Qt.rgba(1, 1, 1, searchBar.expanded ? 0.55 : 0.35)
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !searchBar.expanded
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusSearch()
                }
            }

            TextInput {
                id: searchInput
                visible: searchBar.expanded
                anchors.left: searchBg.left
                anchors.right: clearButton.visible ? clearButton.left : iconButton.left
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                font.pixelSize: 12
                font.family: root.textFontFamily
                clip: true
                selectByMouse: true
                onTextChanged: root.searchQuery = text

                onActiveFocusChanged: {
                    if (!activeFocus && text === "")
                        searchBar.expanded = false;
                }

                Keys.onEscapePressed: {
                    if (text !== "")
                        text = "";
                    else
                        searchBar.expanded = false;
                }
            }

            Text {
                visible: searchBar.expanded && searchInput.text === ""
                text: "Search wallpapers…"
                font.pixelSize: 12
                font.family: root.textFontFamily
                color: Qt.rgba(1, 1, 1, 0.28)
                anchors.left: searchInput.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: clearButton
                visible: searchBar.expanded && searchInput.text !== ""
                width: 20
                height: 20
                radius: 10
                color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                anchors.right: iconButton.left
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d"
                    font.family: root.iconFontFamily
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.5)
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: searchInput.text = ""
                }
            }
        }

        // ── Carousel ───────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: root.cardAreaH

            // Empty state
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: !root.wallpapersLoaded || filteredWallpapers.count === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: !root.wallpapersLoaded ? "Scanning…" : "\uf03e"
                    font.pixelSize: !root.wallpapersLoaded ? 12 : 26
                    font.family: !root.wallpapersLoaded ? root.textFontFamily : root.iconFontFamily
                    color: Qt.rgba(1, 1, 1, 0.22)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.wallpapersLoaded && filteredWallpapers.count === 0
                    text: allWallpapers.count === 0 ? ("No wallpapers found\nin " + root.displayPath(root.wallpaperDir)) : ("No wallpapers match \"" + root.searchQuery + "\"")
                    horizontalAlignment: Text.AlignHCenter
                    color: Qt.rgba(1, 1, 1, 0.22)
                    font.pixelSize: 11
                    font.family: root.textFontFamily
                    lineHeight: 1.5
                }
            }

            PathView {
                id: pathView
                anchors.fill: parent
                model: root.showCondition ? filteredWallpapers : null
                visible: filteredWallpapers.count > 0
                clip: false

                pathItemCount: Math.min(filteredWallpapers.count, 5)
                cacheItemCount: 4
                snapMode: PathView.SnapToItem
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                highlightMoveDuration: 200

                path: Path {
                    startX: pathView.width / 2 - root.spacing * 2
                    startY: root.cardPathY
                    PathLine {
                        x: pathView.width / 2 + root.spacing * 2
                        y: root.cardPathY
                    }
                }

                delegate: Item {
                    id: del
                    readonly property bool isCurrent: PathView.isCurrentItem
                    readonly property bool onPath: PathView.onPath

                    width: root.cardW
                    height: root.cardH + root.labelGap + root.labelH
                    z: isCurrent ? 3 : 1

                    property real sc: isCurrent ? 1.0 : onPath ? root.sideScale : 0.0
                    Behavior on sc {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    property real op: isCurrent ? 1.0 : onPath ? 0.65 : 0.0
                    Behavior on op {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }

                    Item {
                        id: inner
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        width: root.cardW
                        height: root.cardH + root.labelGap + root.labelH
                        scale: del.sc
                        opacity: del.op
                        transformOrigin: Item.Center

                        // Clipped image
                        ClippingRectangle {
                            id: thumb
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: root.cardW
                            height: root.cardH
                            radius: 14
                            color: "#1a1a1a"
                            antialiasing: false

                            Image {
                                anchors.fill: parent
                                source: root.showCondition && model.thumbnailSource ? model.thumbnailSource : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                smooth: true
                                mipmap: false
                                sourceSize: Qt.size(root.cardW * 2, root.cardH * 2)

                                Rectangle {
                                    anchors.fill: parent
                                    color: "#282828"
                                    opacity: parent.status === Image.Ready ? 0 : 1
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                        }

                        // Border overlay
                        Rectangle {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: root.cardW
                            height: root.cardH
                            radius: 14
                            color: "transparent"
                            border.width: (model.filePath === root.effectiveActiveWallpaper) ? 2.5 : 0
                            border.color: "#60a5fa"
                            Behavior on border.width {
                                NumberAnimation {
                                    duration: 150
                                }
                            }

                        }

                        // Click area
                        MouseArea {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: root.cardW
                            height: root.cardH
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (del.isCurrent)
                                    root.applyWallpaper(model.filePath);
                                else
                                    pathView.currentIndex = index;
                            }
                        }

                        // Filename label
                        Text {
                            anchors.top: thumb.bottom
                            anchors.topMargin: root.labelGap
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: root.cardW - 4
                            text: model.fileName
                            color: del.isCurrent ? "white" : Qt.rgba(1, 1, 1, 0.50)
                            font.pixelSize: del.isCurrent ? 11 : 10
                            font.family: root.textFontFamily
                            font.weight: del.isCurrent ? Font.Medium : Font.Normal
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideMiddle
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
