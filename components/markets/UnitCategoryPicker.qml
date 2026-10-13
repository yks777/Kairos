import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."
import "../../logic/ConverterModel.js" as ConverterModel

Flow {
  id: root
  property string category: "length"
  signal categorySelected(string category)

  spacing: Style.space(4)
  Layout.fillWidth: true

  Repeater {
    model: Object.keys(ConverterModel.UNIT_CATEGORIES)
    delegate: Chip {
      required property string modelData
      label: ConverterModel.UNIT_CATEGORIES[modelData].label
      active: root.category === modelData
      onClicked: root.categorySelected(modelData)
    }
  }
}
