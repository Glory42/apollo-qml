.pragma library

function boundedInt(value, fallback, minimumValue, maximumValue) {
    const number = Number(value);
    if (!isFinite(number))
        return fallback;
    return Math.max(minimumValue, Math.min(maximumValue, Math.round(number)));
}

function boundedReal(value, fallback, minimumValue, maximumValue) {
    const number = Number(value);
    if (!isFinite(number))
        return fallback;
    return Math.max(minimumValue, Math.min(maximumValue, number));
}

function nonEmptyString(value, fallback) {
    const text = String(value === undefined || value === null ? "" : value).trim();
    return text.length > 0 ? text : fallback;
}

function validTransitionType(value, transitionTypes) {
    const text = nonEmptyString(value, "center");
    return transitionTypes.indexOf(text) >= 0 ? text : "center";
}
