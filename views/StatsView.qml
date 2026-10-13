import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components"
import "../logic/Model.js" as Model

Item {
  id: root

  property var service: null
  property string range: "today"
  property string kind: "both"

  Layout.fillWidth: true
  Layout.fillHeight: true
  implicitHeight: Style.space(540)

  readonly property var today: {
    if (!root.service) return null;
    void root.service.revision;
    void root.service.tickVersion;
    return root.service.todaySummary();
  }
  readonly property var week: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.weekData();
  }
  readonly property var heatmap: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.heatmapData(12);
  }
  readonly property var hist: {
    if (!root.service) return [];
    void root.service.revision;
    return root.service.history(root.range, root.kind);
  }
  readonly property int weekMax: {
    var maximum = 60;
    for (var i = 0; i < root.week.length; i++) maximum = Math.max(maximum, Number(root.week[i].focusSec) || 0);
    return maximum;
  }

  function formatDuration(seconds) {
    var value = Math.max(0, Math.floor(Number(seconds) || 0));
    return value === 0 ? "0m" : Model.formatDur(value);
  }

  Flickable {
    id: scroll
    anchors.fill: parent
    clip: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    interactive: contentHeight > height

    ColumnLayout {
      id: contentColumn
      width: scroll.width
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        text: "TODAY"
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
        Layout.fillWidth: true
      }

      GridLayout {
        columns: 3
        rowSpacing: Style.space(6)
        columnSpacing: Style.space(6)
        Layout.fillWidth: true

        StatCard { value: root.today ? Model.formatDur(root.today.focusSec) : "—"; label: "Focus" }
        StatCard { value: root.today ? String(root.today.pomoCount) : "—"; label: "Pomodoro" }
        StatCard { value: root.today ? String(root.today.flowCount) : "—"; label: "Flowtime" }
        StatCard { value: root.today ? String(root.today.tasksDone) : "—"; label: "Tasks done" }
        StatCard { value: root.today ? String(root.today.interruptions) : "—"; label: "Interruptions" }
        StatCard { value: root.today ? String(root.today.streak) : "—"; label: "Streak" }
      }

      Text {
        textFormat: Text.PlainText
        text: "THIS WEEK"
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
        Layout.fillWidth: true
        Layout.topMargin: Style.space(3)
      }

      ColumnLayout {
        spacing: Style.space(3)
        Layout.fillWidth: true

        Repeater {
          model: root.week
          delegate: RowLayout {
            required property var modelData
            spacing: Style.space(8)
            Layout.fillWidth: true

            Text {
              textFormat: Text.PlainText
              text: modelData.dayLabel
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              Layout.preferredWidth: Style.space(30)
            }

            Rectangle {
              height: Style.space(10)
              radius: height / 2
              color: Util.alpha(Color.accent, 0.10)
              Layout.fillWidth: true

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: modelData.focusSec > 0
                  ? parent.width * Math.max(0.035, Math.min(1, modelData.focusSec / root.weekMax)) : 0
                radius: parent.radius
                color: Color.accent
                opacity: 0.85
              }
            }

            Text {
              textFormat: Text.PlainText
              text: root.formatDuration(modelData.focusSec)
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              Layout.preferredWidth: Style.space(54)
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }

      Text {
        textFormat: Text.PlainText
        text: "FOCUS HEATMAP"
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
        Layout.fillWidth: true
        Layout.topMargin: Style.space(3)
      }

      ColumnLayout {
        spacing: Style.space(2)
        Layout.fillWidth: true

        Repeater {
          model: 7
          delegate: RowLayout {
            required property int index
            spacing: Style.space(2)
            Layout.fillWidth: true

            Text {
              textFormat: Text.PlainText
              text: ["S", "M", "T", "W", "T", "F", "S"][index]
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              Layout.preferredWidth: Style.space(10)
              horizontalAlignment: Text.AlignHCenter
            }

            Repeater {
              model: root.heatmap[index] || []
              delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Style.space(12)
                radius: Style.space(2)
                color: {
                  var level = Number(modelData.level) || 0;
                  if (level === 0) return Util.alpha(Color.muted, 0.10);
                  if (level === 1) return Util.alpha(Color.accent, 0.30);
                  if (level === 2) return Util.alpha(Color.accent, 0.55);
                  if (level === 3) return Util.alpha(Color.accent, 0.80);
                  return Color.accent;
                }
              }
            }
          }
        }
      }

      Text {
        textFormat: Text.PlainText
        text: "HISTORY"
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
        Layout.fillWidth: true
        Layout.topMargin: Style.space(3)
      }

      ColumnLayout {
        spacing: Style.space(5)
        Layout.fillWidth: true

        RowLayout {
          spacing: Style.space(4)
          Layout.alignment: Qt.AlignHCenter
          Repeater {
            model: [
              { id: "today", label: "Today" },
              { id: "yesterday", label: "Yesterday" },
              { id: "all", label: "All" }
            ]
            delegate: Chip {
              required property var modelData
              label: modelData.label
              active: root.range === modelData.id
              onClicked: root.range = modelData.id
            }
          }
        }

        RowLayout {
          spacing: Style.space(4)
          Layout.alignment: Qt.AlignHCenter
          Repeater {
            model: [
              { id: "both", label: "Both" },
              { id: "pomo", label: "Pomo" },
              { id: "flow", label: "Flow" }
            ]
            delegate: Chip {
              required property var modelData
              label: modelData.label
              active: root.kind === modelData.id
              onClicked: root.kind = modelData.id
            }
          }
        }
      }

      ColumnLayout {
        spacing: Style.space(4)
        Layout.fillWidth: true

        Repeater {
          model: root.hist.slice(0, 30)
          delegate: RowLayout {
            required property var modelData
            spacing: Style.space(8)
            Layout.fillWidth: true

            Rectangle {
              width: Style.space(8)
              height: width
              radius: width / 2
              color: modelData.kind === "pomo" ? Color.accent : Color.muted
              Layout.alignment: Qt.AlignVCenter
            }
            Text {
              textFormat: Text.PlainText
              text: (modelData.kind === "pomo" ? "Pomodoro" : "Flowtime")
                + " · " + root.formatDuration(modelData.durationSec)
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
            Text {
              textFormat: Text.PlainText
              text: Qt.formatDateTime(new Date(modelData.startedAt), "HH:mm")
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }

        Text {
          visible: root.hist.length === 0
          textFormat: Text.PlainText
          text: "No sessions yet — start a Pomodoro or Flowtime."
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          Layout.alignment: Qt.AlignHCenter
          Layout.topMargin: Style.space(4)
        }
      }
      Item { Layout.preferredHeight: Style.space(8) }
    }
  }

  component StatCard: Rectangle {
    id: card
    property string value: ""
    property string label: ""

    Layout.fillWidth: true
    implicitHeight: Style.space(64)
    radius: Style.cornerRadius
    color: "transparent"
    border.color: Color.popups.border
    border.width: Math.max(1, Style.space(1))

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.space(6)
      spacing: 0
      Text {
        textFormat: Text.PlainText
        text: card.value
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        Layout.alignment: Qt.AlignHCenter
        elide: Text.ElideRight
      }
      Text {
        textFormat: Text.PlainText
        text: card.label
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}
