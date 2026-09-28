pragma Singleton

import QtQuick

QtObject {
    readonly property string iconFontFamily: "JetBrainsMono Nerd Font"
    readonly property string textFontFamily: "JetBrainsMono Nerd Font"
    readonly property string heroFontFamily: "JetBrainsMono Nerd Font"
    readonly property string timeFontFamily: "JetBrainsMono Nerd Font"
    readonly property int bodyFontSize: 13
    readonly property int titleFontSize: 15
    readonly property int iconFontSize: 15
    readonly property string clockFormat: "24"

    readonly property int islandWidth: 130
    readonly property int islandHeight: 24
    readonly property int islandPositionX: 50
    readonly property int islandTopMargin: 2
    readonly property int islandExclusiveZone: 26
    readonly property int islandBackgroundOpacity: 100
    readonly property bool islandAutoHideEnabled: false

    readonly property int dynamicIslandPrimaryButton: 1
    readonly property string dynamicIslandPrimaryAction: "toggleExpandedPlayer"
    readonly property int dynamicIslandSecondaryButton: 2
    readonly property string dynamicIslandSecondaryAction: "toggleControlCenter"
    readonly property int dynamicIslandMiddleButton: 3
    readonly property string dynamicIslandMiddleAction: "none"
    readonly property int hoverExpandAction: 0

    readonly property string wallpaperPath: "/home/glory42/Pictures/Wallpapers/current.jpg"
    readonly property string wallpaperLibraryPath: "/home/glory42/Pictures/Wallpapers"

    readonly property bool weatherEnabled: true
    readonly property string weatherLocation: ""
    readonly property string weatherUnits: "metric"
    readonly property int weatherRefreshInterval: 1800000

    function mouseButton(code) {
        const numericCode = Number(code);
        if (numericCode === 1) return Qt.LeftButton;
        if (numericCode === 2) return Qt.RightButton;
        if (numericCode === 3) return Qt.MiddleButton;
        return 0;
    }

    function mouseButtonsMask(codes) {
        let mask = 0;
        const list = Array.isArray(codes) ? codes : [codes];
        for (let i = 0; i < list.length; i++)
            mask |= mouseButton(list[i]);
        return mask;
    }
}
