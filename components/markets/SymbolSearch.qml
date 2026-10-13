import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."

ColumnLayout {
  id: root
  property var service: null
  property string query: ""
  signal close()
  signal symbolAdded(string symbol)

  spacing: Style.space(6)
  Layout.fillWidth: true

  readonly property var results: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.searchResults || [];
  }
  readonly property bool searching: !!(root.service && root.service.searchBusy)

  RowLayout {
    spacing: Style.space(6)
    Layout.fillWidth: true

    FlowInput {
      id: input
      placeholder: "Add symbol or coin name…"
      text: root.query
      Layout.fillWidth: true
      onTextChanged: {
        root.query = text;
        searchDebounce.restart();
      }
      onAccepted: root.performSearch(text)
    }
    FlowIconButton {
      glyph: "\uf00d"
      tip: "Close symbol search"
      onClicked: root.close()
    }
  }

  Text {
    visible: root.searching
    textFormat: Text.PlainText
    text: "Searching Yahoo Finance and CoinGecko…"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    Layout.fillWidth: true
  }

  ListView {
    id: resultsList
    model: root.results
    spacing: Style.space(2)
    clip: true
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(Style.space(150), contentHeight)
    visible: root.results.length > 0

    delegate: Rectangle {
      required property var modelData
      width: resultsList.width
      implicitHeight: Style.space(34)
      radius: Style.cornerRadius
      color: resultMouse.containsMouse ? Util.alpha(Color.accent, 0.12) : "transparent"

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.space(8)
        anchors.rightMargin: Style.space(8)
        spacing: Style.space(8)
        Text {
          textFormat: Text.PlainText
          text: modelData.symbol
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          Layout.preferredWidth: Style.space(68)
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
          textFormat: Text.PlainText
          text: modelData.exchange || ""
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      MouseArea {
        id: resultMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (root.service) root.service.watchlistAdd(modelData.symbol, modelData.coinId || "");
          root.symbolAdded(modelData.symbol);
          root.close();
        }
      }
    }
  }

  Text {
    visible: !root.searching && root.query.trim() !== "" && root.results.length === 0
    textFormat: Text.PlainText
    text: root.service && root.service.searchError
      ? String(root.service.searchError) : "No matching symbols found."
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    Layout.fillWidth: true
  }

  Timer {
    id: searchDebounce
    interval: 350
    repeat: false
    onTriggered: root.performSearch(root.query)
  }

  function performSearch(value) {
    var queryValue = String(value || "").trim();
    root.query = queryValue;
    if (root.service && queryValue.length >= 1 && typeof root.service.searchSymbols === "function")
      root.service.searchSymbols(queryValue);
  }
}
