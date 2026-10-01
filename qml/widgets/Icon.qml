import QtQuick
import QtQuick.Shapes
import ".."

// Stroke icon drawn from a 24x24 SVG path, so the pill needs no icon font or asset files.
Item {
    id: root

    property string name: ""
    property color color: Theme.fg
    property real size: 18

    width: size
    height: size

    readonly property var paths: ({
        "play": "M8 5v14l11-7z",
        "pause": "M8.5 5v14M15.5 5v14",
        "prev": "M6 5v14M19 5L9 12l10 7z",
        "next": "M18 5v14M5 5l10 7-10 7z",
        "wifi": "M2.5 9a14 14 0 0 1 19 0M5.5 12.5a9.5 9.5 0 0 1 13 0M8.8 16a5 5 0 0 1 6.4 0M12 19.4v.1",
        "bt": "M7 7l10 10-5 4V3l5 4L7 17",
        "moon": "M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z",
        "volume": "M4 9v6h4l5 4V5L8 9zM16.5 9a4 4 0 0 1 0 6",
        "mute": "M4 9v6h4l5 4V5L8 9zM17 9.5l4 5M21 9.5l-4 5",
        "sun": "M8 12a4 4 0 1 0 8 0a4 4 0 1 0-8 0M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2 2M16.7 16.7l2 2M18.7 5.3l-2 2M7.3 16.7l-2 2",
        "bell": "M6 16v-5a6 6 0 0 1 12 0v5l2 2H4zM10 21h4",
        "timer": "M5 13a7 7 0 1 0 14 0a7 7 0 1 0-14 0M12 9v4l2.5 2M9.5 2.5h5",
        "cloud": "M7 18.5a4 4 0 0 1-.6-7.95A6 6 0 0 1 18 11.5a3.5 3.5 0 0 1-.5 7z",
        "cal": "M6 5h12a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2zM4 10h16M9 3v4M15 3v4",
        "battery": "M5 7h12a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2zM21.5 10.5v3M6.5 10v4",
        "bolt": "M13 3L5 14h6l-1 7 8-11h-6z",
        "music": "M9 18V6l10-2v12M11 18a2 2 0 1 1-4 0a2 2 0 1 1 4 0M19 16a2 2 0 1 1-4 0a2 2 0 1 1 4 0",
        "sliders": "M4 8h9M17 8h3M4 16h3M11 16h9M13 8a2 2 0 1 0 4 0a2 2 0 1 0-4 0M7 16a2 2 0 1 0 4 0a2 2 0 1 0-4 0",
        "power": "M12 3v8M6.5 6.5a8 8 0 1 0 11 0",
        "chevron": "M9 6l6 6-6 6"
    })

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: 1.6
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: root.paths[root.name] || ""
            }
        }
    }
}
