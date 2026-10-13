.pragma library

var UNIT_CATEGORIES = {
  length: {
    label: "Length",
    units: [
      { id: "m", label: "Meter (m)", factor: 1 },
      { id: "km", label: "Kilometer (km)", factor: 1000 },
      { id: "cm", label: "Centimeter (cm)", factor: 0.01 },
      { id: "mm", label: "Millimeter (mm)", factor: 0.001 },
      { id: "mi", label: "Mile (mi)", factor: 1609.344 },
      { id: "yd", label: "Yard (yd)", factor: 0.9144 },
      { id: "ft", label: "Foot (ft)", factor: 0.3048 },
      { id: "in", label: "Inch (in)", factor: 0.0254 }
    ]
  },
  mass: {
    label: "Mass",
    units: [
      { id: "kg", label: "Kilogram (kg)", factor: 1 },
      { id: "g", label: "Gram (g)", factor: 0.001 },
      { id: "mg", label: "Milligram (mg)", factor: 0.000001 },
      { id: "lb", label: "Pound (lb)", factor: 0.45359237 },
      { id: "oz", label: "Ounce (oz)", factor: 0.028349523125 },
      { id: "t", label: "Metric ton (t)", factor: 1000 }
    ]
  },
  temperature: {
    label: "Temperature",
    units: [
      { id: "C", label: "Celsius (°C)" },
      { id: "F", label: "Fahrenheit (°F)" },
      { id: "K", label: "Kelvin (K)" }
    ]
  },
  volume: {
    label: "Volume",
    units: [
      { id: "L", label: "Liter (L)", factor: 1 },
      { id: "mL", label: "Milliliter (mL)", factor: 0.001 },
      { id: "m3", label: "Cubic meter (m³)", factor: 1000 },
      { id: "gal", label: "US gallon (gal)", factor: 3.785411784 },
      { id: "qt", label: "US quart (qt)", factor: 0.946352946 },
      { id: "cup", label: "US cup", factor: 0.2365882365 }
    ]
  },
  area: {
    label: "Area",
    units: [
      { id: "m2", label: "Square meter (m²)", factor: 1 },
      { id: "km2", label: "Square kilometer (km²)", factor: 1000000 },
      { id: "cm2", label: "Square centimeter (cm²)", factor: 0.0001 },
      { id: "ha", label: "Hectare (ha)", factor: 10000 },
      { id: "acre", label: "Acre", factor: 4046.8564224 },
      { id: "ft2", label: "Square foot (ft²)", factor: 0.09290304 }
    ]
  },
  speed: {
    label: "Speed",
    units: [
      { id: "m/s", label: "Meter/second (m/s)", factor: 1 },
      { id: "km/h", label: "Kilometer/hour (km/h)", factor: 1 / 3.6 },
      { id: "mph", label: "Mile/hour (mph)", factor: 0.44704 },
      { id: "kn", label: "Knot (kn)", factor: 0.514444444444 }
    ]
  },
  time: {
    label: "Time",
    units: [
      { id: "s", label: "Second (s)", factor: 1 },
      { id: "ms", label: "Millisecond (ms)", factor: 0.001 },
      { id: "min", label: "Minute (min)", factor: 60 },
      { id: "h", label: "Hour (h)", factor: 3600 },
      { id: "d", label: "Day (d)", factor: 86400 },
      { id: "wk", label: "Week (wk)", factor: 604800 }
    ]
  },
  data: {
    label: "Data",
    units: [
      { id: "B", label: "Byte (B)", factor: 1 },
      { id: "kB", label: "Kilobyte (kB)", factor: 1000 },
      { id: "MB", label: "Megabyte (MB)", factor: 1000000 },
      { id: "GB", label: "Gigabyte (GB)", factor: 1000000000 },
      { id: "TB", label: "Terabyte (TB)", factor: 1000000000000 },
      { id: "KiB", label: "Kibibyte (KiB)", factor: 1024 },
      { id: "MiB", label: "Mebibyte (MiB)", factor: 1048576 },
      { id: "GiB", label: "Gibibyte (GiB)", factor: 1073741824 }
    ]
  }
};

var CRYPTO_LIST = [
  { symbol: "BTC", name: "Bitcoin", id: "bitcoin" },
  { symbol: "ETH", name: "Ethereum", id: "ethereum" },
  { symbol: "SOL", name: "Solana", id: "solana" },
  { symbol: "BNB", name: "BNB", id: "binancecoin" },
  { symbol: "XRP", name: "XRP", id: "ripple" },
  { symbol: "ADA", name: "Cardano", id: "cardano" },
  { symbol: "DOGE", name: "Dogecoin", id: "dogecoin" },
  { symbol: "TRX", name: "TRON", id: "tron" },
  { symbol: "TON", name: "Toncoin", id: "the-open-network" },
  { symbol: "AVAX", name: "Avalanche", id: "avalanche-2" },
  { symbol: "DOT", name: "Polkadot", id: "polkadot" },
  { symbol: "LINK", name: "Chainlink", id: "chainlink" },
  { symbol: "SHIB", name: "Shiba Inu", id: "shiba-inu" },
  { symbol: "BCH", name: "Bitcoin Cash", id: "bitcoin-cash" },
  { symbol: "LTC", name: "Litecoin", id: "litecoin" }
];

var MAJOR_CURRENCIES = ["USD", "EUR", "BRL", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "MXN", "NZD", "SGD", "KRW", "ZAR"];

var CURRENCY_NAMES = {
  USD: "US Dollar", EUR: "Euro", BRL: "Brazilian Real", GBP: "British Pound",
  JPY: "Japanese Yen", CAD: "Canadian Dollar", AUD: "Australian Dollar",
  CHF: "Swiss Franc", CNY: "Chinese Yuan", INR: "Indian Rupee",
  MXN: "Mexican Peso", NZD: "New Zealand Dollar", SGD: "Singapore Dollar",
  KRW: "South Korean Won", ZAR: "South African Rand"
};

function finiteNumber(value, fallback) {
  if (value === null || value === undefined || value === "") return fallback;
  var number = Number(value);
  return isFinite(number) ? number : fallback;
}

function unitById(category, id) {
  var group = UNIT_CATEGORIES[String(category || "")];
  if (!group || !Array.isArray(group.units)) return null;
  for (var i = 0; i < group.units.length; i++) {
    if (group.units[i].id === String(id || "")) return group.units[i];
  }
  return null;
}

function convertTemperature(value, from, to) {
  var celsius;
  if (from === "C") celsius = value;
  else if (from === "F") celsius = (value - 32) * 5 / 9;
  else if (from === "K") celsius = value - 273.15;
  else return NaN;
  if (to === "C") return celsius;
  if (to === "F") return celsius * 9 / 5 + 32;
  if (to === "K") return celsius + 273.15;
  return NaN;
}

function convertUnit(value, category, from, to) {
  var amount = finiteNumber(value, NaN);
  if (!isFinite(amount)) return NaN;
  var key = String(category || "");
  var fromId = String(from || "");
  var toId = String(to || "");
  if (!unitById(key, fromId) || !unitById(key, toId)) return NaN;
  if (fromId === toId) return amount;
  if (key === "temperature") return convertTemperature(amount, fromId, toId);
  var source = unitById(key, fromId);
  var target = unitById(key, toId);
  var result = amount * Number(source.factor) / Number(target.factor);
  return isFinite(result) ? result : NaN;
}

function cryptoEntry(key) {
  var value = String(key || "").trim().toUpperCase();
  for (var i = 0; i < CRYPTO_LIST.length; i++) {
    if (CRYPTO_LIST[i].symbol === value || CRYPTO_LIST[i].id.toUpperCase() === value) return CRYPTO_LIST[i];
  }
  return null;
}

function cryptoPrice(key, cryptoPrices) {
  var prices = cryptoPrices && typeof cryptoPrices === "object" ? cryptoPrices : {};
  var entry = cryptoEntry(key);
  var candidates = [String(key || ""), String(key || "").toUpperCase(), String(key || "").toLowerCase()];
  if (entry) candidates.push(entry.id, entry.symbol, entry.symbol.toLowerCase());
  for (var i = 0; i < candidates.length; i++) {
    var value = prices[candidates[i]];
    if (value && typeof value === "object") value = value.usd !== undefined ? value.usd : value.USD;
    var number = finiteNumber(value, NaN);
    if (isFinite(number) && number > 0) return number;
  }
  return NaN;
}

function toUsd(value, key, rates, cryptoPrices) {
  var amount = finiteNumber(value, NaN);
  if (!isFinite(amount)) return NaN;
  var currency = String(key || "").trim().toUpperCase();
  if (currency === "USD") return amount;
  var entry = cryptoEntry(currency);
  if (entry) {
    var coinPrice = cryptoPrice(currency, cryptoPrices);
    return isFinite(coinPrice) ? amount * coinPrice : NaN;
  }
  var table = rates && typeof rates === "object" ? rates : {};
  var rate = finiteNumber(table[currency], NaN);
  if (!isFinite(rate) || rate <= 0) return NaN;
  return amount / rate;
}

function fromUsd(usd, key, rates, cryptoPrices) {
  var amount = finiteNumber(usd, NaN);
  if (!isFinite(amount)) return NaN;
  var currency = String(key || "").trim().toUpperCase();
  if (currency === "USD") return amount;
  var entry = cryptoEntry(currency);
  if (entry) {
    var coinPrice = cryptoPrice(currency, cryptoPrices);
    return isFinite(coinPrice) && coinPrice > 0 ? amount / coinPrice : NaN;
  }
  var table = rates && typeof rates === "object" ? rates : {};
  var rate = finiteNumber(table[currency], NaN);
  if (!isFinite(rate) || rate <= 0) return NaN;
  return amount * rate;
}

function convertCross(value, from, to, rates, cryptoPrices) {
  var amount = finiteNumber(value, NaN);
  if (!isFinite(amount)) return NaN;
  if (String(from || "").toUpperCase() === String(to || "").toUpperCase()) return amount;
  var usd = toUsd(amount, from, rates, cryptoPrices);
  return isFinite(usd) ? fromUsd(usd, to, rates, cryptoPrices) : NaN;
}

if (typeof module !== "undefined") {
  module.exports = {
    UNIT_CATEGORIES: UNIT_CATEGORIES,
    CRYPTO_LIST: CRYPTO_LIST,
    MAJOR_CURRENCIES: MAJOR_CURRENCIES,
    CURRENCY_NAMES: CURRENCY_NAMES,
    convertUnit: convertUnit,
    toUsd: toUsd,
    fromUsd: fromUsd,
    convertCross: convertCross
  };
}
