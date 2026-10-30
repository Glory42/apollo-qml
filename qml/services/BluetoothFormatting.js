.pragma library

function cleanText(value) {
    return String(value === undefined || value === null ? "" : value).trim();
}

function normalizedAddress(value) {
    return cleanText(value).toUpperCase().replace(/[-_]/g, ":");
}

function isAddressLike(value, address) {
    const text = cleanText(value);
    if (text.length === 0)
        return false;

    if (/^[0-9A-F]{2}([:_-][0-9A-F]{2}){5}$/i.test(text))
        return true;

    const normalizedDeviceAddress = normalizedAddress(address);
    return normalizedDeviceAddress.length > 0
        && normalizedAddress(text) === normalizedDeviceAddress;
}

function isUsefulName(value, address) {
    const text = cleanText(value);
    if (text.length === 0 || isAddressLike(text, address))
        return false;

    const normalized = text.toLocaleLowerCase();
    return normalized !== "unknown"
        && normalized !== "unknown device"
        && normalized !== "bluetooth device"
        && normalized !== "n/a";
}

function friendlyName(alias, advertisedName, address) {
    // BlueZ Alias is the user-facing name; advertised Name is only a fallback and can be an address placeholder.
    if (isUsefulName(alias, address))
        return cleanText(alias);
    if (isUsefulName(advertisedName, address))
        return cleanText(advertisedName);
    return "";
}

function typeLabel(icon) {
    switch (cleanText(icon).toLocaleLowerCase()) {
    case "audio-headphones":
        return "Headphones";
    case "audio-headset":
        return "Headset";
    case "audio-card":
    case "audio-speakers":
        return "Audio device";
    case "input-keyboard":
        return "Keyboard";
    case "input-mouse":
        return "Mouse";
    case "input-gaming":
        return "Game controller";
    case "phone":
    case "smartphone":
        return "Phone";
    case "computer":
        return "Computer";
    case "camera-photo":
        return "Camera";
    case "printer":
        return "Printer";
    default:
        return "Unknown device";
    }
}

function displayName(alias, advertisedName, address, icon) {
    const name = friendlyName(alias, advertisedName, address);
    return name.length > 0 ? name : typeLabel(icon);
}

function addressLabel(address) {
    return normalizedAddress(address);
}

// What a device can do, from the 16-bit service ids bluetoothctl lists; each label once, in a fixed order.
function profileLabels(ids) {
    const groups = [
        ["Music", ["110a", "110b", "110d"]],
        ["Calls", ["1108", "1112", "111e", "111f"]],
        ["Media controls", ["110c", "110e", "110f"]],
        ["Input", ["1124", "1812"]],
        ["Files", ["1105", "1106"]],
        ["Network", ["1115", "1116"]]
    ];
    const have = ids.map((id) => cleanText(id).toLowerCase());
    return groups.filter((group) => group[1].some((id) => have.indexOf(id) >= 0)).map((group) => group[0]);
}

// PipeWire's name for a Bluetooth codec, as it is usually written.
function codecLabel(codec) {
    const names = {
        sbc: "SBC", sbc_xq: "SBC XQ", msbc: "mSBC", cvsd: "CVSD", aac: "AAC", aac_eld: "AAC-ELD", ldac: "LDAC",
        aptx: "aptX", aptx_hd: "aptX HD", aptx_ll: "aptX LL", aptx_ll_duplex: "aptX LL", faststream: "FastStream",
        faststream_duplex: "FastStream", opus_05: "Opus", opus_g: "Opus", lc3: "LC3", lc3plus_h3: "LC3plus"
    };
    const key = cleanText(codec).toLowerCase();
    return names[key] || key.toUpperCase();
}
