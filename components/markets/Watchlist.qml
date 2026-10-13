import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."
import "../../logic/MarketsModel.js" as MarketsModel

ColumnLayout {
  id: root
  property var service: null
  property string selectedSymbol: ""
  property bool searchOpen: false
  signal symbolSelected(string symbol)

  spacing: Style.space(8)
  Layout.fillWidth: true

  readonly property var quotes: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.quotes || [];
  }
  readonly property var selected: {
    for (var i = 0; i < root.quotes.length; i++)
      if (root.quotes[i].symbol === root.selectedSymbol) return root.quotes[i];
    return root.quotes.length > 0 ? root.quotes[0] : null;
  }

  function currencySuffix(quote) {
    if (!quote) return "";
    var shown = String(quote.displayCurrency || quote.currency || "");
    var requested = String(quote.requestedCurrency || (root.service ? root.service.currency : "USD"));
    return shown !== "" && requested !== "" && shown !== requested ? " " + shown : "";
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.fillWidth: true

    Text {
      textFormat: Text.PlainText
      text: "WATCHLIST"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
    }
    Item { Layout.fillWidth: true }
    Text {
      textFormat: Text.PlainText
      text: {
        if (!root.service) return "Updated never";
        void root.service.revision;
        return "Updated " + root.service.marketsAgeLabel();
      }
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
    FlowIconButton {
      glyph: "\uDB81\uDC50"
      tip: "Refresh market quotes"
      onClicked: if (root.service) root.service.marketsRefresh()
    }
    FlowIconButton {
      glyph: "\uDB81\uDC15"
      tip: "Add symbol"
      highlighted: root.searchOpen
      onClicked: root.searchOpen = !root.searchOpen
    }
  }

  SymbolSearch {
    visible: root.searchOpen
    service: root.service
    Layout.fillWidth: true
    onClose: root.searchOpen = false
    onSymbolAdded: function(symbol) { root.symbolSelected(symbol); }
  }

  ListView {
    id: watchlist
    model: root.quotes
    spacing: Style.space(3)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(Style.space(168), Math.max(Style.space(36), contentHeight))

    delegate: Rectangle {
      id: quoteRow
      required property int index
      required property var modelData
      width: watchlist.width
      implicitHeight: Style.space(30)
      radius: Style.cornerRadius
      color: modelData.symbol === (root.selected ? root.selected.symbol : root.selectedSymbol)
        ? Util.alpha(Color.accent, 0.16)
        : (rowMouse.containsMouse ? Util.alpha(Color.muted, 0.08) : "transparent")

      Drag.active: dragHandle.drag.active
      Drag.keys: ["kairos-market-symbol"]
      Drag.hotSpot.x: width / 2
      Drag.hotSpot.y: height / 2

      DropArea {
        anchors.fill: parent
        keys: ["kairos-market-symbol"]
        onDropped: function(drop) {
          if (!root.service || !drop.source || drop.source.index === quoteRow.index) return;
          root.service.watchlistMove(drop.source.index, quoteRow.index);
          drop.acceptProposedAction();
        }
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.space(6)
        anchors.rightMargin: Style.space(8)
        spacing: Style.space(7)

        MouseArea {
          id: dragHandle
          Layout.preferredWidth: Style.space(18)
          Layout.fillHeight: true
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.SizeVerCursor
          drag.target: quoteRow
          drag.axis: Drag.YAxis
          drag.threshold: Style.space(4)
          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: "\uDB83\uDE75"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        Text {
          textFormat: Text.PlainText
          text: MarketsModel.displaySymbol(modelData.symbol)
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.weight: Font.DemiBold
          elide: Text.ElideRight
          Layout.preferredWidth: Style.space(62)
        }
        Text {
          textFormat: Text.PlainText
          text: modelData.name || ""
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
        Text {
          visible: MarketsModel.marketStatus(modelData, Date.now()) === "closed"
          textFormat: Text.PlainText
          text: "\uDB81\uDD94"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        Text {
          textFormat: Text.PlainText
          text: (modelData.priceText || (isFinite(Number(modelData.price)) ? MarketsModel.formatPrice(modelData.price) : "—"))
            + root.currencySuffix(modelData)
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          Layout.preferredWidth: Style.space(88)
          horizontalAlignment: Text.AlignRight
        }
        Text {
          textFormat: Text.PlainText
          text: (modelData.changeText || MarketsModel.formatChange(modelData)) + root.currencySuffix(modelData)
          color: Number(modelData.change) < 0 ? Color.urgent : Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          Layout.preferredWidth: Style.space(110)
          horizontalAlignment: Text.AlignRight
          elide: Text.ElideLeft
        }
      }

      MouseArea {
        id: rowMouse
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.symbolSelected(modelData.symbol)
      }
    }
  }

  Text {
    visible: root.quotes.length === 0
    textFormat: Text.PlainText
    text: root.service && root.service.watchlist && root.service.watchlist.symbols.length === 0
      ? "Your watchlist is empty. Use Add symbol to begin."
      : root.service && root.service.marketsError ? root.service.marketsError : "Fetching quotes…"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    Layout.fillWidth: true
  }

  Text {
    visible: root.quotes.length > 0 && root.service && root.service.marketsError !== ""
    textFormat: Text.PlainText
    text: root.service ? root.service.marketsError : ""
    color: Color.urgent
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
  }

  Rectangle {
    height: Math.max(1, Style.space(1))
    color: Color.popups.border
    opacity: 0.5
    Layout.fillWidth: true
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.fillWidth: true
    Text {
      textFormat: Text.PlainText
      text: root.selected ? MarketsModel.displaySymbol(root.selected.symbol) + "  ·  " + root.selected.name : "Select a symbol"
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.weight: Font.DemiBold
      elide: Text.ElideRight
      Layout.fillWidth: true
    }
    Text {
      textFormat: Text.PlainText
      text: root.selected ? root.selected.source || "" : ""
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  Chart {
    service: root.service
    symbol: root.selected ? root.selected.symbol : ""
    Layout.fillWidth: true
    Layout.preferredHeight: Style.space(168)
  }

  KeyStats {
    quote: root.selected
    Layout.fillWidth: true
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.fillWidth: true

    CurrencyChip { service: root.service }
    Item { Layout.fillWidth: true }
    FlowButton {
      text: "Open on Binance"
      visible: !!(root.selected && root.selected.assetType === "crypto")
      enabledButton: visible
      onClicked: {
        if (root.service && root.selected)
          root.service.openUrl(root.service.binanceTradeUrl(root.selected.symbol));
      }
    }
    FlowButton {
      text: "Remove"
      enabledButton: !!root.selected
      onClicked: {
        if (root.service && root.selected) {
          var symbol = root.selected.symbol;
          root.service.watchlistRemove(symbol);
          root.symbolSelected("");
        }
      }
    }
  }
}
