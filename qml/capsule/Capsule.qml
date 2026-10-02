import QtQuick
import QtQuick.Shapes
import ".."

// The one shape, flaring out of the top edge. It sizes itself to the current view and springs between sizes.
Item {
    id: capsule

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
    readonly property bool shrinking: !!loader.item && (loader.item.implicitHeight < height || loader.item.implicitWidth < width)
    readonly property real damping: shrinking ? Theme.springDampingClose : Theme.springDamping
    readonly property real fillet: Math.max(0, Math.min(Theme.fillet, height / 3))

    Behavior on width {
        SpringAnimation {
            spring: Theme.springStiffness
            damping: capsule.damping
            epsilon: 0.4
        }
    }

    Behavior on height {
        SpringAnimation {
            spring: Theme.springStiffness
            damping: capsule.damping
            epsilon: 0.4
        }
    }

    function showView() {
        const url = capsule.viewUrls[capsule.ctl.view] || "views/RestView.qml";
        loader.setSource(url, { ctl: capsule.ctl });
    }

    Connections {
        target: capsule.ctl

        function onViewChanged() { capsule.showView(); }
        function onPeekKindChanged() {
            // A peek replacing another peek keeps the same view, so reload to restart the fade.
            if (capsule.ctl.view === "peek")
                capsule.showView();
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
        enabled: capsule.ctl.isOpen
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            const horizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
            wheel.accepted = horizontal;
            if (wheel.phase === Qt.ScrollBegin)
                capsule.swipeReset();
            if (horizontal)
                capsule.swipe(wheel.angleDelta.x);
        }
    }

    Timer {
        id: swipeIdle

        interval: 250
        onTriggered: capsule.swipeReset()
    }

    Shape {
        width: capsule.width
        height: capsule.height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Theme.hull
            strokeColor: "transparent"
            startX: -capsule.fillet
            startY: 0

            PathLine { x: capsule.width + capsule.fillet; y: 0 }
            PathArc { x: capsule.width; y: capsule.fillet; radiusX: capsule.fillet; radiusY: capsule.fillet; direction: PathArc.Counterclockwise }
            PathLine { x: capsule.width; y: capsule.height - capsule.cornerRadius }
            PathArc { x: capsule.width - capsule.cornerRadius; y: capsule.height; radiusX: capsule.cornerRadius; radiusY: capsule.cornerRadius }
            PathLine { x: capsule.cornerRadius; y: capsule.height }
            PathArc { x: 0; y: capsule.height - capsule.cornerRadius; radiusX: capsule.cornerRadius; radiusY: capsule.cornerRadius }
            PathLine { x: 0; y: capsule.fillet }
            PathArc { x: -capsule.fillet; y: 0; radiusX: capsule.fillet; radiusY: capsule.fillet; direction: PathArc.Counterclockwise }
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
