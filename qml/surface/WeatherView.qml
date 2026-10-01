import QtQuick

ViewFrame {
    id: root

    readonly property var weather: ctl ? ctl.weather : null
    readonly property bool ready: weather && weather.hasData

    Text {
        visible: !root.ready
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.weather && root.weather.isError ? root.weather.errorMessage : "Loading weather"
        color: SurfaceStyle.dim
        font.family: SurfaceStyle.fontFamily
        font.pixelSize: 13
    }

    Row {
        visible: root.ready
        width: parent.width
        spacing: 16

        Text {
            id: temp

            anchors.verticalCenter: parent.verticalCenter
            text: root.weather ? Math.round(root.weather.temp) + "\u00b0" : ""
            color: SurfaceStyle.fg
            font.family: SurfaceStyle.fontFamily
            font.pixelSize: 44
            font.weight: Font.Light
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - temp.width - parent.spacing
            spacing: 2

            Text {
                width: parent.width
                text: root.weather ? root.weather.condition : ""
                elide: Text.ElideRight
                color: SurfaceStyle.fg
                font.family: SurfaceStyle.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Text {
                width: parent.width
                text: root.weather ? (root.weather.cityName || root.weather.displayLocation) : ""
                elide: Text.ElideRight
                color: SurfaceStyle.dim
                font.family: SurfaceStyle.fontFamily
                font.pixelSize: 12
            }

            Text {
                width: parent.width
                text: root.weather ? "Feels like " + root.weather.feelsLikeString : ""
                elide: Text.ElideRight
                color: SurfaceStyle.dim
                font.family: SurfaceStyle.fontFamily
                font.pixelSize: 12
            }
        }
    }

    Row {
        visible: root.ready
        width: parent.width

        Repeater {
            model: root.weather ? root.weather.forecast : []

            Column {
                required property var modelData

                width: parent.width / Math.max(1, root.weather.forecast.length)
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.modelData.dayLabel
                    color: SurfaceStyle.dim
                    font.family: SurfaceStyle.fontFamily
                    font.pixelSize: 12
                }

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "cloud"
                    color: SurfaceStyle.dim
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(parent.modelData.maxTemp) + "°  " + Math.round(parent.modelData.minTemp) + "°"
                    color: SurfaceStyle.fg
                    font.family: SurfaceStyle.fontFamily
                    font.pixelSize: 12
                }
            }
        }
    }
}
