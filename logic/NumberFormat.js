.pragma library

function parseAmount(text) {
  var raw = String(text === undefined || text === null ? "" : text).trim();
  if (raw === "") return NaN;
  raw = raw.replace(/[\s_'’\u00a0\u202f]/g, "").replace(/−/g, "-");
  if (raw === "" || !/^[+-]?(?:\d[\d.,]*|[.,]\d+)(?:[eE][+-]?\d+)?$/.test(raw)) return NaN;

  var comma = raw.lastIndexOf(",");
  var dot = raw.lastIndexOf(".");
  if (comma !== -1 && dot !== -1) {
    if (comma > dot) raw = raw.split(".").join("").replace(",", ".");
    else raw = raw.split(",").join("");
  } else {
    var separator = comma !== -1 ? "," : (dot !== -1 ? "." : "");
    if (separator) {
      var first = raw.indexOf(separator);
      var last = raw.lastIndexOf(separator);
      if (first !== last) {
        var tail = raw.slice(last + 1);
        var groups = raw.slice(0, last).split(separator).slice(1);
        var thousands = tail.length === 3;
        for (var i = 0; i < groups.length; i++) {
          if (groups[i].length !== 3) thousands = false;
        }
        if (thousands) raw = raw.split(separator).join("");
        else raw = raw.slice(0, last).split(separator).join("") + "." + tail;
      } else if (separator === ",") {
        raw = raw.replace(",", ".");
      }
    }
  }
  var value = Number(raw);
  return isFinite(value) ? value : NaN;
}

function formatResult(value) {
  if (typeof value !== "number" || !isFinite(value)) return "—";
  var abs = Math.abs(value);
  if (abs !== 0 && (abs >= 1e12 || abs < 1e-6)) return value.toExponential(4);
  var digits = abs >= 1000 ? 2 : abs >= 1 ? 4 : 6;
  var fixed = value.toFixed(digits);
  var parts = fixed.split(".");
  if (parts.length > 1) parts[1] = parts[1].replace(/0+$/, "");
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return parts[0] + (parts[1] ? "." + parts[1] : "");
}

if (typeof module !== "undefined") {
  module.exports = { parseAmount: parseAmount, formatResult: formatResult };
}
