pragma ComponentBehavior: Bound

import QtQuick
import "../core"

// Current weather and a three-day forecast from Open-Meteo, for a configured or IP-detected city.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool weatherEnabled: Config.weatherEnabled
    property string location: Config.weatherLocation
    property string units: Config.weatherUnits
    property int refreshInterval: Config.weatherRefreshInterval

    property real temp: 0
    property real feelsLike: 0
    property string condition: ""
    property string cityName: ""
    property string countryName: ""
    property string displayLocation: ""
    property var forecast: []
    property bool loading: false
    property string errorMessage: ""
    property bool hasData: false
    property bool isStale: false
    property bool isError: errorMessage.length > 0 && !isStale

    property real _latitude: 0
    property real _longitude: 0
    property bool _locationReady: false

    readonly property string feelsLikeString: hasData ? Math.round(feelsLike) + "\u00b0" + (units === "imperial" ? "F" : "C") : "--"

    function _wmoDescription(code) {
        const table = {
            0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
            45: "Fog", 48: "Depositing rime fog",
            51: "Light drizzle", 53: "Moderate drizzle", 55: "Dense drizzle",
            56: "Light freezing drizzle", 57: "Dense freezing drizzle",
            61: "Slight rain", 63: "Moderate rain", 65: "Heavy rain",
            66: "Light freezing rain", 67: "Heavy freezing rain",
            71: "Slight snow fall", 73: "Moderate snow fall", 75: "Heavy snow fall",
            77: "Snow grains",
            80: "Slight rain showers", 81: "Moderate rain showers", 82: "Violent rain showers",
            85: "Slight snow showers", 86: "Heavy snow showers",
            95: "Thunderstorm", 96: "Thunderstorm with slight hail", 99: "Thunderstorm with heavy hail"
        };
        return table[parseInt(code, 10)] || "Unknown";
    }

    function _dayLabel(dateString, index) {
        if (index === 0) return "Today";
        if (index === 1) return "Tomorrow";
        try {
            const d = new Date(dateString + "T00:00:00");
            const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            return days[d.getDay()] || dateString;
        } catch (e) {
            return dateString;
        }
    }

    // Entry point: re-fetch for whatever location is already resolved, or
    // resolve one first if this is the first call.
    function refresh() {
        if (!weatherEnabled)
            return;
        if (!root._locationReady) {
            root._resolveInitialLocation();
            return;
        }
        root._fetchWeather();
    }

    function _resolveInitialLocation() {
        const configuredName = (root.location || "").trim();
        if (configuredName.length > 0) {
            root._geocodeAndFetch(configuredName);
            return;
        }
        root._autoDetectLocation();
    }

    // IP-based fallback so there's a sensible default with zero configuration
    // (Open-Meteo has no such endpoint of its own; wttr.in's is used for this
    // one purpose only, not for any actual weather data).
    function _autoDetectLocation() {
        root.loading = true;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status !== 200) {
                root.loading = false;
                root.errorMessage = "Could not detect location";
                root.isStale = root.hasData;
                return;
            }

            const raw = xhr.responseText.trim();
            if (raw.length === 0 || raw.length > 100 || raw.indexOf("<") === 0 || raw.indexOf("Unknown") !== -1) {
                root.loading = false;
                root.errorMessage = "Could not detect location";
                root.isStale = root.hasData;
                return;
            }

            const city = raw.split(",")[0].trim();
            root._geocodeAndFetch(city.length > 0 ? city : raw);
        };
        xhr.open("GET", "https://wttr.in/?format=%l");
        // wttr.in serves an HTML page instead of plain text unless the
        // User-Agent looks like curl -- Qt's XHR default looks like a browser.
        xhr.setRequestHeader("User-Agent", "curl/8.0");
        xhr.send();
    }

    function _geocodeAndFetch(name) {
        root.loading = true;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status !== 200) {
                root.loading = false;
                root.errorMessage = "Location lookup failed";
                root.isStale = root.hasData;
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                if (!data.results || data.results.length === 0) {
                    root.loading = false;
                    root.errorMessage = "Location not found: " + name;
                    root.isStale = root.hasData;
                    return;
                }

                const match = data.results[0];
                root._latitude = match.latitude;
                root._longitude = match.longitude;
                root.cityName = match.name || name;
                root.countryName = match.country || "";
                root.displayLocation = root.countryName.length > 0 ? (root.cityName + ", " + root.countryName) : root.cityName;
                root._locationReady = true;
                root._fetchWeather();
            } catch (err) {
                root.loading = false;
                root.errorMessage = "Location lookup error";
                root.isStale = root.hasData;
            }
        };
        xhr.open("GET", "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(name) + "&count=1&language=en&format=json");
        xhr.send();
    }

    function _fetchWeather() {
        root.loading = true;
        const isMetric = root.units !== "imperial";
        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + root._latitude
            + "&longitude=" + root._longitude
            + "&current=temperature_2m,apparent_temperature,weather_code"
            + "&daily=temperature_2m_max,temperature_2m_min"
            + "&timezone=auto&forecast_days=3"
            + "&temperature_unit=" + (isMetric ? "celsius" : "fahrenheit");

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            root.loading = false;
            if (xhr.status !== 200) {
                root.errorMessage = "Weather fetch failed (" + xhr.status + ")";
                root.isStale = root.hasData;
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                if (!data || !data.current) {
                    root.errorMessage = "Invalid weather data";
                    root.isStale = root.hasData;
                    return;
                }

                root.temp = data.current.temperature_2m;
                root.feelsLike = data.current.apparent_temperature;
                root.condition = root._wmoDescription(data.current.weather_code);

                const daily = data.daily;
                if (daily && daily.time) {
                    const days = [];
                    for (let i = 0; i < Math.min(3, daily.time.length); i++) {
                        days.push({
                            dayLabel: root._dayLabel(daily.time[i], i),
                            maxTemp: daily.temperature_2m_max[i],
                            minTemp: daily.temperature_2m_min[i]
                        });
                    }
                    root.forecast = days;
                }

                root.hasData = true;
                root.isStale = false;
                root.errorMessage = "";
            } catch (err) {
                root.errorMessage = "Weather parse error";
                root.isStale = root.hasData;
            }
        };

        xhr.open("GET", url);
        xhr.send();
    }

    Timer {
        interval: Math.max(60000, root.refreshInterval)
        running: root.weatherEnabled
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: if (weatherEnabled) refresh()

    onLocationChanged: if (weatherEnabled) _resolveInitialLocation()
    onUnitsChanged: if (_locationReady) _fetchWeather()
}
