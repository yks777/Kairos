import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../../logic/MarketsModel.js" as MarketsModel

ColumnLayout {
  id: root
  property var quote: null

  spacing: Style.space(4)
  Layout.fillWidth: true

  readonly property bool isCrypto: !!(root.quote && root.quote.assetType === "crypto")

  function currencySuffix() {
    if (!root.quote) return "";
    var shown = String(root.quote.displayCurrency || root.quote.currency || "");
    var requested = String(root.quote.requestedCurrency || shown);
    return shown !== "" && requested !== "" && shown !== requested ? " " + shown : "";
  }

  function money(value) { return MarketsModel.formatPrice(value) + root.currencySuffix(); }

  GridLayout {
    columns: 2
    columnSpacing: Style.space(14)
    rowSpacing: Style.space(3)
    Layout.fillWidth: true

    StatRow { label: "Open"; value: root.quote ? root.money(root.quote.open) : "—"; visible: !root.isCrypto }
    StatRow { label: "Prev close"; value: root.quote ? root.money(root.quote.prevClose) : "—"; visible: !root.isCrypto }
    StatRow { label: "Day high"; value: root.quote ? root.money(root.quote.dayHigh) : "—"; visible: !root.isCrypto }
    StatRow { label: "Day low"; value: root.quote ? root.money(root.quote.dayLow) : "—"; visible: !root.isCrypto }
    StatRow { label: "Volume"; value: root.quote ? MarketsModel.formatVolume(root.quote.volume) : "—"; visible: !root.isCrypto }
    StatRow {
      label: "52w range"
      value: root.quote ? root.money(root.quote.week52Low) + " – " + root.money(root.quote.week52High) : "—"
      visible: !root.isCrypto
    }

    StatRow { label: "Open"; value: root.quote ? root.money(root.quote.open) : "—"; visible: root.isCrypto }
    StatRow { label: "Prev close"; value: root.quote ? root.money(root.quote.prevClose) : "—"; visible: root.isCrypto }
    StatRow { label: "24h high"; value: root.quote ? root.money(root.quote.dayHigh) : "—"; visible: root.isCrypto }
    StatRow { label: "24h low"; value: root.quote ? root.money(root.quote.dayLow) : "—"; visible: root.isCrypto }
    StatRow { label: "Volume"; value: root.quote ? MarketsModel.formatVolume(root.quote.volume) + root.currencySuffix() : "—"; visible: root.isCrypto }
    StatRow { label: "Market cap"; value: root.quote ? MarketsModel.formatMarketCap(root.quote.marketCap) + root.currencySuffix() : "—"; visible: root.isCrypto }
    StatRow {
      label: "Circulating"
      value: root.quote ? MarketsModel.formatSupply(root.quote.circulatingSupply, root.quote.symbol) : "—"
      visible: root.isCrypto
    }
  }

  component StatRow: RowLayout {
    id: row
    property string label: ""
    property string value: ""
    spacing: Style.space(5)
    Layout.fillWidth: true

    Text {
      textFormat: Text.PlainText
      text: row.label
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      Layout.preferredWidth: Style.space(82)
    }
    Text {
      textFormat: Text.PlainText
      text: row.value
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
      Layout.fillWidth: true
    }
  }
}
