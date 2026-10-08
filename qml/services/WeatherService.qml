import QtQuick
import Quickshell
import Quickshell.Io
import ".."

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
    property string icon: "cloud"
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
    property int _failures: 0
    // While there is no connection a failed request is not retried; the weather is fetched when it returns.
    property bool online: true
    // Seconds to wait before trying again after each failure in a row; the last one repeats.
    readonly property var _retryAfter: [5, 15, 30, 60, 120, 300]

    readonly property string feelsLikeString: hasData ? Math.round(feelsLike) + "\u00b0" + (units === "imperial" ? "F" : "C") : "--"

    function iconFor(code, day) {
        const c = parseInt(code, 10);
        if (c === 0) return day ? "clear_day" : "clear_night";
        if (c === 1 || c === 2) return day ? "partly_cloudy_day" : "partly_cloudy_night";
        if (c === 45 || c === 48) return "foggy";
        if (c >= 51 && c <= 57) return "rainy_light";
        if ((c >= 61 && c <= 67) || (c >= 80 && c <= 82)) return "rainy";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "weather_snowy";
        if (c >= 95) return "thunderstorm";
        return "cloud";
    }

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

    function _daysAhead(dateString) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        return Math.round((new Date(dateString + "T00:00:00") - today) / 86400000);
    }

    function _dayLabel(dateString) {
        const ahead = root._daysAhead(dateString);
        if (ahead === 0) return "Today";
        if (ahead === 1) return "Tomorrow";
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return days[new Date(dateString + "T00:00:00").getDay()] || dateString;
    }

    // A failed step is tried again soon: at login the shell is up before the network is, and the next refresh is half an hour away.
    function _fail(message, again) {
        root.loading = false;
        root.errorMessage = message;
        root.isStale = root.hasData;
        if (again === false || !root.online)
            return;
        retry.interval = root._retryAfter[Math.min(root._failures, root._retryAfter.length - 1)] * 1000;
        root._failures += 1;
        retry.restart();
    }

    // The last weather shown, kept so a restart has something to show before the first answer arrives.
    function _save() {
        store.setText(JSON.stringify({
            at: Date.now(), units: root.units, temp: root.temp, feelsLike: root.feelsLike, condition: root.condition,
            icon: root.icon, cityName: root.cityName, countryName: root.countryName,
            displayLocation: root.displayLocation, forecast: root.forecast
        }));
    }

    function _restore(text) {
        let saved = null;
        try {
            saved = JSON.parse(text);
        } catch (error) {
            return;
        }
        // Weather older than three hours says more about the past than about now.
        if (root.hasData || !saved || saved.units !== root.units || Date.now() - saved.at > 3 * 3600 * 1000)
            return;
        root.temp = saved.temp;
        root.feelsLike = saved.feelsLike;
        root.condition = saved.condition;
        root.icon = saved.icon;
        root.cityName = saved.cityName;
        root.countryName = saved.countryName;
        root.displayLocation = saved.displayLocation;
        root.forecast = (saved.forecast || []).filter((day) => root._daysAhead(day.date) >= 0)
            .map((day) => Object.assign({}, day, { dayLabel: root._dayLabel(day.date) }));
        root.hasData = true;
        root.isStale = true;
    }

    // Re-fetches for the resolved location, resolving one first on the first call.
    onOnlineChanged: {
        if (online && (errorMessage !== "" || !hasData)) {
            root._failures = 0;
            retry.stop();
            root.refresh();
        }
    }

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

    // IP-based fallback location from wttr.in, because Open-Meteo has no such endpoint; no weather data comes from it.
    function _autoDetectLocation() {
        root.loading = true;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status !== 200) {
                root._fail("Could not detect location");
                return;
            }

            const raw = xhr.responseText.trim();
            if (raw.length === 0 || raw.length > 100 || raw.indexOf("<") === 0 || raw.indexOf("Unknown") !== -1) {
                root._fail("Could not detect location");
                return;
            }

            const city = raw.split(",")[0].trim();
            root._geocodeAndFetch(city.length > 0 ? city : raw);
        };
        xhr.open("GET", "https://wttr.in/?format=%l");
        // wttr.in serves HTML instead of plain text unless the User-Agent looks like curl.
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
                root._fail("Location lookup failed");
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                if (!data.results || data.results.length === 0) {
                    // A name nobody knows will not be found by asking again.
                    root._fail("Location not found: " + name, false);
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
                root._fail("Location lookup error");
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
            + "&current=temperature_2m,apparent_temperature,weather_code,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&timezone=auto&forecast_days=3"
            + "&temperature_unit=" + (isMetric ? "celsius" : "fahrenheit");

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status !== 200) {
                root._fail("Weather fetch failed (" + xhr.status + ")");
                return;
            }
            root.loading = false;

            try {
                const data = JSON.parse(xhr.responseText);
                if (!data || !data.current) {
                    root._fail("Invalid weather data");
                    return;
                }

                root.temp = data.current.temperature_2m;
                root.feelsLike = data.current.apparent_temperature;
                root.condition = root._wmoDescription(data.current.weather_code);
                root.icon = root.iconFor(data.current.weather_code, data.current.is_day !== 0);

                const daily = data.daily;
                if (daily && daily.time) {
                    const days = [];
                    for (let i = 0; i < Math.min(3, daily.time.length); i++) {
                        days.push({
                            date: daily.time[i],
                            dayLabel: root._dayLabel(daily.time[i]),
                            icon: root.iconFor(daily.weather_code[i], true),
                            maxTemp: daily.temperature_2m_max[i],
                            minTemp: daily.temperature_2m_min[i]
                        });
                    }
                    root.forecast = days;
                }

                root.hasData = true;
                root.isStale = false;
                root.errorMessage = "";
                root._failures = 0;
                retry.stop();
                root._save();
            } catch (err) {
                root._fail("Weather parse error");
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

    Timer {
        id: retry

        onTriggered: root.refresh()
    }

    FileView {
        id: store

        path: Quickshell.statePath("weather.json")
        printErrors: false
        onLoaded: root._restore(text())
    }

    Component.onCompleted: if (weatherEnabled) refresh()

    onLocationChanged: if (weatherEnabled) _resolveInitialLocation()
    onUnitsChanged: if (_locationReady) _fetchWeather()
}
