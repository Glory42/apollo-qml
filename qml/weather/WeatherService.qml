pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    readonly property var userConfig: UserConfig

    property bool weatherEnabled: userConfig ? userConfig.weatherEnabled : true
    property string location: userConfig ? userConfig.weatherLocation : ""
    property string units: userConfig ? userConfig.weatherUnits : "metric"
    property int refreshInterval: userConfig ? userConfig.weatherRefreshInterval : 1800000

    property real temp: 0
    property real feelsLike: 0
    property int humidity: 0
    property real windSpeed: 0
    property string windDir: ""
    property int uvIndex: 0
    property string condition: ""
    property string weatherCode: ""
    property string weatherType: "sunny"
    property string iconGlyph: ""
    property string iconColor: "#f4c542"
    property string cityName: ""
    property string countryName: ""
    property string displayLocation: ""
    property string sunrise: ""
    property string sunset: ""
    property real minTemp: 0
    property real maxTemp: 0
    property var forecast: []
    property bool loading: false
    property string errorMessage: ""
    property var lastUpdated: null
    property bool hasData: false
    property bool isStale: false
    property bool isError: errorMessage.length > 0 && !isStale

    // Location search (autocomplete over Open-Meteo's geocoding API), used by
    // the picker in WeatherLayer.qml.
    property var locationSuggestions: []
    property bool searchingLocations: false
    property string searchError: ""

    property real _latitude: 0
    property real _longitude: 0
    property bool _locationReady: false
    property bool _bootstrapped: false
    property string _pendingSearchQuery: ""

    readonly property string tempString: hasData ? (Math.round(temp) + "°" + (units === "imperial" ? "F" : "C")) : "--"
    readonly property string feelsLikeString: hasData ? (Math.round(feelsLike) + "°" + (units === "imperial" ? "F" : "C")) : "--"
    readonly property string windSpeedString: hasData ? (Math.round(windSpeed) + (units === "imperial" ? " mph" : " km/h")) : "--"
    readonly property string rangeString: hasData ? (Math.round(maxTemp) + "° / " + Math.round(minTemp) + "°") : ""

    // WMO weather-interpretation codes (used by Open-Meteo) → the same
    // type/glyph/color buckets WeatherIcon.qml already understands.
    function _wmoIcon(code) {
        const c = parseInt(code, 10);
        if (c === 0) return { type: "sunny", glyph: "", color: "#f4c542" };
        if (c === 1 || c === 2) return { type: "partly_cloudy", glyph: "", color: "#f4c542" };
        if (c === 3) return { type: "cloudy", glyph: "", color: "#9aa0a6" };
        if (c === 45 || c === 48) return { type: "fog", glyph: "", color: "#8a8e99" };
        if (c === 95 || c === 96 || c === 99) return { type: "thunder", glyph: "", color: "#e8b84a" };
        if ([71, 73, 75, 77, 85, 86].indexOf(c) !== -1) return { type: "snow", glyph: "", color: "#d8e8f4" };
        if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].indexOf(c) !== -1) return { type: "rain", glyph: "", color: "#4a9de8" };
        return { type: "cloudy", glyph: "", color: "#9aa0a6" };
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

    function _compassFromDegrees(deg) {
        const dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
        const idx = Math.round(((deg % 360) + 360) % 360 / 22.5) % 16;
        return dirs[idx];
    }

    function _formatTimeOfDay(iso) {
        if (!iso) return "";
        const parts = iso.split("T");
        if (parts.length < 2) return "";
        const hm = parts[1].split(":");
        let h = parseInt(hm[0], 10);
        const m = hm[1];
        const suffix = h >= 12 ? "PM" : "AM";
        h = h % 12;
        if (h === 0) h = 12;
        return h + ":" + m + " " + suffix;
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
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,uv_index"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
            + "&timezone=auto&forecast_days=3"
            + "&temperature_unit=" + (isMetric ? "celsius" : "fahrenheit")
            + "&wind_speed_unit=" + (isMetric ? "kmh" : "mph");

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

                const current = data.current;
                root.temp = current.temperature_2m;
                root.feelsLike = current.apparent_temperature;
                root.humidity = Math.round(current.relative_humidity_2m || 0);
                root.windSpeed = current.wind_speed_10m;
                root.windDir = root._compassFromDegrees(current.wind_direction_10m || 0);
                root.uvIndex = Math.round(current.uv_index || 0);
                root.weatherCode = String(current.weather_code);
                root.condition = root._wmoDescription(current.weather_code);

                const iconData = root._wmoIcon(current.weather_code);
                root.weatherType = iconData.type;
                root.iconGlyph = iconData.glyph;
                root.iconColor = iconData.color;

                const daily = data.daily;
                if (daily && daily.time && daily.time.length > 0) {
                    root.maxTemp = daily.temperature_2m_max[0];
                    root.minTemp = daily.temperature_2m_min[0];
                    root.sunrise = root._formatTimeOfDay(daily.sunrise[0]);
                    root.sunset = root._formatTimeOfDay(daily.sunset[0]);

                    const parsedForecast = [];
                    const count = Math.min(3, daily.time.length);
                    for (let i = 0; i < count; i++) {
                        const dayIcon = root._wmoIcon(daily.weather_code[i]);
                        parsedForecast.push({
                            date: daily.time[i],
                            dayLabel: root._dayLabel(daily.time[i], i),
                            maxTemp: daily.temperature_2m_max[i],
                            minTemp: daily.temperature_2m_min[i],
                            condition: root._wmoDescription(daily.weather_code[i]),
                            weatherType: dayIcon.type,
                            iconGlyph: dayIcon.glyph,
                            iconColor: dayIcon.color
                        });
                    }
                    root.forecast = parsedForecast;
                }

                root.lastUpdated = new Date();
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

    // Debounced location search for the picker UI. Stale responses (the
    // query moved on while this one was in flight) are dropped.
    function searchLocations(query) {
        const trimmed = (query || "").trim();
        root._pendingSearchQuery = trimmed;
        if (trimmed.length < 2) {
            root.locationSuggestions = [];
            root.searchingLocations = false;
            searchDebounceTimer.stop();
            return;
        }
        searchDebounceTimer.restart();
    }

    function _runLocationSearch(query) {
        if (query.length < 2)
            return;

        root.searchingLocations = true;
        root.searchError = "";
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (query !== root._pendingSearchQuery)
                return;

            root.searchingLocations = false;
            if (xhr.status !== 200) {
                root.searchError = "Search failed";
                root.locationSuggestions = [];
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                const results = data.results || [];
                root.locationSuggestions = results.map((r) => ({
                    name: r.name,
                    admin1: r.admin1 || "",
                    country: r.country || "",
                    latitude: r.latitude,
                    longitude: r.longitude
                }));
            } catch (err) {
                root.searchError = "Search error";
                root.locationSuggestions = [];
            }
        };
        xhr.open("GET", "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(query) + "&count=6&language=en&format=json");
        xhr.send();
    }

    function clearSuggestions() {
        root.locationSuggestions = [];
        root.searchError = "";
    }

    // Commits a search result: persists it so it survives shell restarts,
    // then fetches weather for it immediately.
    function selectLocation(suggestion) {
        if (!suggestion)
            return;

        root._latitude = suggestion.latitude;
        root._longitude = suggestion.longitude;
        root.cityName = suggestion.name;
        root.countryName = suggestion.country;
        root.displayLocation = suggestion.country.length > 0 ? (suggestion.name + ", " + suggestion.country) : suggestion.name;
        root._locationReady = true;
        root.locationSuggestions = [];
        root.searchError = "";

        locationAdapter.configured = true;
        locationAdapter.name = root.displayLocation;
        locationAdapter.latitude = suggestion.latitude;
        locationAdapter.longitude = suggestion.longitude;
        locationFile.writeAdapter();

        root._fetchWeather();
    }

    FileView {
        id: locationFile
        path: Quickshell.env("HOME") + "/.local/state/tide-island/weather-location.json"
        watchChanges: false
        printErrors: false

        onLoaded: {
            if (locationAdapter.configured) {
                root._latitude = locationAdapter.latitude;
                root._longitude = locationAdapter.longitude;
                root.cityName = locationAdapter.name;
                root.displayLocation = locationAdapter.name;
                root._locationReady = true;
            }
            root._bootstrapped = true;
            if (root.weatherEnabled)
                root.refresh();
        }
        onLoadFailed: (error) => {
            root._bootstrapped = true;
            if (root.weatherEnabled)
                root.refresh();
        }

        JsonAdapter {
            id: locationAdapter
            property bool configured: false
            property string name: ""
            property real latitude: 0
            property real longitude: 0
        }
    }

    Timer {
        id: searchDebounceTimer
        interval: 300
        repeat: false
        onTriggered: root._runLocationSearch(root._pendingSearchQuery)
    }

    Timer {
        id: refreshTimer
        interval: Math.max(60000, root.refreshInterval)
        running: root.weatherEnabled
        repeat: true
        triggeredOnStart: false
        onTriggered: root.refresh()
    }

    onLocationChanged: {
        if (root._bootstrapped && root.weatherEnabled && !locationAdapter.configured)
            root._resolveInitialLocation();
    }
    onUnitsChanged: {
        if (root._locationReady)
            root._fetchWeather();
    }
    onWeatherEnabledChanged: {
        if (root._bootstrapped && root.weatherEnabled && !root.hasData)
            root.refresh();
    }
}
