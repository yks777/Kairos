import QtQuick
import Quickshell
import Quickshell.Io
import "../logic/MarketsModel.js" as MarketsModel

Item {
  id: root
  property var service: null

  property var quotes: []
  property var series: ({})
  property var seriesUpdatedAt: ({})
  property double lastFetch: 0
  property string lastError: ""
  property string seriesError: ""
  property var quoteQueue: []
  property bool refreshPending: false
  property string observedWatchlistKey: ""

  property var searchResults: []
  property bool searchBusy: false
  property string searchError: ""
  property string pendingSearchQuery: ""
  property string activeSearchQuery: ""
  property int searchGeneration: 0
  property int searchPendingCount: 0
  property var searchYahooRows: []
  property var searchCoinRows: []

  property var pendingSeries: null

  readonly property var watchlist: {
    if (root.service && root.service.settings && root.service.settings.markets
        && root.service.settings.markets.watchlist) return root.service.settings.markets.watchlist;
    return MarketsModel.defaultWatchlist();
  }

  readonly property var displayQuotes: {
    if (root.service) void root.service.revision;
    var currency = root.service && root.service.settings && root.service.settings.markets
      ? String(root.service.settings.markets.currency || "USD").toUpperCase() : "USD";
    var output = [];
    for (var i = 0; i < root.quotes.length; i++) {
      var source = root.quotes[i] || {};
      var quote = {};
      for (var field in source) if (Object.prototype.hasOwnProperty.call(source, field)) quote[field] = source[field];
      var sourceCurrency = String(source.currency || "USD").toUpperCase();
      if (!/^[A-Z]{3}$/.test(sourceCurrency)) sourceCurrency = "USD";
      var displayCurrency = currency === sourceCurrency ? currency : sourceCurrency;
      var priceConverted = false;
      if (currency !== sourceCurrency && root.service && typeof root.service.convertCurrency === "function") {
        var numericFields = ["price", "change", "open", "prevClose", "dayHigh", "dayLow", "week52Low", "week52High", "marketCap"];
        for (var fieldIndex = 0; fieldIndex < numericFields.length; fieldIndex++) {
          var key = numericFields[fieldIndex];
          var value = Number(source[key]);
          if (!isFinite(value)) continue;
          var fieldCurrency = key === "marketCap" ? "USD" : sourceCurrency;
          var converted = root.service.convertCurrency(value, fieldCurrency, currency);
          if (converted !== null && converted !== undefined && converted !== ""
              && isFinite(Number(converted))) {
            quote[key] = Number(converted);
            if (key === "price") priceConverted = true;
          }
        }
        if (source.assetType === "crypto" && isFinite(Number(source.volume))) {
          var convertedVolume = root.service.convertCurrency(Number(source.volume), sourceCurrency, currency);
          if (convertedVolume !== null && convertedVolume !== undefined && convertedVolume !== ""
              && isFinite(Number(convertedVolume))) {
            quote.volume = Number(convertedVolume);
          }
        }
      }
      if (priceConverted) displayCurrency = currency;
      quote.priceText = isFinite(Number(quote.price)) ? MarketsModel.formatPrice(quote.price) : "—";
      quote.changeText = MarketsModel.formatChange(quote);
      quote.displayCurrency = displayCurrency;
      quote.requestedCurrency = currency;
      output.push(quote);
    }
    return output;
  }

  function curlCommand(url) {
    if (!url || String(url).indexOf("https://") !== 0) return [];
    return [
      "curl", "--fail", "--silent", "--location",
      "--connect-timeout", "5", "--max-time", "10",
      "--user-agent", "Mozilla/5.0 (X11; Linux x86_64) Kairos/1.0",
      "--", String(url)
    ];
  }

  function copyObject(value) {
    var output = {};
    if (value && typeof value === "object")
      for (var key in value) if (Object.prototype.hasOwnProperty.call(value, key)) output[key] = value[key];
    return output;
  }

  function existingQuote(symbol) {
    for (var i = 0; i < root.quotes.length; i++)
      if (root.quotes[i].symbol === symbol) return root.quotes[i];
    return null;
  }

  function replaceQuote(symbol, parsed, fallbackType) {
    var previous = root.existingQuote(symbol) || {};
    var result = {};
    for (var key in previous) if (Object.prototype.hasOwnProperty.call(previous, key)) result[key] = previous[key];
    if (parsed) for (var field in parsed) if (Object.prototype.hasOwnProperty.call(parsed, field)) result[field] = parsed[field];
    result.symbol = symbol;
    result.name = String(result.name || previous.name || MarketsModel.CRYPTO_NAMES[symbol] || symbol);
    result.assetType = result.assetType || fallbackType || "stock";
    result.currency = String(result.currency || "USD").toUpperCase();
    if (!/^[A-Z]{3}$/.test(result.currency)) result.currency = "USD";
    if (result.assetType === "crypto") result.coinId = result.coinId || MarketsModel.coinIdForSymbol(symbol, root.watchlist.coinIds);
    var rows = root.quotes.slice();
    var found = false;
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].symbol === symbol) { rows[i] = result; found = true; break; }
    }
    if (!found) rows.push(result);
    root.quotes = rows;
  }

  function seedQuoteRows(symbols) {
    var rows = [];
    var coins = root.watchlist && root.watchlist.coinIds ? root.watchlist.coinIds : {};
    for (var i = 0; i < symbols.length; i++) {
      var symbol = MarketsModel.normalizeSymbol(symbols[i]);
      if (!symbol) continue;
      var previous = root.existingQuote(symbol);
      if (previous) {
        rows.push(previous);
      } else {
        var crypto = MarketsModel.isCryptoSymbol(symbol, coins);
        rows.push({
          symbol: symbol,
          name: MarketsModel.CRYPTO_NAMES[symbol] || symbol,
          assetType: crypto ? "crypto" : "stock",
          source: "",
          price: NaN,
          change: NaN,
          changePct: NaN,
          open: NaN,
          prevClose: NaN,
          dayHigh: NaN,
          dayLow: NaN,
          volume: NaN,
          week52Low: NaN,
          week52High: NaN,
          marketCap: NaN,
          circulatingSupply: NaN,
          coinId: MarketsModel.coinIdForSymbol(symbol, coins),
          updatedAt: 0
        });
      }
    }
    root.quotes = rows;
  }

  function refresh() {
    if (quoteProc.running || coinMarketsProc.running) {
      root.refreshPending = true;
      return;
    }
    root.refreshPending = false;
    var symbols = root.watchlist && Array.isArray(root.watchlist.symbols) ? root.watchlist.symbols.slice(0, 50) : [];
    root.seedQuoteRows(symbols);
    root.lastError = "";
    if (symbols.length === 0) {
      root.quotes = [];
      root.lastFetch = Date.now();
      root.bumpService();
      return;
    }
    var nextQueue = [];
    for (var i = 0; i < symbols.length; i++) {
      var symbol = MarketsModel.normalizeSymbol(symbols[i]);
      if (!symbol) continue;
      nextQueue.push({
        symbol: symbol,
        assetType: MarketsModel.isCryptoSymbol(symbol, root.watchlist.coinIds) ? "crypto" : "stock",
        coinId: MarketsModel.coinIdForSymbol(symbol, root.watchlist.coinIds)
      });
    }
    root.quoteQueue = nextQueue;
    root.startNextQuote();
  }

  function startNextQuote() {
    if (quoteProc.running) return;
    if (root.quoteQueue.length === 0) {
      root.fetchCoinMarkets();
      return;
    }
    var pending = root.quoteQueue.slice();
    var item = pending.shift();
    root.quoteQueue = pending;
    quoteProc.symbol = item.symbol;
    quoteProc.assetType = item.assetType;
    quoteProc.coinId = item.coinId;
    quoteProc.output = "";
    var url = item.assetType === "crypto"
      ? MarketsModel.binanceTickerUrl(MarketsModel.binancePairFor(item.symbol, root.watchlist.coinIds))
      : MarketsModel.yahooChartUrl(item.symbol, "1d", "1m");
    var command = root.curlCommand(url);
    if (command.length === 0) {
      root.lastError = "This symbol does not have a supported market data source.";
      Qt.callLater(root.startNextQuote);
      return;
    }
    quoteProc.command = command;
    quoteProc.running = true;
  }

  function fetchCoinMarkets() {
    var ids = MarketsModel.cryptoIdsFromQuotes(root.quotes, root.watchlist.coinIds);
    if (ids.length === 0) {
      root.finishRefresh();
      return;
    }
    coinMarketsProc.output = "";
    coinMarketsProc.command = root.curlCommand(MarketsModel.coingeckoMarketsUrl(ids));
    if (coinMarketsProc.command.length === 0) {
      root.finishRefresh();
      return;
    }
    coinMarketsProc.running = true;
  }

  function finishRefresh() {
    root.lastFetch = Date.now();
    if (root.quotes.length > 0) {
      var valid = false;
      for (var i = 0; i < root.quotes.length; i++) {
        if (isFinite(Number(root.quotes[i].price)) && Number(root.quotes[i].price) > 0) { valid = true; break; }
      }
      if (!valid && root.lastError === "") root.lastError = "Market quotes are temporarily unavailable.";
    }
    root.bumpService();
    if (root.refreshPending) {
      root.refreshPending = false;
      Qt.callLater(root.refresh);
    }
  }

  function fetchSeries(symbol, range) {
    var keySymbol = MarketsModel.normalizeSymbol(symbol);
    var keyRange = String(range || "1d");
    if (!keySymbol) return;
    var key = keySymbol + "|" + keyRange;
    var cachedAt = Number(root.seriesUpdatedAt[key]) || 0;
    if (root.series[key] && !MarketsModel.isStale(cachedAt, 15, Date.now())) return;
    if (seriesProc.running) {
      root.pendingSeries = { symbol: keySymbol, range: keyRange };
      return;
    }
    root.startSeries(keySymbol, keyRange);
  }

  function startSeries(symbol, range) {
    root.seriesError = "";
    var crypto = MarketsModel.isCryptoSymbol(symbol, root.watchlist.coinIds);
    var url = crypto
      ? MarketsModel.binanceKlinesUrl(symbol, range, root.watchlist.coinIds)
      : MarketsModel.yahooChartUrl(symbol, range);
    var command = root.curlCommand(url);
    if (command.length === 0) {
      root.seriesError = "Chart data is unavailable for this symbol.";
      root.bumpService();
      return;
    }
    seriesProc.symbol = symbol;
    seriesProc.range = range;
    seriesProc.assetType = crypto ? "crypto" : "stock";
    seriesProc.output = "";
    seriesProc.command = command;
    seriesProc.running = true;
  }

  function seriesFor(symbol, range) {
    return root.series[String(symbol || "") + "|" + String(range || "1d")] || [];
  }

  function startPendingSeries() {
    if (seriesProc.running || !root.pendingSeries) return;
    var pending = root.pendingSeries;
    root.pendingSeries = null;
    root.fetchSeries(pending.symbol, pending.range);
  }

  function searchSymbols(query) {
    var value = String(query || "").trim().slice(0, 80);
    root.searchGeneration++;
    if (value === "") {
      root.pendingSearchQuery = "";
      root.searchBusy = false;
      root.searchResults = [];
      root.searchError = "";
      root.bumpService();
      return;
    }
    if (yahooSearchProc.running || coinSearchProc.running) {
      root.pendingSearchQuery = value;
      root.searchBusy = true;
      return;
    }
    root.beginSearch(value, root.searchGeneration);
  }

  function beginSearch(query, generation) {
    root.activeSearchQuery = query;
    root.pendingSearchQuery = "";
    root.searchBusy = true;
    root.searchError = "";
    root.searchPendingCount = 2;
    root.searchYahooRows = [];
    root.searchCoinRows = [];
    yahooSearchProc.query = query;
    yahooSearchProc.generation = generation;
    yahooSearchProc.output = "";
    yahooSearchProc.command = root.curlCommand(MarketsModel.yahooSearchUrl(query));
    coinSearchProc.query = query;
    coinSearchProc.generation = generation;
    coinSearchProc.output = "";
    coinSearchProc.command = root.curlCommand(MarketsModel.coingeckoSearchUrl(query));
    if (yahooSearchProc.command.length > 0) yahooSearchProc.running = true;
    else root.applySearchPart("yahoo", generation, [], 1);
    if (coinSearchProc.command.length > 0) coinSearchProc.running = true;
    else root.applySearchPart("coin", generation, [], 1);
  }

  function applySearchPart(source, generation, rows, exitCode) {
    if (generation !== root.searchGeneration) {
      if (!yahooSearchProc.running && !coinSearchProc.running && root.pendingSearchQuery !== "")
        Qt.callLater(root.startPendingSearch);
      return;
    }
    if (source === "yahoo") root.searchYahooRows = exitCode === 0 ? rows : [];
    else root.searchCoinRows = exitCode === 0 ? rows : [];
    root.searchPendingCount = Math.max(0, root.searchPendingCount - 1);
    if (root.searchPendingCount !== 0) return;
    root.searchResults = root.mergeSearchResults(root.searchYahooRows, root.searchCoinRows);
    root.searchBusy = false;
    root.searchError = root.searchResults.length === 0 ? "Search is unavailable or returned no matches." : "";
    root.bumpService();
    if (root.pendingSearchQuery !== "") Qt.callLater(root.startPendingSearch);
  }

  function mergeSearchResults(yahooRows, coinRows) {
    var output = [];
    var indexes = {};
    var stocks = Array.isArray(yahooRows) ? yahooRows : [];
    var coins = Array.isArray(coinRows) ? coinRows : [];
    for (var i = 0; i < stocks.length; i++) {
      var item = copyObject(stocks[i]);
      var key = String(item.symbol || "").toUpperCase() + "|" + String(item.assetType || "stock");
      indexes[key] = output.length;
      output.push(item);
    }
    for (var j = 0; j < coins.length; j++) {
      var coin = copyObject(coins[j]);
      var coinKey = String(coin.symbol || "").toUpperCase() + "|crypto";
      if (Object.prototype.hasOwnProperty.call(indexes, coinKey)) {
        output[indexes[coinKey]].coinId = coin.coinId;
        if (!output[indexes[coinKey]].name || output[indexes[coinKey]].name === output[indexes[coinKey]].symbol)
          output[indexes[coinKey]].name = coin.name;
      } else {
        indexes[coinKey] = output.length;
        output.push(coin);
      }
    }
    return output.slice(0, 20);
  }

  function startPendingSearch() {
    if (yahooSearchProc.running || coinSearchProc.running || root.pendingSearchQuery === "") return;
    var value = root.pendingSearchQuery;
    root.pendingSearchQuery = "";
    root.beginSearch(value, root.searchGeneration);
  }

  function refreshSearch() {
    if (root.service) root.service.bump();
  }

  function watchlistKey() {
    try { return JSON.stringify(root.watchlist); } catch (error) { return "{}"; }
  }

  function handleWatchlistChanged() {
    var next = root.watchlistKey();
    if (next === root.observedWatchlistKey) return;
    root.observedWatchlistKey = next;
    root.refresh();
  }

  function bumpService() {
    if (root.service && typeof root.service.bump === "function") root.service.bump();
  }

  Process {
    id: quoteProc
    property string symbol: ""
    property string assetType: "stock"
    property string coinId: ""
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: quoteProc.output = text
    }
    onExited: function(exitCode) {
      var output = quoteProc.output;
      var symbol = quoteProc.symbol;
      var assetType = quoteProc.assetType;
      var coinId = quoteProc.coinId;
      quoteProc.output = "";
      var parsed = null;
      if (exitCode === 0) {
        if (assetType === "crypto") {
          var ticker = MarketsModel.parseBinanceTicker(output);
          if (ticker) {
            parsed = {
              symbol: symbol,
              name: MarketsModel.CRYPTO_NAMES[symbol] || symbol,
              assetType: "crypto",
              source: "Binance",
              price: ticker.price,
              change: ticker.change,
              changePct: ticker.changePct,
              open: ticker.open,
              prevClose: ticker.prevClose,
              dayHigh: ticker.dayHigh,
              dayLow: ticker.dayLow,
              volume: ticker.volume,
              updatedAt: ticker.updatedAt,
              coinId: coinId || MarketsModel.coinIdForSymbol(symbol, root.watchlist.coinIds)
            };
          }
        } else {
          parsed = MarketsModel.parseChartResponse(output, symbol);
          if (parsed) parsed.source = "Yahoo Finance";
        }
      }
      if (parsed) root.replaceQuote(symbol, parsed, assetType);
      else if (exitCode !== 0 && root.lastError === "") root.lastError = "One or more market data sources could not be reached.";
      else if (exitCode === 0 && root.lastError === "") root.lastError = "A market response could not be parsed.";
      root.bumpService();
      Qt.callLater(root.startNextQuote);
    }
  }

  Process {
    id: coinMarketsProc
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: coinMarketsProc.output = text
    }
    onExited: function(exitCode) {
      var parsed = exitCode === 0 ? MarketsModel.parseCoinMarkets(coinMarketsProc.output) : [];
      coinMarketsProc.output = "";
      if (parsed.length > 0) root.quotes = MarketsModel.enrichQuotes(root.quotes, parsed);
      root.finishRefresh();
    }
  }

  Process {
    id: seriesProc
    property string symbol: ""
    property string range: "1d"
    property string assetType: "stock"
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: seriesProc.output = text
    }
    onExited: function(exitCode) {
      var symbol = seriesProc.symbol;
      var range = seriesProc.range;
      var key = symbol + "|" + range;
      var output = seriesProc.output;
      seriesProc.output = "";
      var points = [];
      if (exitCode === 0) points = seriesProc.assetType === "crypto"
        ? MarketsModel.parseBinanceKlines(output) : MarketsModel.parseChartSeries(output, range);
      if (points.length > 1) {
        var next = root.copyObject(root.series);
        next[key] = points;
        root.series = next;
        var updated = root.copyObject(root.seriesUpdatedAt);
        updated[key] = Date.now();
        root.seriesUpdatedAt = updated;
        root.seriesError = "";
      } else {
        root.seriesError = "Chart data is not available for this range.";
      }
      root.bumpService();
      Qt.callLater(root.startPendingSeries);
    }
  }

  Process {
    id: yahooSearchProc
    property string query: ""
    property int generation: 0
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: yahooSearchProc.output = text
    }
    onExited: function(exitCode) {
      var generation = yahooSearchProc.generation;
      var output = yahooSearchProc.output;
      yahooSearchProc.output = "";
      root.applySearchPart("yahoo", generation,
        exitCode === 0 ? MarketsModel.parseYahooSearch(output) : [], exitCode);
    }
  }

  Process {
    id: coinSearchProc
    property string query: ""
    property int generation: 0
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: coinSearchProc.output = text
    }
    onExited: function(exitCode) {
      var generation = coinSearchProc.generation;
      var output = coinSearchProc.output;
      coinSearchProc.output = "";
      root.applySearchPart("coin", generation,
        exitCode === 0 ? MarketsModel.parseCoinSearch(output) : [], exitCode);
    }
  }

  Timer {
    id: refreshTimer
    interval: Math.max(1, Number(root.service && root.service.settings && root.service.settings.markets
      ? root.service.settings.markets.refreshMinutes : 5) || 5) * 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Connections {
    target: root.service
    function onSettingsChanged() { root.handleWatchlistChanged(); }
    function onStateLoadedChanged() {
      if (root.service && root.service.stateLoaded) root.handleWatchlistChanged();
    }
  }

  Component.onCompleted: {
    root.observedWatchlistKey = root.watchlistKey();
    if (root.service && root.service.stateLoaded) root.refresh();
  }
}
