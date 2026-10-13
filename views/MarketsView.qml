import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components"
import "../components/markets"

Item {
  id: root
  property var service: null
  property string subTab: "watchlist"
  property string selectedSymbol: ""

  Layout.fillWidth: true
  Layout.fillHeight: true
  implicitHeight: Style.space(520)

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(8)

    RowLayout {
      spacing: Style.space(4)
      Layout.fillWidth: true
      Repeater {
        model: [
          { id: "watchlist", label: "Watchlist" },
          { id: "convert", label: "Convert" },
          { id: "crypto", label: "Crypto" },
          { id: "units", label: "Units" }
        ]
        delegate: Chip {
          required property var modelData
          Layout.fillWidth: true
          label: modelData.label
          active: root.subTab === modelData.id
          onClicked: root.subTab = modelData.id
        }
      }
    }

    Flickable {
      id: contentScroll
      clip: true
      contentWidth: width
      contentHeight: contentColumn.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      interactive: contentHeight > height
      Layout.fillWidth: true
      Layout.fillHeight: true

      ColumnLayout {
        id: contentColumn
        width: contentScroll.width
        spacing: Style.space(8)

        Watchlist {
          service: root.service
          selectedSymbol: root.selectedSymbol
          visible: root.subTab === "watchlist"
          Layout.fillWidth: true
          onSymbolSelected: function(symbol) { root.selectedSymbol = symbol; }
        }

        PairEditor {
          service: root.service
          mode: "fiat"
          visible: root.subTab === "convert"
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(390)
        }

        PairEditor {
          service: root.service
          mode: "crypto"
          visible: root.subTab === "crypto"
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(390)
        }

        PairEditor {
          service: root.service
          mode: "units"
          visible: root.subTab === "units"
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(430)
        }
      }
    }
  }
}
