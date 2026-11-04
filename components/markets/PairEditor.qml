import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."
import "../../logic/NumberFormat.js" as NumberFormat
import "../../logic/ConverterModel.js" as ConverterModel

Item {
  id: root
  property var service: null
  property string mode: "fiat"
  property string category: "length"
  property string fromKey: ""
  property string toKey: ""
  property string fromValue: "1"
  property string toValue: ""
  property string lastEdited: "top"
  property string pickerSide: ""
  property bool syncing: false

  Layout.fillWidth: true
  implicitHeight: Style.space(400)

  function optionsForMode() {
    if (root.mode === "units") {
      var group = ConverterModel.UNIT_CATEGORIES[root.category];
      return group && Array.isArray(group.units) ? group.units : [];
    }
    var options = [];
    ConverterModel.MAJOR_CURRENCIES.forEach(function(code) {
      options.push({ id: code, label: code + " — " + (ConverterModel.CURRENCY_NAMES[code] || code), kind: "fiat" });
    });
    ConverterModel.CRYPTO_LIST.forEach(function(item) {
      options.push({ id: item.symbol, label: item.symbol + " — " + item.name + " (cripto)", kind: "crypto" });
    });
    return options;
  }

  function defaultPair() {
    if (root.mode === "units") {
      var units = ConverterModel.UNIT_CATEGORIES[root.category].units;
      return [units[0].id, units.length > 1 ? units[1].id : units[0].id];
    }
    return ["BTC", "USD"];
  }

  function setModeDefaults() {
    var pair = root.defaultPair();
    root.fromKey = pair[0];
    root.toKey = pair[1];
    root.fromValue = "1";
    root.lastEdited = "top";
    root.recalculate("top");
  }

  function keyLabel(key) {
    var options = root.optionsForMode();
    for (var i = 0; i < options.length; i++) if (options[i].id === key) return options[i].label;
    return String(key || "Choose");
  }

  function convertAmount(value) {
    var amount = NumberFormat.parseAmount(value);
    if (!isFinite(amount)) return NaN;
    if (root.mode === "units") return ConverterModel.convertUnit(amount, root.category, root.fromKey, root.toKey);
    if (!root.service || typeof root.service.convertCurrency !== "function") return NaN;
    return root.service.convertCurrency(amount, root.fromKey, root.toKey);
  }

  function recalculate(side) {
    if (root.syncing) return;
    var sourceSide = side === "bottom" ? "bottom" : "top";
    var value = sourceSide === "top" ? root.fromValue : root.toValue;
    var amount = NumberFormat.parseAmount(value);
    var result = NaN;
    if (isFinite(amount)) {
      var sourceKey = sourceSide === "top" ? root.fromKey : root.toKey;
      var targetKey = sourceSide === "top" ? root.toKey : root.fromKey;
      if (root.mode === "units") result = ConverterModel.convertUnit(amount, root.category, sourceKey, targetKey);
      else if (root.service && typeof root.service.convertCurrency === "function")
        result = root.service.convertCurrency(amount, sourceKey, targetKey);
    }
    root.lastEdited = sourceSide;
    root.syncing = true;
    if (sourceSide === "top") root.toValue = NumberFormat.formatResult(result);
    else root.fromValue = NumberFormat.formatResult(result);
    root.syncing = false;
  }

  function swapPair() {
    var key = root.fromKey;
    root.fromKey = root.toKey;
    root.toKey = key;
    root.recalculate(root.lastEdited);
  }

  function selectOption(value) {
    if (root.pickerSide === "from") root.fromKey = value;
    else if (root.pickerSide === "to") root.toKey = value;
    root.pickerSide = "";
    root.recalculate(root.lastEdited);
  }

  ColumnLayout {
    id: editorLayout
    anchors.fill: parent
    spacing: Style.space(8)

    Text {
      textFormat: Text.PlainText
      text: root.mode === "units" ? "UNIT CONVERTER" : "CONVERTER"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    Layout.fillWidth: true
  }

  UnitCategoryPicker {
    visible: root.mode === "units"
    category: root.category
    Layout.fillWidth: true
    onCategorySelected: function(selectedCategory) {
      root.category = selectedCategory;
      var pair = root.defaultPair();
      root.fromKey = pair[0];
      root.toKey = pair[1];
      root.recalculate(root.lastEdited);
    }
  }

  RowLayout {
    spacing: Style.space(6)
    Layout.fillWidth: true

    FlowInput {
      id: topField
      text: root.fromValue
      placeholder: "Amount"
      Layout.fillWidth: true
      onTextChanged: {
        if (root.syncing) return;
        root.fromValue = text;
        root.recalculate("top");
      }
      onAccepted: root.recalculate("top")
    }
    FlowButton {
      text: root.fromKey || "From"
      primary: true
      onClicked: {
        root.pickerSide = "from";
        optionSearch.text = "";
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.space(6)

    Item { Layout.fillWidth: true }
    FlowIconButton {
      glyph: "\uDB82\uDE0A"
      tip: "Swap conversion direction"
      onClicked: root.swapPair()
    }
    Item { Layout.fillWidth: true }
  }

  RowLayout {
    spacing: Style.space(6)
    Layout.fillWidth: true

    FlowInput {
      id: bottomField
      text: root.toValue
      placeholder: "Converted amount"
      Layout.fillWidth: true
      onTextChanged: {
        if (root.syncing) return;
        root.toValue = text;
        root.recalculate("bottom");
      }
      onAccepted: root.recalculate("bottom")
    }
    FlowButton {
      text: root.toKey || "To"
      primary: true
      onClicked: {
        root.pickerSide = "to";
        optionSearch.text = "";
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.space(6)
    Item { Layout.fillWidth: true }
    Text {
      textFormat: Text.PlainText
      text: {
        if (root.mode === "units") return "Local conversion · no network needed";
        if (root.service) {
          void root.service.revision;
          return root.service.converterStatus(root.mode);
        }
        return "Rates are unavailable.";
      }
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignRight
      Layout.fillWidth: true
      elide: Text.ElideRight
    }
  }

  }

  onModeChanged: root.setModeDefaults()
  Component.onCompleted: root.setModeDefaults()

  Connections {
    target: root.service
    function onCurrencyRatesChanged() { if (root.mode !== "units") root.recalculate(root.lastEdited); }
    function onCryptoPricesChanged() { if (root.mode !== "units") root.recalculate(root.lastEdited); }
  }

  Rectangle {
    id: optionOverlay
    visible: root.pickerSide !== ""
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.55)
    z: 30

    MouseArea {
      anchors.fill: parent
      onClicked: root.pickerSide = ""
    }

    Rectangle {
      id: optionCard
      anchors.centerIn: parent
      width: Math.max(0, Math.min(parent.width - Style.space(24), Style.space(400)))
      height: Math.max(0, Math.min(parent.height - Style.space(24), Style.space(340)))
      radius: Style.cornerRadius
      color: Color.popups.background
      border.color: Color.popups.border
      border.width: Math.max(1, Style.space(1))

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(12)
        spacing: Style.space(8)

        Text {
          textFormat: Text.PlainText
          text: "CHOOSE " + (root.pickerSide === "from" ? "SOURCE" : "TARGET")
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
          Layout.fillWidth: true
        }

        FlowInput {
          id: optionSearch
          placeholder: "Filter options"
          Layout.fillWidth: true
        }

        ListView {
          id: optionList
          clip: true
          spacing: Style.space(2)
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: root.optionsForMode().filter(function(item) {
            var query = String(optionSearch.text || "").trim().toLowerCase();
            return query === "" || String(item.id).toLowerCase().indexOf(query) !== -1
              || String(item.label).toLowerCase().indexOf(query) !== -1;
          })

          delegate: Rectangle {
            required property var modelData
            width: optionList.width
            implicitHeight: Style.space(34)
            radius: Style.cornerRadius
            color: optionMouse.containsMouse ? Util.alpha(Color.accent, 0.12) : "transparent"
            Text {
              anchors.fill: parent
              anchors.leftMargin: Style.space(8)
              anchors.rightMargin: Style.space(8)
              textFormat: Text.PlainText
              text: modelData.label
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              verticalAlignment: Text.AlignVCenter
              elide: Text.ElideRight
            }
            MouseArea {
              id: optionMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectOption(modelData.id)
            }
          }
        }
      }
    }
  }
}
