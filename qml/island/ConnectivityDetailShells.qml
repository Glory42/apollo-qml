import QtQuick
import "../connectivity"

Item {
    id: shells

    property var root: null
    property var mainCapsule: null
    property var provider: null

    readonly property alias wifiShell: wifiConnectivityDetailShell
    readonly property alias bluetoothShell: bluetoothConnectivityDetailShell
    readonly property alias powerShell: powerConnectivityDetailShell

    ConnectivityDetailShell {
        id: wifiConnectivityDetailShell

        open: shells.root.wifiConnectivityDetailOpen
        mounted: shells.root.wifiConnectivityDetailMounted
        rightSide: false
        panelKind: "wifi"
        provider: shells.provider
        mainCapsule: shells.mainCapsule
        availableWidth: shells.root.width
        detailWidth: shells.root.connectivityDetailWidth
        detailHeight: shells.root.connectivityDetailHeight
        detailGap: shells.root.connectivityDetailGap
        iconFontFamily: shells.root.iconFontFamily
        textFontFamily: shells.root.textFontFamily
        heroFontFamily: shells.root.heroFontFamily
    }

    ConnectivityDetailShell {
        id: bluetoothConnectivityDetailShell

        open: shells.root.bluetoothConnectivityDetailOpen
        mounted: shells.root.bluetoothConnectivityDetailMounted
        rightSide: true
        panelKind: "bluetooth"
        provider: shells.provider
        mainCapsule: shells.mainCapsule
        availableWidth: shells.root.width
        detailWidth: shells.root.connectivityDetailWidth
        detailHeight: shells.root.connectivityDetailHeight
        detailGap: shells.root.connectivityDetailGap
        iconFontFamily: shells.root.iconFontFamily
        textFontFamily: shells.root.textFontFamily
        heroFontFamily: shells.root.heroFontFamily
    }

    ConnectivityDetailShell {
        id: powerConnectivityDetailShell

        open: shells.root.powerConnectivityDetailOpen
        mounted: shells.root.powerConnectivityDetailMounted
        rightSide: true
        panelKind: "power"
        provider: shells.provider
        mainCapsule: shells.mainCapsule
        availableWidth: shells.root.width
        detailWidth: 260
        detailHeight: 88
        detailGap: shells.root.connectivityDetailGap
        iconFontFamily: shells.root.iconFontFamily
        textFontFamily: shells.root.textFontFamily
        heroFontFamily: shells.root.heroFontFamily
    }
}
