import QtQuick
import QtQuick.Shapes
import ".."
import "IconPaths.js" as IconPaths

// Material Symbols (Rounded, by Google, Apache 2.0) drawn from their SVG paths.
Item {
    id: root

    property string name: ""
    property color color: Theme.fg
    property real size: 18

    width: size
    height: size

    Shape {
        // The paths sit on a 960 unit grid whose y runs from -960 to 0.
        y: root.size
        width: 960
        height: 960
        scale: root.size / 960
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            fillRule: ShapePath.WindingFill

            PathSvg {
                path: IconPaths.paths[root.name] || ""
            }
        }
    }
}
