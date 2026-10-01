import QtQuick

// The one shape. It sizes itself to whatever the current view asks for and morphs between sizes.
Rectangle {
    id: pill

    property var ctl: null

    readonly property var viewUrls: ({
        "rest": "RestView.qml",
        "peek": "PeekView.qml",
        "music": "MusicView.qml",
        "quick": "QuickView.qml",
        "timer": "TimerView.qml",
        "weather": "WeatherView.qml",
        "calendar": "CalendarView.qml",
        "notifications": "NotificationsView.qml",
        "wifi": "WifiView.qml",
        "bt": "BluetoothView.qml"
    })

    width: loader.item ? loader.item.implicitWidth : SurfaceStyle.restWidth
    height: loader.item ? loader.item.implicitHeight : SurfaceStyle.restHeight
    radius: Math.min(height / 2, SurfaceStyle.maxRadius)
    color: SurfaceStyle.pill
    border.width: 1
    border.color: SurfaceStyle.line
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: SurfaceStyle.morphDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: SurfaceStyle.morphCurve
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: SurfaceStyle.morphDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: SurfaceStyle.morphCurve
        }
    }

    function showView() {
        const url = pill.viewUrls[pill.ctl.view] || "RestView.qml";
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

    Component.onCompleted: showView()

    Loader {
        id: loader

        anchors.horizontalCenter: parent.horizontalCenter
        y: 0

        onLoaded: fadeIn.restart()
    }

    SequentialAnimation {
        id: fadeIn

        ScriptAction { script: loader.opacity = 0 }
        PauseAnimation { duration: 100 }
        NumberAnimation {
            target: loader
            property: "opacity"
            to: 1
            duration: SurfaceStyle.fadeDuration
        }
    }
}
