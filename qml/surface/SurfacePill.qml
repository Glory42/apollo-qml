import QtQuick
import ".."

// The one shape. It sizes itself to whatever the current view asks for and morphs between sizes.
Rectangle {
    id: pill

    property var ctl: null

    readonly property var viewUrls: ({
        "rest": "../views/RestView.qml",
        "peek": "../views/PeekView.qml",
        "music": "../views/MusicView.qml",
        "quick": "../views/QuickView.qml",
        "timer": "../views/TimerView.qml",
        "weather": "../views/WeatherView.qml",
        "calendar": "../views/CalendarView.qml",
        "notifications": "../views/NotificationsView.qml",
        "wifi": "../views/WifiView.qml",
        "bt": "../views/BluetoothView.qml"
    })

    width: loader.item ? loader.item.implicitWidth : Theme.restWidth
    height: loader.item ? loader.item.implicitHeight : Theme.restHeight
    radius: Math.min(height / 2, Theme.maxRadius)
    color: Theme.pill
    border.width: 1
    border.color: Theme.line
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: Theme.morphDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.morphCurve
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Theme.morphDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.morphCurve
        }
    }

    function showView() {
        const url = pill.viewUrls[pill.ctl.view] || "../views/RestView.qml";
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
            duration: Theme.fadeDuration
        }
    }
}
