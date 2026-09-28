import QtQuick
import Quickshell.Io

// See OverviewIpc.qml for why shellRoot lives on a wrapping QtObject
// instead of directly on the IpcHandler.
QtObject {
    id: wrapper

    required property var shellRoot

    property IpcHandler handler: IpcHandler {
        target: "tide"

        function showClock() {
            wrapper.shellRoot.forFocusedWindow((window) => window.showClockWindow());
        }

        function showTimer() {
            wrapper.shellRoot.forFocusedWindow((window) => window.showTimerWindow());
        }

        function showCustom() {
            wrapper.shellRoot.forFocusedWindow((window) => window.showCustomInfoWindow());
        }

        function showLyrics() {
            wrapper.shellRoot.forFocusedWindow((window) => window.showLyricsWindow());
        }

        function swipeRight() {
            wrapper.shellRoot.forFocusedWindow((window) => window.swipeRightWindow());
        }

        function swipeLeft() {
            wrapper.shellRoot.forFocusedWindow((window) => window.swipeLeftWindow());
        }

        function togglePlayer() {
            wrapper.shellRoot.forFocusedWindow((window) => window.togglePlayerWindow());
        }

        function toggleControlCenter() {
            wrapper.shellRoot.forFocusedWindow((window) => window.toggleControlCenterWindow());
        }

        function togglePowerMenu() {
            wrapper.shellRoot.forFocusedWindow((window) => window.togglePowerMenuWindow());
        }

        function toggleNotificationCenter() {
            wrapper.shellRoot.forFocusedWindow((window) => window.toggleNotificationCenterWindow());
        }

        function toggleWallpaperPicker() {
            wrapper.shellRoot.forFocusedWindow((window) => window.toggleWallpaperPickerWindow());
        }

        function toggleWeather() {
            wrapper.shellRoot.forFocusedWindow((window) => window.toggleWeatherWindow());
        }

        function showWeather() {
            wrapper.shellRoot.forFocusedWindow((window) => window.showWeatherWindow ? window.showWeatherWindow() : window.toggleWeatherWindow());
        }

        function openWeather() {
            wrapper.shellRoot.forFocusedWindow((window) => window.showWeatherWindow ? window.showWeatherWindow() : window.toggleWeatherWindow());
        }

        function closeWeather() {
            wrapper.shellRoot.forFocusedWindow((window) => window.closeWeatherWindow ? window.closeWeatherWindow() : window.toggleWeatherWindow());
        }

        function refreshWeather() {
            if (wrapper.shellRoot.weatherService)
                wrapper.shellRoot.weatherService.refresh();
        }

        function toggleCalendar() {
            wrapper.shellRoot.forFocusedWindow((window) => window.toggleCalendarWindow());
        }

        function showCalendar() {
            wrapper.shellRoot.forFocusedWindow((window) => window.showCalendarWindow ? window.showCalendarWindow() : window.toggleCalendarWindow());
        }

        function openCalendar() {
            wrapper.shellRoot.forFocusedWindow((window) => window.showCalendarWindow ? window.showCalendarWindow() : window.toggleCalendarWindow());
        }

        function closeCalendar() {
            wrapper.shellRoot.forFocusedWindow((window) => window.closeCalendarWindow ? window.closeCalendarWindow() : window.toggleCalendarWindow());
        }
    }
}
