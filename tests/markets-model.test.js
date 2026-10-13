const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const MarketsModel = loadQmlLibrary("logic/MarketsModel.js");

test("crypto symbols and display formatting handle common quote suffixes", () => {
  assert.equal(MarketsModel.isCryptoSymbol("BTC"), true);
  assert.equal(MarketsModel.isCryptoSymbol("BTC-USD"), true);
  assert.equal(MarketsModel.isCryptoSymbol("AAPL"), false);
  assert.equal(MarketsModel.displaySymbol("BTC-USD"), "BTC");
  assert.equal(MarketsModel.displaySymbol("BTC-EUR"), "BTC/EUR");
  assert.equal(MarketsModel.normalizeSymbol("btc-usd"), "BTC");
});

test("price, percent, change, volume, and market-cap formatting are stable", () => {
  assert.equal(MarketsModel.formatPrice(104250), "104,250.00");
  assert.equal(MarketsModel.formatPercent(1.21), "+1.21%");
  assert.equal(MarketsModel.formatChange({ change: 1250, changePct: 1.21 }), "+1,250.00 (+1.21%)");
  assert.equal(MarketsModel.formatVolume(1200000000), "1.2B");
  assert.equal(MarketsModel.formatMarketCap(2050000000000), "2.05T");
});

test("market session reports regular US hours as open and the evening as closed", () => {
  const quote = { assetType: "stock", marketState: "" };
  const weekdayOpen = Date.UTC(2026, 5, 15, 18, 0, 0); // 14:00 EDT on Monday
  const weekdayClosed = Date.UTC(2026, 5, 15, 21, 0, 0); // 17:00 EDT on Monday
  const weekend = Date.UTC(2026, 5, 14, 18, 0, 0);
  assert.equal(MarketsModel.marketStatus(quote, weekdayOpen), "open");
  assert.equal(MarketsModel.marketStatus(quote, weekdayClosed), "closed");
  assert.equal(MarketsModel.marketStatus(quote, weekend), "closed");
  assert.equal(MarketsModel.marketStatus({ assetType: "crypto" }, weekend), "open");
});

test("watchlist add normalizes and deduplicates symbols and preserves CoinGecko ids", () => {
  const initial = MarketsModel.defaultWatchlist();
  const same = MarketsModel.addSymbol(initial, "aapl");
  assert.deepEqual(same.symbols, ["AAPL", "NVDA", "BTC"]);
  const next = MarketsModel.addSymbol(initial, "DOGE-USD", "dogecoin");
  assert.deepEqual(next.symbols, ["AAPL", "NVDA", "BTC", "DOGE"]);
  assert.equal(next.coinIds.DOGE, "dogecoin");
  const removed = MarketsModel.removeSymbol(next, "DOGE");
  assert.equal(removed.symbols.includes("DOGE"), false);
  assert.equal(removed.coinIds.DOGE, undefined);
});

test("watchlist reorder moves a symbol to the requested position", () => {
  const initial = { symbols: ["AAPL", "NVDA", "BTC"], coinIds: {} };
  const moved = MarketsModel.moveSymbol(initial, 2, 0);
  assert.deepEqual(moved.symbols, ["BTC", "AAPL", "NVDA"]);
  assert.deepEqual(initial.symbols, ["AAPL", "NVDA", "BTC"]);
});

test("Binance pair and trade URL use the selected crypto quote", () => {
  assert.equal(MarketsModel.binancePairFor("BTC-USD"), "BTCUSDT");
  assert.equal(MarketsModel.binancePairFor("ETH"), "ETHUSDT");
  assert.equal(MarketsModel.binanceTradeUrlFor("BTC-USD"), "https://www.binance.com/en/trade/BTC_USDT?type=spot");
});

test("age labels are readable and stale detection uses twice the refresh interval", () => {
  const now = 2000000000000;
  assert.equal(MarketsModel.ageLabel(now - 1000, now), "just now");
  assert.equal(MarketsModel.ageLabel(now - 2 * 60000, now), "2m ago");
  assert.equal(MarketsModel.isStale(now - 9 * 60000, 5, now), false);
  assert.equal(MarketsModel.isStale(now - 11 * 60000, 5, now), true);
  assert.equal(MarketsModel.isStale(0, 5, now), true);
});

test("Yahoo intraday chart data is trimmed to the selected one- and four-hour range", () => {
  const start = 1700000000;
  const payload = {
    chart: { result: [{
      timestamp: [0, 1, 2, 3, 4, 5].map((hour) => start + hour * 3600),
      indicators: { quote: [{ close: [10, 11, 12, 13, 14, 15] }] }
    }] }
  };
  assert.deepEqual(MarketsModel.parseChartSeries(payload, "1h").map((point) => point.c), [14, 15]);
  assert.deepEqual(MarketsModel.parseChartSeries(payload, "4h").map((point) => point.c), [11, 12, 13, 14, 15]);
  assert.equal(MarketsModel.parseChartSeries(payload, "1d").length, 6);
});

test("Yahoo chart and Binance ticker responses are parsed into quote data", () => {
  const yahoo = MarketsModel.parseChartResponse(JSON.stringify({
    chart: { result: [{
      meta: {
        symbol: "PETR4.SA", longName: "Petrobras", currency: "BRL", regularMarketPrice: 38,
        chartPreviousClose: 37, regularMarketOpen: 37.5, regularMarketDayHigh: 39,
        regularMarketDayLow: 36, regularMarketVolume: 1000,
        fiftyTwoWeekLow: 25, fiftyTwoWeekHigh: 42, marketState: "REGULAR"
      },
      indicators: { quote: [{ open: [37.5], high: [39], low: [36], close: [38], volume: [1000] }] }
    }] }
  }), "PETR4.SA");
  assert.equal(yahoo.name, "Petrobras");
  assert.equal(yahoo.currency, "BRL");
  assert.equal(yahoo.price, 38);
  assert.equal(yahoo.change, 1);
  assert.equal(yahoo.changePct, 1 / 37 * 100);

  const binance = MarketsModel.parseBinanceTicker(JSON.stringify({
    symbol: "BTCUSDT", lastPrice: "104250", priceChange: "1250", priceChangePercent: "1.21",
    openPrice: "103000", highPrice: "104800", lowPrice: "102500", volume: "12000",
    quoteVolume: "1200000000", closeTime: 2000000000000
  }));
  assert.equal(binance.price, 104250);
  assert.equal(binance.changePct, 1.21);
  assert.equal(binance.volume, 1200000000);
});
