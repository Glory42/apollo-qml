.pragma library

function daysInMonth(y, m) {
    return new Date(y, m + 1, 0).getDate();
}

function daysInPrevMonth(y, m) {
    return new Date(y, m, 0).getDate();
}

// Monday-based first day of week: 0 = Monday, ..., 6 = Sunday
function firstDayOfWeek(y, m) {
    const day = new Date(y, m, 1).getDay();
    return (day + 6) % 7;
}

function getWeekNumber(y, m, d) {
    const target = new Date(Date.UTC(y, m, d));
    target.setUTCDate(target.getUTCDate() + 4 - (target.getUTCDay() || 7));
    const yearStart = new Date(Date.UTC(target.getUTCFullYear(), 0, 1));
    return Math.ceil((((target.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
}
