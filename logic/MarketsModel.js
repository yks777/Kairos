.pragma library

var CRYPTO_COIN_IDS = {
  BTC: "bitcoin",
  ETH: "ethereum",
  SOL: "solana",
  BNB: "binancecoin",
  XRP: "ripple",
  ADA: "cardano",
  DOGE: "dogecoin",
  TRX: "tron",
  TON: "the-open-network",
  AVAX: "avalanche-2",
  DOT: "polkadot",
  LINK: "chainlink",
  SHIB: "shiba-inu",
  BCH: "bitcoin-cash",
  LTC: "litecoin"
};

var CRYPTO_NAMES = {
  BTC: "Bitcoin", ETH: "Ethereum", SOL: "Solana", BNB: "BNB",
  XRP: "XRP", ADA: "Cardano", DOGE: "Dogecoin", TRX: "TRON",
  TON: "Toncoin", AVAX: "Avalanche", DOT: "Polkadot", LINK: "Chainlink",
  SHIB: "Shiba Inu", BCH: "Bitcoin Cash", LTC: "Litecoin"
};

function finiteNumber(value, fallback) {
  if (value === null || value === undefined || value === "") return fallback;
  var number = Number(value);
  return isFinite(number) ? number : fallback;
}

function own(object, key) {
  return object !== null && typeof object === "object"
    && Object.prototype.hasOwnProperty.call(object, key);
}

function cryptoBase(symbol) {
  var value = String(symbol || "").trim().toUpperCase();
  var match = value.match(/^([A-Z0-9]{2,16})(?:[-/]?(?:USD|USDT))$/);
  if (match && own(CRYPTO_COIN_IDS, match[1])) return match[1];
  if (value.indexOf("/") !== -1) value = value.split("/")[0];
  else if (value.indexOf("-") !== -1) value = value.split("-")[0];
  if (own(CRYPTO_COIN_IDS, value)) return value;
  if (/USDT$/.test(value)) {
    var candidate = value.slice(0, -4);
    if (own(CRYPTO_COIN_IDS, candidate)) return candidate;
  }
  return "";
}

function normalizeSymbol(input) {
  var symbol = String(input === undefined || input === null ? "" : input)
    .trim().toUpperCase().replace(/\s+/g, "");
  if (symbol.charAt(0) === "$") symbol = symbol.slice(1);
  if (symbol === "") return "";
  var base = cryptoBase(symbol);
  if (base && /(?:[-/]?(?:USD|USDT))$/.test(symbol)) return base;
  if (symbol.length > 24 || !/^[A-Z0-9][A-Z0-9.^/_=-]*$/.test(symbol)) return "";
  return symbol;
}

function isCryptoSymbol(symbol, coinIds) {
  var normalized = String(symbol || "").trim().toUpperCase();
  var map = coinIds && typeof coinIds === "object" ? coinIds : {};
  if (own(map, normalized) && String(map[normalized] || "") !== "") return true;
  return cryptoBase(normalized) !== "";
}

function displaySymbol(symbol) {
  var value = String(symbol || "").trim().toUpperCase();
  if (/-USD$/.test(value)) return value.slice(0, -4);
  if (/-EUR$/.test(value)) return value.slice(0, -4) + "/EUR";
  if (/-USDT$/.test(value)) return value.slice(0, -5);
  if (value.indexOf("/") !== -1) return value;
  var base = cryptoBase(value);
  if (base) return base;
  return value;
}

function defaultWatchlist() {
  return { symbols: ["AAPL", "NVDA", "BTC"], coinIds: {} };
}

function cloneWatchlist(watchlist) {
  var source = watchlist && typeof watchlist === "object" ? watchlist : defaultWatchlist();
  var symbols = Array.isArray(source.symbols) ? source.symbols.slice(0, 50) : [];
  var coinIds = {};
  var ids = source.coinIds && typeof source.coinIds === "object" ? source.coinIds : {};
  for (var key in ids) {
    if (own(ids, key)) coinIds[String(key).toUpperCase()] = String(ids[key] || "");
  }
  return { symbols: symbols, coinIds: coinIds };
}

function addSymbol(watchlist, symbol, coinId) {
  var next = cloneWatchlist(watchlist);
  var normalized = normalizeSymbol(symbol);
  if (!normalized) return next;
  var exists = false;
  for (var i = 0; i < next.symbols.length; i++) {
    if (String(next.symbols[i]).toUpperCase() === normalized) { exists = true; break; }
  }
  if (!exists && next.symbols.length < 50) next.symbols.push(normalized);
  if (coinId && /^[a-z0-9-]{1,64}$/.test(String(coinId))) next.coinIds[normalized] = String(coinId);
  return next;
}

function removeSymbol(watchlist, symbol) {
  var next = cloneWatchlist(watchlist);
  var normalized = normalizeSymbol(symbol);
  next.symbols = next.symbols.filter(function(item) { return String(item).toUpperCase() !== normalized; });
  delete next.coinIds[normalized];
  return next;
}

function moveSymbol(watchlist, fromIndex, toIndex) {
  var next = cloneWatchlist(watchlist);
  var from = Math.floor(finiteNumber(fromIndex, -1));
  var to = Math.floor(finiteNumber(toIndex, -1));
  if (from < 0 || from >= next.symbols.length || to < 0 || to >= next.symbols.length || from === to) return next;
  var moved = next.symbols.splice(from, 1)[0];
  next.symbols.splice(to, 0, moved);
  return next;
}

function coinIdForSymbol(symbol, coinIds) {
  var key = String(symbol || "").trim().toUpperCase();
  var ids = coinIds && typeof coinIds === "object" ? coinIds : {};
  if (own(ids, key) && /^[a-z0-9-]{1,64}$/.test(String(ids[key]))) return String(ids[key]);
  var base = cryptoBase(key) || key;
  return own(CRYPTO_COIN_IDS, base) ? CRYPTO_COIN_IDS[base] : "";
}

function cryptoIdsFromQuotes(quotes, coinIds) {
  var ids = [];
  var seen = {};
  var rows = Array.isArray(quotes) ? quotes : [];
  for (var i = 0; i < rows.length; i++) {
    var quote = rows[i] || {};
    var id = String(quote.coinId || coinIdForSymbol(quote.symbol, coinIds) || "");
    if (id && !seen[id]) { seen[id] = true; ids.push(id); }
  }
  return ids;
}

function parseChartResponse(line, symbol) {
  var payload = line;
  if (typeof payload === "string") {
    try { payload = JSON.parse(payload); } catch (error) { return null; }
  }
  if (!payload || typeof payload !== "object") return null;
  var chart = payload.chart || payload;
  var result = chart && Array.isArray(chart.result) ? chart.result[0] : null;
  if (!result || !result.meta) return null;
  var meta = result.meta;
  var indicators = result.indicators || {};
  var quoteRows = indicators.quote || [];
  var quoteData = quoteRows.length ? quoteRows[0] : {};
  var closes = Array.isArray(quoteData.close) ? quoteData.close : [];
  var opens = Array.isArray(quoteData.open) ? quoteData.open : [];
  var highs = Array.isArray(quoteData.high) ? quoteData.high : [];
  var lows = Array.isArray(quoteData.low) ? quoteData.low : [];
  var volumes = Array.isArray(quoteData.volume) ? quoteData.volume : [];

  function lastFinite(values) {
    for (var index = values.length - 1; index >= 0; index--) {
      var number = finiteNumber(values[index], NaN);
      if (isFinite(number)) return number;
    }
    return NaN;
  }
  var price = finiteNumber(meta.regularMarketPrice, lastFinite(closes));
  if (!isFinite(price)) return null;
  var prevClose = finiteNumber(meta.chartPreviousClose,
    finiteNumber(meta.previousClose, NaN));
  if (!isFinite(prevClose)) prevClose = finiteNumber(closes.length > 1 ? closes[closes.length - 2] : NaN, price);
  var change = finiteNumber(meta.regularMarketChange, price - prevClose);
  var changePct = finiteNumber(meta.regularMarketChangePercent,
    prevClose === 0 ? 0 : change / prevClose * 100);
  var period = meta.currentTradingPeriod && meta.currentTradingPeriod.regular
    ? meta.currentTradingPeriod.regular : {};
  var openTime = finiteNumber(period.start, 0);
  var closeTime = finiteNumber(period.end, 0);
  var timestamp = finiteNumber(meta.regularMarketTime, 0);

  return {
    symbol: normalizeSymbol(symbol || meta.symbol || ""),
    name: String(meta.longName || meta.shortName || meta.displayName || symbol || meta.symbol || ""),
    assetType: "stock",
    source: "Yahoo",
    currency: /^[A-Z]{3}$/.test(String(meta.currency || "").toUpperCase())
      ? String(meta.currency).toUpperCase() : "USD",
    price: price,
    change: change,
    changePct: changePct,
    open: finiteNumber(meta.regularMarketOpen, lastFinite(opens)),
    prevClose: prevClose,
    dayHigh: finiteNumber(meta.regularMarketDayHigh, lastFinite(highs)),
    dayLow: finiteNumber(meta.regularMarketDayLow, lastFinite(lows)),
    volume: finiteNumber(meta.regularMarketVolume, lastFinite(volumes)),
    week52Low: finiteNumber(meta.fiftyTwoWeekLow, NaN),
    week52High: finiteNumber(meta.fiftyTwoWeekHigh, NaN),
    marketState: String(meta.marketState || ""),
    regularOpenMs: openTime > 0 ? openTime * 1000 : 0,
    regularCloseMs: closeTime > 0 ? closeTime * 1000 : 0,
    exchangeTimezoneName: String(meta.exchangeTimezoneName || ""),
    updatedAt: timestamp > 0 ? timestamp * 1000 : Date.now(),
    coinId: ""
  };
}

function parseQuoteLines(text, symbols) {
  var rows = [];
  var lines = String(text || "").split(/\r?\n/);
  var index = 0;
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim();
    if (!line) continue;
    var symbol = Array.isArray(symbols) ? symbols[index] : "";
    var quote = parseChartResponse(line, symbol);
    if (quote) rows.push(quote);
    index++;
  }
  if (rows.length === 0 && String(text || "").trim() !== "") {
    var single = parseChartResponse(String(text), Array.isArray(symbols) ? symbols[0] : "");
    if (single) rows.push(single);
  }
  return rows;
}

function parseChartSeries(text, range) {
  var payload = text;
  if (typeof payload === "string") {
    try { payload = JSON.parse(payload); } catch (error) { return []; }
  }
  var result = payload && payload.chart && Array.isArray(payload.chart.result) ? payload.chart.result[0] : null;
  if (!result) return [];
  var timestamps = Array.isArray(result.timestamp) ? result.timestamp : [];
  var quote = result.indicators && result.indicators.quote && result.indicators.quote.length
    ? result.indicators.quote[0] : {};
  var closes = Array.isArray(quote.close) ? quote.close : [];
  var output = [];
  for (var i = 0; i < timestamps.length && i < closes.length; i++) {
    var time = finiteNumber(timestamps[i], NaN);
    var close = finiteNumber(closes[i], NaN);
    if (isFinite(time) && isFinite(close)) output.push({ t: time * 1000, c: close });
  }
  var rangeKey = String(range || "").toLowerCase();
  var hours = rangeKey === "1h" ? 1 : rangeKey === "4h" ? 4 : 0;
  if (hours && output.length > 1) {
    var cutoff = output[output.length - 1].t - hours * 60 * 60 * 1000;
    output = output.filter(function(point) { return point.t >= cutoff; });
  }
  return output;
}

function parseBinanceTicker(line) {
  var data = line;
  if (typeof data === "string") {
    try { data = JSON.parse(data); } catch (error) { return null; }
  }
  if (!data || typeof data !== "object" || Array.isArray(data) || data.code) return null;
  var price = finiteNumber(data.lastPrice, NaN);
  if (!isFinite(price)) return null;
  var change = finiteNumber(data.priceChange, 0);
  var changePct = finiteNumber(data.priceChangePercent, 0);
  var open = finiteNumber(data.openPrice, price - change);
  return {
    pair: String(data.symbol || ""),
    price: price,
    change: change,
    changePct: changePct,
    open: open,
    prevClose: price - change,
    dayHigh: finiteNumber(data.highPrice, NaN),
    dayLow: finiteNumber(data.lowPrice, NaN),
    volume: finiteNumber(data.quoteVolume, finiteNumber(data.volume, NaN)),
    baseVolume: finiteNumber(data.volume, NaN),
    updatedAt: finiteNumber(data.closeTime, Date.now())
  };
}

function parseBinanceLines(text, pairs) {
  var output = [];
  var lines = String(text || "").split(/\r?\n/);
  for (var i = 0; i < lines.length; i++) {
    if (!lines[i].trim()) continue;
    var item = parseBinanceTicker(lines[i]);
    if (item) {
      if (Array.isArray(pairs) && pairs[i] && !item.pair) item.pair = String(pairs[i]);
      output.push(item);
    }
  }
  if (output.length === 0 && String(text || "").trim() !== "") {
    var single = parseBinanceTicker(String(text));
    if (single) output.push(single);
  }
  return output;
}

function parseBinanceKlines(text) {
  var data = text;
  if (typeof data === "string") {
    try { data = JSON.parse(data); } catch (error) { return []; }
  }
  if (!Array.isArray(data)) return [];
  var output = [];
  for (var i = 0; i < data.length; i++) {
    var row = data[i];
    if (!Array.isArray(row) || row.length < 5) continue;
    var time = finiteNumber(row[0], NaN);
    var close = finiteNumber(row[4], NaN);
    if (isFinite(time) && isFinite(close)) output.push({ t: time, c: close });
  }
  return output;
}

function enrichQuotesBinance(quotes, binanceData) {
  var rows = Array.isArray(quotes) ? quotes : [];
  var data = binanceData && typeof binanceData === "object" ? binanceData : {};
  return rows.map(function(quote) {
    var pair = binancePairFor(quote.symbol);
    var item = own(data, pair) ? data[pair] : null;
    if (!item) return quote;
    var copy = {};
    for (var key in quote) if (own(quote, key)) copy[key] = quote[key];
    copy.price = item.price;
    copy.change = item.change;
    copy.changePct = item.changePct;
    copy.open = item.open;
    copy.prevClose = item.prevClose;
    copy.dayHigh = item.dayHigh;
    copy.dayLow = item.dayLow;
    copy.volume = item.volume;
    copy.assetType = "crypto";
    copy.source = "Binance";
    copy.updatedAt = item.updatedAt || Date.now();
    return copy;
  });
}

function parseCoinMarkets(text) {
  var data = text;
  if (typeof data === "string") {
    try { data = JSON.parse(data); } catch (error) { return []; }
  }
  if (!Array.isArray(data)) return [];
  var output = [];
  for (var i = 0; i < data.length && output.length < 50; i++) {
    var item = data[i];
    if (!item || typeof item !== "object") continue;
    var symbol = String(item.symbol || "").toUpperCase();
    var id = String(item.id || "");
    if (!/^[A-Z0-9]{1,16}$/.test(symbol) || !/^[a-z0-9-]{1,64}$/.test(id)) continue;
    output.push({
      id: id,
      symbol: symbol,
      name: String(item.name || symbol).slice(0, 80),
      price: finiteNumber(item.current_price, NaN),
      marketCap: finiteNumber(item.market_cap, NaN),
      volume: finiteNumber(item.total_volume, NaN),
      circulatingSupply: finiteNumber(item.circulating_supply, NaN),
      high24h: finiteNumber(item.high_24h, NaN),
      low24h: finiteNumber(item.low_24h, NaN),
      changePct: finiteNumber(item.price_change_percentage_24h, NaN),
      marketCapRank: finiteNumber(item.market_cap_rank, NaN)
    });
  }
  return output;
}

function parseCoinSearch(text) {
  var data = text;
  if (typeof data === "string") {
    try { data = JSON.parse(data); } catch (error) { return []; }
  }
  var coins = data && Array.isArray(data.coins) ? data.coins : [];
  var output = [];
  for (var i = 0; i < coins.length && output.length < 12; i++) {
    var coin = coins[i] || {};
    var symbol = String(coin.symbol || "").toUpperCase();
    var id = String(coin.id || "");
    if (!/^[A-Z0-9]{1,16}$/.test(symbol) || !/^[a-z0-9-]{1,64}$/.test(id)) continue;
    output.push({
      symbol: symbol,
      name: String(coin.name || symbol).slice(0, 80),
      exchange: "CoinGecko",
      assetType: "crypto",
      coinId: id,
      marketCapRank: finiteNumber(coin.market_cap_rank, NaN)
    });
  }
  return output;
}

function enrichQuotes(quotes, coinData) {
  var rows = Array.isArray(quotes) ? quotes : [];
  var coins = Array.isArray(coinData) ? coinData : [];
  var byId = {};
  var bySymbol = {};
  for (var i = 0; i < coins.length; i++) {
    var coin = coins[i] || {};
    if (coin.id) byId[String(coin.id)] = coin;
    if (coin.symbol) bySymbol[String(coin.symbol).toUpperCase()] = coin;
  }
  return rows.map(function(quote) {
    var id = String(quote.coinId || coinIdForSymbol(quote.symbol) || "");
    var coin = id && own(byId, id) ? byId[id] : bySymbol[String(quote.symbol || "").toUpperCase()];
    if (!coin) return quote;
    var copy = {};
    for (var key in quote) if (own(quote, key)) copy[key] = quote[key];
    copy.coinId = coin.id;
    copy.name = coin.name || copy.name;
    copy.assetType = "crypto";
    copy.marketCap = coin.marketCap;
    copy.circulatingSupply = coin.circulatingSupply;
    if (!isFinite(Number(copy.dayHigh))) copy.dayHigh = coin.high24h;
    if (!isFinite(Number(copy.dayLow))) copy.dayLow = coin.low24h;
    if (!isFinite(Number(copy.changePct))) copy.changePct = coin.changePct;
    if (!isFinite(Number(copy.price)) && isFinite(Number(coin.price))) copy.price = coin.price;
    if (!isFinite(Number(copy.volume)) && isFinite(Number(coin.volume))) copy.volume = coin.volume;
    return copy;
  });
}

function yahooSearchUrl(query) {
  var value = String(query || "").trim();
  return "https://query1.finance.yahoo.com/v1/finance/search?q=" + encodeURIComponent(value)
    + "&quotesCount=12&newsCount=0";
}

function parseYahooSearch(text) {
  var payload = text;
  if (typeof payload === "string") {
    try { payload = JSON.parse(payload); } catch (error) { return []; }
  }
  var quotes = payload && Array.isArray(payload.quotes) ? payload.quotes : [];
  var output = [];
  var seen = {};
  for (var i = 0; i < quotes.length && output.length < 12; i++) {
    var quote = quotes[i] || {};
    var symbol = normalizeSymbol(quote.symbol || "");
    var type = String(quote.quoteType || "").toUpperCase();
    if (!symbol || ["EQUITY", "ETF", "INDEX", "CURRENCY", "CRYPTOCURRENCY", "FUTURE"].indexOf(type) === -1) continue;
    var key = symbol + "|" + type;
    if (seen[key]) continue;
    seen[key] = true;
    output.push({
      symbol: symbol,
      name: String(quote.shortname || quote.longname || quote.name || symbol).slice(0, 80),
      exchange: String(quote.exchDisp || quote.exchange || "Yahoo"),
      assetType: type === "CRYPTOCURRENCY" || isCryptoSymbol(symbol) ? "crypto" : "stock",
      coinId: coinIdForSymbol(symbol)
    });
  }
  return output;
}

function coingeckoMarketsUrl(ids) {
  var values = Array.isArray(ids) ? ids : [];
  var safe = [];
  for (var i = 0; i < values.length && safe.length < 50; i++) {
    var id = String(values[i] || "");
    if (/^[a-z0-9-]{1,64}$/.test(id) && safe.indexOf(id) === -1) safe.push(id);
  }
  return "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids="
    + encodeURIComponent(safe.join(","))
    + "&order=market_cap_desc&per_page=50&page=1&sparkline=false"
    + "&price_change_percentage=24h";
}

function coingeckoSearchUrl(query) {
  return "https://api.coingecko.com/api/v3/search?query=" + encodeURIComponent(String(query || "").trim());
}

function binancePairFor(symbol, coinIds) {
  var value = String(symbol || "").trim().toUpperCase();
  var base = cryptoBase(value);
  if (!base && isCryptoSymbol(value, coinIds)) base = value.split(/[-/]/)[0];
  if (!base) return "";
  var suffix = "USDT";
  var pairMatch = value.match(/^[A-Z0-9]+[-/]([A-Z0-9]+)$/);
  if (pairMatch) {
    var quote = pairMatch[1];
    if (quote === "USD") quote = "USDT";
    if (["USDT", "BTC", "ETH", "BNB", "EUR", "TRY", "BRL"].indexOf(quote) !== -1) suffix = quote;
  }
  return base + suffix;
}

function binanceTickerUrl(pair) {
  var value = String(pair || "").toUpperCase();
  if (!/^[A-Z0-9]{5,24}$/.test(value)) return "";
  return "https://api.binance.com/api/v3/ticker/24hr?symbol=" + encodeURIComponent(value);
}

function binanceKlinesUrl(symbol, range, coinIds) {
  var pair = binancePairFor(symbol, coinIds);
  if (!pair) return "";
  var settings = {
    "1h": ["1m", 60], "4h": ["5m", 48], "1d": ["15m", 96],
    "5d": ["1h", 120], "1mo": ["4h", 180], "3mo": ["1d", 90],
    "6mo": ["1d", 180], "ytd": ["1d", 365], "1y": ["1d", 365],
    "5y": ["1w", 260], "max": ["1M", 120]
  };
  var item = settings[String(range || "1d")] || settings["1d"];
  return "https://api.binance.com/api/v3/klines?symbol=" + encodeURIComponent(pair)
    + "&interval=" + encodeURIComponent(item[0]) + "&limit=" + item[1];
}

function yahooChartUrl(symbol, range, interval) {
  var value = String(symbol || "").trim().toUpperCase();
  if (!/^[A-Z0-9][A-Z0-9.^=_-]{0,23}$/.test(value)) return "";
  var rangeMap = {
    "1h": ["1d", "1m"], "4h": ["1d", "5m"], "1d": ["1d", "5m"],
    "5d": ["5d", "15m"], "1mo": ["1mo", "1d"], "3mo": ["3mo", "1d"],
    "6mo": ["6mo", "1d"], "ytd": ["ytd", "1d"], "1y": ["1y", "1d"],
    "5y": ["5y", "1wk"], "max": ["max", "1mo"]
  };
  var defaults = rangeMap[String(range || "1d")] || rangeMap["1d"];
  var period = defaults[0];
  var step = interval || defaults[1];
  return "https://query1.finance.yahoo.com/v8/finance/chart/" + encodeURIComponent(value)
    + "?range=" + encodeURIComponent(period) + "&interval=" + encodeURIComponent(step)
    + "&events=div%2Csplits&includePrePost=false";
}

function marketStatus(quote, nowMs) {
  if (quote && String(quote.assetType || "").toLowerCase() === "crypto") return "open";
  var state = String(quote && quote.marketState || "").toUpperCase();
  if (["REGULAR", "OPEN", "OPENING", "CLOSING"].indexOf(state) !== -1) return "open";
  if (["CLOSED", "PRE", "PREPRE", "POST", "POSTPOST", "HALTED"].indexOf(state) !== -1) return "closed";
  var now = finiteNumber(nowMs, Date.now());
  var open = finiteNumber(quote && quote.regularOpenMs, 0);
  var close = finiteNumber(quote && quote.regularCloseMs, 0);
  if (open > 0 && close > 0 && now >= open && now < close) return "open";

  // Fallback for US-listed symbols when Yahoo does not provide a session state.
  var date = new Date(now);
  var year = date.getUTCFullYear();
  var startDay = nthWeekdayOfMonth(year, 2, 0, 2);
  var endDay = nthWeekdayOfMonth(year, 10, 0, 1);
  var dstStart = Date.UTC(year, 2, startDay, 7, 0, 0);
  var dstEnd = Date.UTC(year, 10, endDay, 6, 0, 0);
  var offsetMinutes = now >= dstStart && now < dstEnd ? -240 : -300;
  var eastern = new Date(now + offsetMinutes * 60000);
  var weekday = eastern.getUTCDay();
  var minuteOfDay = eastern.getUTCHours() * 60 + eastern.getUTCMinutes();
  return weekday >= 1 && weekday <= 5 && minuteOfDay >= 570 && minuteOfDay < 960 ? "open" : "closed";
}

function nthWeekdayOfMonth(year, month, weekday, occurrence) {
  var firstDow = new Date(Date.UTC(year, month, 1)).getUTCDay();
  return 1 + ((weekday - firstDow + 7) % 7) + (occurrence - 1) * 7;
}

function marketStatusLabel(status) {
  return String(status || "").toLowerCase() === "open" ? "Market open" : "Market closed";
}

function groupNumber(value, decimals) {
  var number = finiteNumber(value, NaN);
  if (!isFinite(number)) return "—";
  var digits = decimals === undefined ? 2 : Math.max(0, Math.min(8, Math.floor(decimals)));
  var fixed = Math.abs(number).toFixed(digits);
  var parts = fixed.split(".");
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return (number < 0 ? "-" : "") + parts[0] + (digits ? "." + parts[1] : "");
}

function formatPrice(price) {
  return groupNumber(price, 2);
}

function formatPercent(percent) {
  var value = finiteNumber(percent, NaN);
  if (!isFinite(value)) return "—";
  return (value > 0 ? "+" : "") + value.toFixed(2) + "%";
}

function formatChange(quote) {
  if (!quote) return "";
  var change = finiteNumber(quote.change, NaN);
  var percent = finiteNumber(quote.changePct, NaN);
  if (!isFinite(change)) return "—";
  var amount = (change > 0 ? "+" : "") + groupNumber(change, 2);
  return amount + (isFinite(percent) ? " (" + formatPercent(percent) + ")" : "");
}

function formatVolume(value) {
  var number = finiteNumber(value, NaN);
  if (!isFinite(number) || number < 0) return "—";
  if (number >= 1e12) return (number / 1e12).toFixed(2).replace(/0+$/, "").replace(/\.$/, "") + "T";
  if (number >= 1e9) return (number / 1e9).toFixed(2).replace(/0+$/, "").replace(/\.$/, "") + "B";
  if (number >= 1e6) return (number / 1e6).toFixed(2).replace(/0+$/, "").replace(/\.$/, "") + "M";
  if (number >= 1e3) return (number / 1e3).toFixed(2).replace(/0+$/, "").replace(/\.$/, "") + "K";
  return groupNumber(number, 0);
}

function formatMarketCap(value) {
  var number = finiteNumber(value, NaN);
  if (!isFinite(number)) return "—";
  if (number >= 1e12) return groupNumber(number / 1e12, 2) + "T";
  if (number >= 1e9) return groupNumber(number / 1e9, 2) + "B";
  if (number >= 1e6) return groupNumber(number / 1e6, 2) + "M";
  return groupNumber(number, 0);
}

function formatSupply(value, symbol) {
  var number = finiteNumber(value, NaN);
  if (!isFinite(number)) return "—";
  return formatVolume(number) + (symbol ? " " + displaySymbol(symbol) : "");
}

function ageMs(lastUpdatedMs, nowMs) {
  var last = finiteNumber(lastUpdatedMs, 0);
  if (last <= 0) return Infinity;
  return Math.max(0, finiteNumber(nowMs, Date.now()) - last);
}

function ageLabel(lastUpdatedMs, nowMs) {
  var age = ageMs(lastUpdatedMs, nowMs);
  if (!isFinite(age)) return "never";
  if (age < 60000) return "just now";
  var minutes = Math.floor(age / 60000);
  if (minutes < 60) return minutes + "m ago";
  var hours = Math.floor(minutes / 60);
  if (hours < 24) return hours + "h ago";
  var days = Math.floor(hours / 24);
  return days + "d ago";
}

function isStale(lastUpdatedMs, refreshMin, nowMs) {
  var age = ageMs(lastUpdatedMs, nowMs);
  var refresh = Math.max(1, finiteNumber(refreshMin, 5)) * 60000;
  return !isFinite(age) || age > refresh * 2;
}

if (typeof module !== "undefined") {
  module.exports = {
    CRYPTO_COIN_IDS: CRYPTO_COIN_IDS,
    CRYPTO_NAMES: CRYPTO_NAMES,
    parseChartResponse: parseChartResponse,
    parseQuoteLines: parseQuoteLines,
    parseChartSeries: parseChartSeries,
    parseBinanceTicker: parseBinanceTicker,
    parseBinanceLines: parseBinanceLines,
    parseBinanceKlines: parseBinanceKlines,
    isCryptoSymbol: isCryptoSymbol,
    displaySymbol: displaySymbol,
    normalizeSymbol: normalizeSymbol,
    marketStatus: marketStatus,
    marketStatusLabel: marketStatusLabel,
    formatPrice: formatPrice,
    formatPercent: formatPercent,
    formatChange: formatChange,
    formatVolume: formatVolume,
    formatMarketCap: formatMarketCap,
    formatSupply: formatSupply,
    defaultWatchlist: defaultWatchlist,
    addSymbol: addSymbol,
    removeSymbol: removeSymbol,
    moveSymbol: moveSymbol,
    coinIdForSymbol: coinIdForSymbol,
    coingeckoMarketsUrl: coingeckoMarketsUrl,
    parseCoinMarkets: parseCoinMarkets,
    parseCoinSearch: parseCoinSearch,
    enrichQuotes: enrichQuotes,
    cryptoIdsFromQuotes: cryptoIdsFromQuotes,
    binancePairFor: binancePairFor,
    binanceTickerUrl: binanceTickerUrl,
    binanceKlinesUrl: binanceKlinesUrl,
    enrichQuotesBinance: enrichQuotesBinance,
    binanceTradeUrlFor: binanceTradeUrlFor,
    yahooSearchUrl: yahooSearchUrl,
    parseYahooSearch: parseYahooSearch,
    coingeckoSearchUrl: coingeckoSearchUrl,
    yahooChartUrl: yahooChartUrl,
    ageMs: ageMs,
    ageLabel: ageLabel,
    isStale: isStale
  };
}

function binanceTradeUrlFor(symbol, coinIds) {
  var pair = binancePairFor(symbol, coinIds);
  if (!pair) return "";
  var match = pair.match(/^([A-Z0-9]+?)(USDT|BTC|ETH|BNB|EUR|TRY|BRL)$/);
  if (!match) return "https://www.binance.com/en/trade/" + encodeURIComponent(pair);
  return "https://www.binance.com/en/trade/" + match[1] + "_" + match[2] + "?type=spot";
}
