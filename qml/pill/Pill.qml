import QtQuick
import QtQuick.Shapes
import ".."

// The one shape, flaring out of the top edge. It sizes itself to the current view and springs between sizes.
Item {
    id: pill

    property var ctl: null
    property real swipeSum: 0
    property bool swipeLocked: false

    readonly property var viewUrls: ({
        "rest": "views/RestView.qml",
        "peek": "views/PeekView.qml",
        "music": "views/MusicView.qml",
        "quick": "views/QuickView.qml",
        "timer": "views/TimerView.qml",
        "weather": "views/WeatherView.qml",
        "calendar": "views/CalendarView.qml",
        "notifications": "views/NotificationsView.qml",
        "wifi": "views/WifiView.qml",
        "bt": "views/BluetoothView.qml"
    })

    width: loader.item ? loader.item.implicitWidth : Theme.restWidth
    height: loader.item ? loader.item.implicitHeight : Theme.restHeight
    readonly property real cornerRadius: Math.min(height / 2, Theme.maxRadius)
    readonly property real fillet: Math.max(0, Math.min(Theme.fillet, height / 3))

    Behavior on width {
        SpringAnimation {
            spring: Theme.springStiffness
            damping: Theme.springDamping
            epsilon: 0.4
        }
    }

    Behavior on height {
        SpringAnimation {
            spring: Theme.springStiffness
            damping: Theme.springDamping
            epsilon: 0.4
        }
    }

    function showView() {
        const url = pill.viewUrls[pill.ctl.view] || "views/RestView.qml";
        loader.setSource(url, { ctl: pill.ctl });
    }

    Connections {
        target: pill.ctl

        function onViewChanged() { pill.showView(); }
        function onPeekKindChanged() {
            // A peek replacing another peek keeps the same view, so reload to restart the fade.
            if (pill.ctl.view === "peek")
                pill.showView();
        }
    }

    function swipeReset() {
        swipeSum = 0;
        swipeLocked = false;
    }

    function swipe(dx) {
        swipeIdle.restart();
        if (swipeLocked)
            return;
        swipeSum += dx;
        if (Math.abs(swipeSum) < 250)
            return;
        swipeLocked = true;
        // Fingers moving left give a negative delta and go to the next tab.
        ctl.step((swipeSum < 0) !== Config.swipeReverse ? 1 : -1);
        swipeSum = 0;
    }

    Component.onCompleted: showView()

    MouseArea {
        anchors.fill: parent
        z: 1000
        enabled: pill.ctl.isOpen
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            const horizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
            wheel.accepted = horizontal;
            if (wheel.phase === Qt.ScrollBegin)
                pill.swipeReset();
            if (horizontal)
                pill.swipe(wheel.angleDelta.x);
        }
    }

    Timer {
        id: swipeIdle

        interval: 250
        onTriggered: pill.swipeReset()
    }

    Shape {
        width: pill.width
        height: pill.height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Theme.pill
            strokeColor: "transparent"
            startX: -pill.fillet
            startY: 0

            PathLine { x: pill.width + pill.fillet; y: 0 }
            PathArc { x: pill.width; y: pill.fillet; radiusX: pill.fillet; radiusY: pill.fillet; direction: PathArc.Counterclockwise }
            PathLine { x: pill.width; y: pill.height - pill.cornerRadius }
            PathArc { x: pill.width - pill.cornerRadius; y: pill.height; radiusX: pill.cornerRadius; radiusY: pill.cornerRadius }
            PathLine { x: pill.cornerRadius; y: pill.height }
            PathArc { x: 0; y: pill.height - pill.cornerRadius; radiusX: pill.cornerRadius; radiusY: pill.cornerRadius }
            PathLine { x: 0; y: pill.fillet }
            PathArc { x: -pill.fillet; y: 0; radiusX: pill.fillet; radiusY: pill.fillet; direction: PathArc.Counterclockwise }
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Loader {
            id: loader

            anchors.horizontalCenter: parent.horizontalCenter
            y: 0

            onLoaded: fadeIn.restart()
        }
    }

    SequentialAnimation {
        id: fadeIn

        ScriptAction { script: loader.opacity = 0 }
        PauseAnimation { duration: 100 }
        NumberAnimation {
            target: loader
            property: "opacity"
            to: 1
            duration: Theme.fadeDuration
        }
    }
}
