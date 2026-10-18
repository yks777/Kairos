import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import qs.Commons
import "../components"

Item {
  id: root
  property var service: null
  signal back()
  property bool confirmingReset: false
  property string selectedCategory: "focus"

  Layout.fillWidth: true
  Layout.fillHeight: true
  implicitHeight: Style.space(560)

   readonly property var categories: [
     { id: "focus", label: "Focus", subtitle: "Timers, breaks and streak." },
     { id: "calendar", label: "Calendar", subtitle: "Events, sync and maps." },
     { id: "obsidian", label: "Obsidian", subtitle: "Daily-notes vault integration." },
     { id: "markets", label: "Markets", subtitle: "Quotes and display currency." },
     { id: "system", label: "System", subtitle: "Panel, shortcuts and data file." }
   ]

  function update(section, patch) {
    if (root.service && typeof root.service.updateSettings === "function")
      root.service.updateSettings(section, patch);
  }

  function value(section, key, fallback) {
    if (!root.service || !root.service.settings || !root.service.settings[section]) return fallback;
    var value = root.service.settings[section][key];
    return value === undefined || value === null ? fallback : value;
  }

  function categorySubtitle(id) {
    for (var i = 0; i < root.categories.length; i++)
      if (root.categories[i].id === id) return root.categories[i].subtitle;
    return "";
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(8)

    RowLayout {
      spacing: Style.space(8)
      Layout.fillWidth: true
      FlowIconButton {
        glyph: "\uf053"
        tip: "Back"
        onClicked: root.back()
      }
      Text {
        textFormat: Text.PlainText
        text: "SETTINGS"
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 2
        Layout.fillWidth: true
      }
    }

    RowLayout {
      spacing: Style.space(10)
      Layout.fillWidth: true
      Layout.fillHeight: true

      ColumnLayout {
        id: nav
        spacing: Style.space(2)
        Layout.preferredWidth: Style.space(148)
        Layout.maximumWidth: Style.space(148)
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop

        Repeater {
          model: root.categories
          delegate: Item {
            id: navItem
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: Style.space(36)

            Rectangle {
              anchors.fill: parent
              radius: Style.cornerRadius
              color: Color.accent
              opacity: root.selectedCategory === navItem.modelData.id ? 0.20 : (hitArea.containsMouse ? 0.10 : 0.0)
            }
            Rectangle {
              width: Math.max(2, Style.space(3))
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              anchors.left: parent.left
              anchors.topMargin: Style.space(6)
              anchors.bottomMargin: Style.space(6)
              anchors.leftMargin: Style.space(4)
              radius: width / 2
              color: Color.accent
              visible: root.selectedCategory === navItem.modelData.id
            }
            Text {
              anchors.fill: parent
              anchors.leftMargin: Style.space(16)
              anchors.rightMargin: Style.space(8)
              verticalAlignment: Text.AlignVCenter
              textFormat: Text.PlainText
              text: navItem.modelData.label
              color: root.selectedCategory === navItem.modelData.id ? Color.accent : Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.weight: root.selectedCategory === navItem.modelData.id ? Font.DemiBold : Font.Normal
              elide: Text.ElideRight
            }
            MouseArea {
              id: hitArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedCategory = navItem.modelData.id
            }
          }
        }

        Item { Layout.fillHeight: true }
      }

      Rectangle {
        width: 1
        Layout.fillHeight: true
        color: Color.popups.border
        opacity: 0.5
      }

      Flickable {
        id: scroll
        clip: true
        contentWidth: width
        contentHeight: settingsColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
          id: settingsColumn
          width: scroll.width
          spacing: Style.space(12)

          // ---- Focus ----
          ColumnLayout {
            spacing: Style.space(12)
            Layout.fillWidth: true
            visible: root.selectedCategory === "focus"
            CategoryHeader { heading: "Focus"; subtitle: root.categorySubtitle("focus") }
            Section {
              title: "Focus"
              RowLayout {
                SettingLabel { text: "Technique" }
                Chip { label: "Pomodoro"; active: root.value("focus", "focusAction", "pomodoro") === "pomodoro"; onClicked: root.update("focus", { focusAction: "pomodoro" }) }
                Chip { label: "Flowtime"; active: root.value("focus", "focusAction", "pomodoro") === "flowtime"; onClicked: root.update("focus", { focusAction: "flowtime" }) }
              }
              NumberRow { label: "Focus duration"; unit: "min"; value: Number(root.value("focus", "focusSec", 1500)) / 60; minimum: 1; maximum: 480; onCommit: function(v) { root.update("focus", { focusSec: v * 60 }); } }
              NumberRow { label: "Short break"; unit: "min"; value: Number(root.value("focus", "shortBreakSec", 300)) / 60; minimum: 0; maximum: 120; onCommit: function(v) { root.update("focus", { shortBreakSec: v * 60 }); } }
              NumberRow { label: "Long break"; unit: "min"; value: Number(root.value("focus", "longBreakSec", 900)) / 60; minimum: 0; maximum: 240; onCommit: function(v) { root.update("focus", { longBreakSec: v * 60 }); } }
              NumberRow { label: "Sessions per long break"; unit: "sessions"; value: root.value("focus", "longBreakInterval", 4); minimum: 1; maximum: 24; onCommit: function(v) { root.update("focus", { longBreakInterval: v }); } }
            }
            Section {
              title: "Flowtime"
              RowLayout {
                SettingLabel { text: "Break mode" }
                Chip { label: "Traditional"; active: root.value("flowtime", "breakMode", "traditional") === "traditional"; onClicked: root.update("flowtime", { breakMode: "traditional" }) }
                Chip { label: "Proportional"; active: root.value("flowtime", "breakMode", "traditional") === "proportional"; onClicked: root.update("flowtime", { breakMode: "proportional" }) }
              }
              NumberRow { label: "Break ratio"; unit: "%"; value: Number(root.value("flowtime", "breakRatio", 0.2)) * 100; minimum: 0; maximum: 100; onCommit: function(v) { root.update("flowtime", { breakRatio: v / 100 }); } }
              NumberRow { label: "Minimum break"; unit: "min"; value: Number(root.value("flowtime", "minBreakSec", 300)) / 60; minimum: 0; maximum: 120; onCommit: function(v) { root.update("flowtime", { minBreakSec: v * 60 }); } }
              NumberRow { label: "Maximum break"; unit: "min"; value: Number(root.value("flowtime", "maxBreakSec", 900)) / 60; minimum: 1; maximum: 240; onCommit: function(v) { root.update("flowtime", { maxBreakSec: v * 60 }); } }
            }
            Section {
              title: "Stats"
              NumberRow { label: "Daily streak minimum"; unit: "min"; value: Number(root.value("stats", "streakMinSec", 900)) / 60; minimum: 1; maximum: 1440; onCommit: function(v) { root.update("stats", { streakMinSec: v * 60 }); } }
            }
          }

          // ---- Calendar ----
          ColumnLayout {
            spacing: Style.space(12)
            Layout.fillWidth: true
            visible: root.selectedCategory === "calendar"
            CategoryHeader { heading: "Calendar"; subtitle: root.categorySubtitle("calendar") }
            Section {
              title: "Calendar"
              ToggleRow { label: "Event notifications"; checked: root.value("calendar", "notifications", true); onToggled: function(v) { root.update("calendar", { notifications: v }); } }
              NumberRow { label: "Notification lead"; unit: "min"; value: root.value("calendar", "leadMinutes", 10); minimum: 0; maximum: 120; onCommit: function(v) { root.update("calendar", { leadMinutes: v }); } }
              NumberRow { label: "Agenda days"; unit: "days"; value: root.value("calendar", "agendaDays", 7); minimum: 1; maximum: 60; onCommit: function(v) { root.update("calendar", { agendaDays: v }); } }
              RowLayout {
                SettingLabel { text: "Time format" }
                Chip { label: "Match khal"; active: root.value("calendar", "timeFormat", "Match khal") === "Match khal"; onClicked: root.update("calendar", { timeFormat: "Match khal" }) }
                Chip { label: "12-hour"; active: root.value("calendar", "timeFormat", "Match khal") === "12-hour"; onClicked: root.update("calendar", { timeFormat: "12-hour" }) }
                Chip { label: "24-hour"; active: root.value("calendar", "timeFormat", "Match khal") === "24-hour"; onClicked: root.update("calendar", { timeFormat: "24-hour" }) }
              }
              NumberRow { label: "Sync interval"; unit: "min · 0 disables"; value: root.value("calendar", "syncIntervalMinutes", 15); minimum: 0; maximum: 1440; onCommit: function(v) { root.update("calendar", { syncIntervalMinutes: v }); } }
              TextRow { label: "Sync command"; value: root.value("calendar", "syncCommand", "vdirsyncer sync"); onCommit: function(v) { root.update("calendar", { syncCommand: v }); } }
              RowLayout {
                SettingLabel { text: "Maps" }
                Chip { label: "Google"; active: root.value("calendar", "mapsProvider", "Google Maps") === "Google Maps"; onClicked: root.update("calendar", { mapsProvider: "Google Maps" }) }
                Chip { label: "OpenStreetMap"; active: root.value("calendar", "mapsProvider", "Google Maps") === "OpenStreetMap"; onClicked: root.update("calendar", { mapsProvider: "OpenStreetMap" }) }
                Chip { label: "Apple"; active: root.value("calendar", "mapsProvider", "Google Maps") === "Apple Maps"; onClicked: root.update("calendar", { mapsProvider: "Apple Maps" }) }
              }
            }
          }

          // ---- Obsidian ----
          ColumnLayout {
            spacing: Style.space(12)
            Layout.fillWidth: true
            visible: root.selectedCategory === "obsidian"
            CategoryHeader { heading: "Obsidian"; subtitle: "Vault auto-detected via the .obsidian folder above your diary." }
            Section {
              title: "Obsidian"
              ToggleRow { label: "Enabled"; checked: root.value("obsidian", "enabled", false); onToggled: function(v) { root.update("obsidian", { enabled: v }); } }
              PathRow { label: "Diary folder"; value: root.value("obsidian", "diaryPath", ""); onCommit: function(v) { root.update("obsidian", { diaryPath: v }); } }
              TextRow { label: "Vault name (optional)"; value: root.value("obsidian", "vaultName", ""); onCommit: function(v) { root.update("obsidian", { vaultName: v }); } }
              Text { textFormat: Text.PlainText; text: "Daily notes live directly in this folder as YYYY-MM-DD.md. A missing day is created as an empty note and opened in Obsidian."; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
              FlowButton { text: "Test connection"; onClicked: if (root.service) root.service.obsidianTestConnection() }
              Text { textFormat: Text.PlainText; text: root.service ? root.service.obsidianTestStatus : ""; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
          }

          // ---- Markets ----
          ColumnLayout {
            spacing: Style.space(12)
            Layout.fillWidth: true
            visible: root.selectedCategory === "markets"
            CategoryHeader { heading: "Markets"; subtitle: root.categorySubtitle("markets") }
            Section {
              title: "Markets"
              NumberRow { label: "Quote refresh"; unit: "min"; value: root.value("markets", "refreshMinutes", 5); minimum: 1; maximum: 60; onCommit: function(v) { root.update("markets", { refreshMinutes: v }); } }
              RowLayout {
                SettingLabel { text: "Display currency" }
                Repeater {
                  model: ["USD", "EUR", "BRL"]
                  delegate: Chip {
                    required property string modelData
                    label: modelData
                    active: root.value("markets", "currency", "USD") === modelData
                    onClicked: root.update("markets", { currency: modelData })
                  }
                }
              }
              Text { textFormat: Text.PlainText; text: "The market watchlist is managed from Markets → Watchlist."; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
          }

          // ---- System ----
          ColumnLayout {
            spacing: Style.space(12)
            Layout.fillWidth: true
            visible: root.selectedCategory === "system"
            CategoryHeader { heading: "System"; subtitle: root.categorySubtitle("system") }
            Section {
              title: "Bar"
              ToggleRow { label: "Show focus timer"; checked: root.value("bar", "showFocusTimer", true); onToggled: function(v) { root.update("bar", { showFocusTimer: v }); } }
            }
            Section {
              title: "Shortcuts"
              TextRow { label: "Toggle panel"; value: root.value("shortcuts", "toggleShortcut", "Super+H"); onCommit: function(v) { root.update("shortcuts", { toggleShortcut: v }); } }
              TextRow { label: "Pomodoro"; value: root.value("shortcuts", "focusShortcut", "Super+Shift+H"); onCommit: function(v) { root.update("shortcuts", { focusShortcut: v }); } }
              TextRow { label: "Flowtime"; value: root.value("shortcuts", "flowtimeShortcut", "Super+Alt+H"); onCommit: function(v) { root.update("shortcuts", { flowtimeShortcut: v }); } }
            }
            Section {
              title: "Notifications"
              ToggleRow { label: "Enabled"; checked: root.value("notifications", "enabled", true); onToggled: function(v) { root.update("notifications", { enabled: v }); } }
              ToggleRow { label: "Sound"; checked: root.value("notifications", "sound", true); onToggled: function(v) { root.update("notifications", { sound: v }); } }
            }
            Section {
              title: "Data"
              Text { textFormat: Text.PlainText; text: root.service ? ("State file: " + root.service.stateFilePath) : ""; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
              RowLayout {
                FlowButton {
                  text: root.confirmingReset ? "Confirm reset" : "Reset data"
                  primary: root.confirmingReset
                  onClicked: {
                    if (root.confirmingReset) {
                      if (root.service) root.service.resetAll();
                      root.confirmingReset = false;
                    } else root.confirmingReset = true;
                  }
                }
              }
              Text { textFormat: Text.PlainText; text: root.service ? root.service.dataStatus : ""; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
          }

          Item { Layout.preferredHeight: Style.space(8) }
        }
      }
    }
  }

  component CategoryHeader: ColumnLayout {
    id: header
    property string heading: ""
    property string subtitle: ""
    spacing: Style.space(2)
    Layout.fillWidth: true
    Text {
      textFormat: Text.PlainText
      text: header.heading.toUpperCase()
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.weight: Font.DemiBold
      font.letterSpacing: 1
      Layout.fillWidth: true
    }
    Text {
      textFormat: Text.PlainText
      text: header.subtitle
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
      visible: header.subtitle !== ""
    }
    Rectangle {
      height: Math.max(1, Style.space(1))
      color: Color.popups.border
      opacity: 0.5
      Layout.fillWidth: true
      Layout.topMargin: Style.space(4)
    }
  }

  component Section: ColumnLayout {
    id: section
    property string title: ""
    spacing: Style.space(7)
    Layout.fillWidth: true
    Layout.leftMargin: Style.space(4)
    Layout.rightMargin: Style.space(4)
    Text {
      textFormat: Text.PlainText
      text: section.title.toUpperCase()
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
      Layout.fillWidth: true
    }
    Rectangle {
      height: Math.max(1, Style.space(1))
      color: Color.popups.border
      opacity: 0.5
      Layout.fillWidth: true
    }
  }

  component SettingLabel: Text {
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    Layout.fillWidth: true
  }

  component NumberRow: RowLayout {
    id: num
    property string label: ""
    property string unit: ""
    property real value: 0
    property int minimum: 0
    property int maximum: 1000000
    signal commit(real value)
    spacing: Style.space(6)
    Layout.fillWidth: true
    SettingLabel { text: num.label }
    Text {
      textFormat: Text.PlainText
      text: num.unit
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
    FlowInput {
      id: input
      numbersOnly: true
      text: String(Math.round(num.value))
      implicitWidth: Style.space(72)
      Layout.preferredWidth: Style.space(72)
      onAccepted: {
        var parsed = parseInt(input.text, 10);
        if (!isNaN(parsed)) {
          var bounded = Math.max(num.minimum, Math.min(num.maximum, parsed));
          input.text = String(bounded);
          num.commit(bounded);
        } else input.text = String(Math.round(num.value));
      }
      onCancelled: input.text = String(Math.round(num.value))
    }
  }

  component ToggleRow: RowLayout {
    id: toggle
    property string label: ""
    property bool checked: false
    signal toggled(bool value)
    spacing: Style.space(10)
    Layout.fillWidth: true
    SettingLabel { text: toggle.label }
    Rectangle {
      width: Style.space(42)
      height: Style.space(23)
      radius: height / 2
      color: "transparent"
      border.color: toggle.checked ? Color.accent : Color.popups.border
      border.width: Math.max(1, Style.space(1))
      Rectangle {
        width: Style.space(15)
        height: width
        radius: width / 2
        color: toggle.checked ? Color.accent : Color.muted
        anchors.verticalCenter: parent.verticalCenter
        x: toggle.checked ? parent.width - width - Style.space(4) : Style.space(4)
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled(!toggle.checked)
      }
    }
  }

  component TextRow: RowLayout {
    id: row
    property string label: ""
    property string value: ""
    signal commit(string value)
    spacing: Style.space(8)
    Layout.fillWidth: true
    SettingLabel { text: row.label }
    FlowInput {
      id: input
      text: row.value
      Layout.fillWidth: true
      onAccepted: row.commit(input.text.trim())
    }
  }

  component PathRow: ColumnLayout {
    id: pathRow
    property string label: ""
    property string value: ""
    signal commit(string value)
    spacing: Style.space(4)
    Layout.fillWidth: true

    SettingLabel { text: pathRow.label }

    RowLayout {
      spacing: Style.space(6)
      Layout.fillWidth: true
      FlowInput {
        id: pathInput
        text: pathRow.value
        Layout.fillWidth: true
        onAccepted: pathRow.commit(pathInput.text.trim())
      }
      FlowButton {
        text: "Browse…"
        onClicked: pathRow.openPicker()
      }
    }

    Text {
      textFormat: Text.PlainText
      text: "Pick the folder that holds your daily notes, or paste an absolute path."
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    FolderDialog {
      id: diaryPicker
      title: "Choose Obsidian diary folder"
      onAccepted: {
        var picked = pathRow.urlToPath(diaryPicker.selectedFolder);
        if (picked !== "") pathRow.commit(picked);
      }
    }

    function openPicker() {
      var folderUrl = pathRow.pathToFolderUrl((pathInput.text || pathRow.value || "").trim());
      if (folderUrl !== "") diaryPicker.currentFolder = folderUrl;
      diaryPicker.open();
    }

    function urlToPath(url) {
      var s = String(url || "");
      if (s.indexOf("file://") === 0) s = s.substring(7);
      try { return decodeURIComponent(s); } catch (error) { return s; }
    }

    function pathToFolderUrl(path) {
      var p = String(path || "").trim();
      if (p === "" || p.charAt(0) !== "/") return "";
      try { return "file://" + encodeURI(p); } catch (error) { return "file://" + p; }
    }
  }
}
