import QtQuick
import QtQuick.Layouts
import qs.Commons
import "."
import "../../logic/MarketsModel.js" as MarketsModel

Item {
  id: root
  property var service: null
  property string symbol: ""
  property string range: "1d"

  Layout.fillWidth: true
  implicitHeight: Style.space(170)

  function ensureSeries() {
    if (root.service && root.symbol !== "" && typeof root.service.marketsFetchSeries === "function")
      root.service.marketsFetchSeries(root.symbol, root.range);
  }

  function paint() {
    var context = canvas.getContext("2d");
    if (!context) return;
    context.reset();
    context.clearRect(0, 0, canvas.width, canvas.height);
    var width = canvas.width;
    var height = canvas.height;
    if (!root.service || root.symbol === "") return;

    var data = root.service.marketsSeries(root.symbol, root.range);
    if (!data || data.length < 2) return;

    var min = Number(data[0].c);
    var max = Number(data[0].c);
    for (var i = 1; i < data.length; i++) {
      min = Math.min(min, Number(data[i].c));
      max = Math.max(max, Number(data[i].c));
    }
    if (!isFinite(min) || !isFinite(max)) return;
    if (max === min) {
      var padValue = Math.max(1, Math.abs(max) * 0.002);
      min -= padValue;
      max += padValue;
    }

    var padding = Style.space(8);
    var plotWidth = Math.max(1, width - padding * 2);
    var plotHeight = Math.max(1, height - padding * 2);
    var span = max - min;

    context.strokeStyle = Util.alpha(Color.muted, 0.14);
    context.lineWidth = Math.max(1, Style.space(1));
    context.beginPath();
    for (var grid = 1; grid <= 3; grid++) {
      var gridY = padding + plotHeight * grid / 4;
      context.moveTo(padding, gridY);
      context.lineTo(width - padding, gridY);
    }
    context.stroke();

    var quote = typeof root.service.quoteFor === "function" ? root.service.quoteFor(root.symbol) : null;
    context.strokeStyle = quote && Number(quote.change) < 0 ? Color.urgent : Color.accent;
    context.lineWidth = Math.max(1.5, Style.space(2));
    context.lineJoin = "round";
    context.lineCap = "round";
    context.beginPath();

    var firstTime = Number(data[0].t);
    var lastTime = Number(data[data.length - 1].t);
    var timeSpan = lastTime - firstTime;
    if (!isFinite(timeSpan) || timeSpan <= 0) timeSpan = data.length - 1;
    for (var point = 0; point < data.length; point++) {
      var x = timeSpan === data.length - 1 && lastTime === firstTime
        ? padding + point / (data.length - 1) * plotWidth
        : padding + (Number(data[point].t) - firstTime) / timeSpan * plotWidth;
      var y = padding + (max - Number(data[point].c)) / span * plotHeight;
      if (point === 0) context.moveTo(x, y);
      else context.lineTo(x, y);
    }
    context.stroke();
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(4)

    RangeSelector {
      currentRange: root.range
      onRangeSelected: function(selectedRange) {
        root.range = selectedRange;
        root.ensureSeries();
      }
      Layout.fillWidth: true
    }

    Rectangle {
      radius: Style.cornerRadius
      color: Util.alpha(Color.popups.background, 0.40)
      border.color: Color.popups.border
      border.width: Math.max(1, Style.space(1))
      Layout.fillWidth: true
      Layout.fillHeight: true

      Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: Style.space(4)
        onPaint: root.paint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
      }

      Text {
        anchors.centerIn: parent
        visible: {
          if (!root.service || root.symbol === "") return true;
          var revision = root.service.revision;
          revision;
          var values = root.service.marketsSeries(root.symbol, root.range);
          return !values || values.length < 2;
        }
        textFormat: Text.PlainText
        text: {
          if (root.service) void root.service.revision;
          if (root.symbol === "") return "Select a symbol to view its chart.";
          if (root.service && typeof root.service.marketsSeriesStatus === "function") {
            var error = root.service.marketsSeriesStatus();
            if (error) return error;
          }
          return "Loading chart data…";
        }
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  Connections {
    target: root.service
    function onRevisionChanged() { canvas.requestPaint(); }
  }

  onSymbolChanged: {
    root.ensureSeries();
    canvas.requestPaint();
  }
  onRangeChanged: canvas.requestPaint()
  Component.onCompleted: root.ensureSeries()
}
