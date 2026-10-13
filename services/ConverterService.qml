import QtQuick
import Quickshell
import Quickshell.Io
import "../logic/ConverterModel.js" as ConverterModel

Item {
  id: root
  property var service: null

  property var currencyRates: ({})
  property var cryptoPrices: ({})
  property double ratesFetchedAt: 0
  property double cryptoFetchedAt: 0
  property string ratesError: ""
  property string cryptoError: ""
  property bool ratesStale: false
  property bool cryptoStale: false
  property bool pendingRates: false
  property bool pendingCrypto: false
  property bool forceRatesPending: false
  property bool forceCryptoPending: false

  readonly property string ratesScript: localPath(Qt.resolvedUrl("../scripts/fetch-rates"))
  readonly property string cryptoScript: localPath(Qt.resolvedUrl("../scripts/fetch-crypto"))

  function localPath(url) {
    var value = String(url || "");
    if (value.indexOf("file://") === 0) value = value.substring(7);
    try { return decodeURIComponent(value); } catch (error) { return value; }
  }

  function cryptoIds() {
    var ids = [];
    for (var i = 0; i < ConverterModel.CRYPTO_LIST.length; i++) ids.push(ConverterModel.CRYPTO_LIST[i].id);
    return ids.join(",");
  }

  function refresh(force) {
    var forced = force === true;
    if (ratesProc.running) {
      root.pendingRates = true;
      root.forceRatesPending = root.forceRatesPending || forced;
    } else {
      ratesProc.output = "";
      ratesProc.command = forced ? [root.ratesScript, "USD", "--force"] : [root.ratesScript, "USD"];
      ratesProc.running = true;
    }
    if (cryptoProc.running) {
      root.pendingCrypto = true;
      root.forceCryptoPending = root.forceCryptoPending || forced;
    } else {
      cryptoProc.output = "";
      var cryptoCommand = [root.cryptoScript, root.cryptoIds()];
      if (forced) cryptoCommand.push("--force");
      cryptoProc.command = cryptoCommand;
      cryptoProc.running = true;
    }
  }

  function applyRates(raw, exitCode) {
    try {
      var data = JSON.parse(String(raw || ""));
      if (data && data.ok === true && data.rates && typeof data.rates === "object") {
        root.currencyRates = data.rates;
        root.ratesFetchedAt = Number(data.fetched_at) || Date.now();
        root.ratesStale = data.stale === true;
        root.ratesError = root.ratesStale ? "Using cached fiat rates." : "";
        root.bumpService();
        return;
      }
      root.ratesError = String(data && data.error || "Fiat exchange rates are unavailable.");
    } catch (error) {
      root.ratesError = exitCode === 0
        ? "The fiat-rate response could not be read."
        : "Fiat exchange rates are unavailable.";
    }
    root.ratesStale = root.ratesFetchedAt > 0;
    root.bumpService();
  }

  function applyCrypto(raw, exitCode) {
    try {
      var data = JSON.parse(String(raw || ""));
      if (data && data.ok === true && data.prices && typeof data.prices === "object") {
        root.cryptoPrices = data.prices;
        root.cryptoFetchedAt = Number(data.fetched_at) || Date.now();
        root.cryptoStale = data.stale === true;
        root.cryptoError = root.cryptoStale ? "Using cached crypto prices." : "";
        root.bumpService();
        return;
      }
      root.cryptoError = String(data && data.error || "Crypto conversion rates are unavailable.");
    } catch (error) {
      root.cryptoError = exitCode === 0
        ? "The crypto-rate response could not be read."
        : "Crypto conversion rates are unavailable.";
    }
    root.cryptoStale = root.cryptoFetchedAt > 0;
    root.bumpService();
  }

  function runPendingRates() {
    if (!root.pendingRates) return;
    var force = root.forceRatesPending;
    root.pendingRates = false;
    root.forceRatesPending = false;
    ratesProc.output = "";
    ratesProc.command = force ? [root.ratesScript, "USD", "--force"] : [root.ratesScript, "USD"];
    ratesProc.running = true;
  }

  function runPendingCrypto() {
    if (!root.pendingCrypto) return;
    var force = root.forceCryptoPending;
    root.pendingCrypto = false;
    root.forceCryptoPending = false;
    cryptoProc.output = "";
    var cryptoCommand = [root.cryptoScript, root.cryptoIds()];
    if (force) cryptoCommand.push("--force");
    cryptoProc.command = cryptoCommand;
    cryptoProc.running = true;
  }

  function bumpService() {
    if (root.service && typeof root.service.bump === "function") root.service.bump();
  }

  Process {
    id: ratesProc
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: ratesProc.output = text
    }
    onExited: function(exitCode) {
      var output = ratesProc.output;
      ratesProc.output = "";
      root.applyRates(output, exitCode);
      Qt.callLater(root.runPendingRates);
    }
  }

  Process {
    id: cryptoProc
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: cryptoProc.output = text
    }
    onExited: function(exitCode) {
      var output = cryptoProc.output;
      cryptoProc.output = "";
      root.applyCrypto(output, exitCode);
      Qt.callLater(root.runPendingCrypto);
    }
  }

  Timer {
    interval: 5 * 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh(false)
  }
}
