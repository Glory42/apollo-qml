import QtQuick
import "../.."

ViewFrame {
    id: root

    readonly property var weather: ctl ? ctl.weather : null
    readonly property bool ready: weather && weather.hasData

    Text {
        visible: !root.ready
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.weather && root.weather.isError ? root.weather.errorMessage : "Loading weather"
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: 13
    }

    Row {
        visible: root.ready
        width: parent.width
        spacing: 16

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.weather ? root.weather.icon : "cloud"
            size: 40
            color: Theme.fg
        }

        Text {
            id: temp

            anchors.verticalCenter: parent.verticalCenter
            text: root.weather ? Math.round(root.weather.temp) + "\u00b0" : ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 44
            font.weight: Font.Light
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 40 - temp.width - 2 * parent.spacing
            spacing: 2

            Text {
                width: parent.width
                text: root.weather ? root.weather.condition : ""
                elide: Text.ElideRight
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Text {
                width: parent.width
                text: root.weather ? (root.weather.cityName || root.weather.displayLocation) : ""
                elide: Text.ElideRight
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            Text {
                width: parent.width
                text: root.weather ? "Feels like " + root.weather.feelsLikeString : ""
                elide: Text.ElideRight
                color: Theme.dim
                font.family: Theme.fontFamily
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
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: parent.modelData.icon
                    size: 22
                    color: Theme.dim
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(parent.modelData.maxTemp) + "°  " + Math.round(parent.modelData.minTemp) + "°"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
            }
        }
    }
}
