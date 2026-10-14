import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components"

Item {
  id: root
  property var service: null
  signal back()
  property bool confirmingReset: false

  Layout.fillWidth: true
  Layout.fillHeight: true
  implicitHeight: Style.space(560)

  function update(section, patch) {
    if (root.service && typeof root.service.updateSettings === "function")
      root.service.updateSettings(section, patch);
  }

  function value(section, key, fallback) {
    if (!root.service || !root.service.settings || !root.service.settings[section]) return fallback;
    var value = root.service.settings[section][key];
    return value === undefined || value === null ? fallback : value;
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

        Section {
          title: "Obsidian"
          ToggleRow { label: "Enabled"; checked: root.value("obsidian", "enabled", false); onToggled: function(v) { root.update("obsidian", { enabled: v }); } }
          PathRow { label: "Diary folder"; mode: "directory"; value: root.value("obsidian", "diaryPath", ""); onCommit: function(v) { root.update("obsidian", { diaryPath: v }); } }
          TextRow { label: "Vault name (optional)"; value: root.value("obsidian", "vaultName", ""); onCommit: function(v) { root.update("obsidian", { vaultName: v }); } }
          PathRow { label: "Static template"; mode: "file"; value: root.value("obsidian", "templatePath", ""); onCommit: function(v) { root.update("obsidian", { templatePath: v }); } }
          FlowButton { text: "Test connection"; onClicked: if (root.service) root.service.obsidianTestConnection() }
          Text { textFormat: Text.PlainText; text: root.service ? root.service.obsidianTestStatus : ""; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }

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

        Section {
          title: "Social"
          ToggleRow { label: "Telegram"; checked: root.value("social", "telegram", false); onToggled: function(v) { root.update("social", { telegram: v }); } }
          ToggleRow { label: "WhatsApp"; checked: root.value("social", "whatsapp", false); onToggled: function(v) { root.update("social", { whatsapp: v }); } }
          ToggleRow { label: "Signal"; checked: root.value("social", "signal", false); onToggled: function(v) { root.update("social", { signal: v }); } }
          ToggleRow { label: "Discord"; checked: root.value("social", "discord", false); onToggled: function(v) { root.update("social", { discord: v }); } }
          ToggleRow { label: "Matrix"; checked: root.value("social", "matrix", false); onToggled: function(v) { root.update("social", { matrix: v }); } }
          ToggleRow { label: "Message notifications"; checked: root.value("social", "notifyMessages", true); onToggled: function(v) { root.update("social", { notifyMessages: v }); } }
          ToggleRow { label: "Call notifications"; checked: root.value("social", "notifyCalls", true); onToggled: function(v) { root.update("social", { notifyCalls: v }); } }
          ToggleRow { label: "Show previews"; checked: root.value("social", "showPreview", false); onToggled: function(v) { root.update("social", { showPreview: v }); } }
          Text { textFormat: Text.PlainText; text: "Connectors require an optional local kairos-social-bridge adapter."; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
          Text {
            textFormat: Text.PlainText
            text: root.service ? [
              "Telegram · " + root.service.socialPlatformStatus("telegram"),
              "WhatsApp · " + root.service.socialPlatformStatus("whatsapp"),
              "Signal · " + root.service.socialPlatformStatus("signal"),
              "Discord · " + root.service.socialPlatformStatus("discord"),
              "Matrix · " + root.service.socialPlatformStatus("matrix")
            ].join("\n") : ""
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
        }

        Section {
          title: "Email"
          ToggleRow { label: "New-message notifications"; checked: root.value("email", "notifyNew", true); onToggled: function(v) { root.update("email", { notifyNew: v }); } }
          ToggleRow { label: "Show subject previews"; checked: root.value("email", "showPreview", false); onToggled: function(v) { root.update("email", { showPreview: v }); } }
          Repeater {
            model: root.service ? root.service.settings.email.accounts : []
            delegate: AccountEditor {
              required property var modelData
              account: modelData
              service: root.service
            }
          }
          FlowButton { text: "Add email account"; onClicked: if (root.service) root.service.emailAddAccount() }
          Text { textFormat: Text.PlainText; text: root.service ? root.service.emailStatusText : "Email uses the system keyring for passwords."; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }

        Section {
          title: "Bar"
          ToggleRow { label: "Show focus timer"; checked: root.value("bar", "showFocusTimer", true); onToggled: function(v) { root.update("bar", { showFocusTimer: v }); } }
        }

        Section {
          title: "Stats"
          NumberRow { label: "Daily streak minimum"; unit: "min"; value: Number(root.value("stats", "streakMinSec", 900)) / 60; minimum: 1; maximum: 1440; onCommit: function(v) { root.update("stats", { streakMinSec: v * 60 }); } }
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
          Text { textFormat: Text.PlainText; text: "Email passwords are held by the system Secret Service and are not written to this file."; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
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

        Item { Layout.preferredHeight: Style.space(8) }
      }
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

  component PathRow: RowLayout {
    id: pathRow
    property string label: ""
    property string value: ""
    property string mode: "file"
    signal commit(string value)
    spacing: Style.space(8)
    Layout.fillWidth: true
    SettingLabel { text: pathRow.label }
    FlowInput {
      id: pathInput
      text: pathRow.value
      Layout.fillWidth: true
      onAccepted: pathRow.commit(pathInput.text.trim())
    }
    Text {
      textFormat: Text.PlainText
      text: pathRow.mode === "directory" ? "Use absolute path" : "Use absolute file path"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  component AccountEditor: ColumnLayout {
    id: editor
    property var account: null
    property var service: null
    spacing: Style.space(5)
    Layout.fillWidth: true

    Text { textFormat: Text.PlainText; text: editor.account ? editor.account.name : "Email account"; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall; font.weight: Font.DemiBold; Layout.fillWidth: true }
    TextRow { label: "Account name"; value: editor.account ? editor.account.name : ""; onCommit: function(v) { editor.patch({ name: v }); } }
    TextRow { label: "Email address"; value: editor.account ? editor.account.email : ""; onCommit: function(v) { editor.patch({ email: v }); } }
    TextRow { label: "IMAP host"; value: editor.account ? editor.account.imapHost : ""; onCommit: function(v) { editor.patch({ imapHost: v }); } }
    NumberRow { label: "IMAP port"; unit: "TLS"; value: editor.account ? editor.account.imapPort : 993; minimum: 1; maximum: 65535; onCommit: function(v) { editor.patch({ imapPort: v }); } }
    TextRow { label: "SMTP host"; value: editor.account ? editor.account.smtpHost : ""; onCommit: function(v) { editor.patch({ smtpHost: v }); } }
    NumberRow { label: "SMTP port"; unit: "TLS"; value: editor.account ? editor.account.smtpPort : 587; minimum: 1; maximum: 65535; onCommit: function(v) { editor.patch({ smtpPort: v }); } }
    TextRow { label: "Username"; value: editor.account ? editor.account.username : ""; onCommit: function(v) { editor.patch({ username: v }); } }
    SecretRow { account: editor.account; service: editor.service }
    RowLayout {
      FlowButton { text: "Remove account"; onClicked: if (editor.service && editor.account) editor.service.emailRemoveAccount(editor.account.id) }
    }

    function patch(values) {
      if (editor.service && editor.account) editor.service.emailUpdateAccount(editor.account.id, values);
    }
  }

  component SecretRow: ColumnLayout {
    id: secretRow
    property var account: null
    property var service: null
    spacing: Style.space(4)
    Layout.fillWidth: true
    Text { textFormat: Text.PlainText; text: "App password (stored only in the system keyring)"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; Layout.fillWidth: true }
    RowLayout {
      Rectangle {
        implicitHeight: Style.space(32)
        radius: Style.cornerRadius
        color: "transparent"
        border.color: Color.popups.border
        border.width: Math.max(1, Style.space(1))
        Layout.fillWidth: true
        TextInput {
          id: secretInput
          anchors.fill: parent
          anchors.leftMargin: Style.space(8)
          anchors.rightMargin: Style.space(8)
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          color: Color.popups.text
          selectionColor: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          maximumLength: 4096
        }
      }
      FlowButton {
        text: "Save password"
        enabledButton: !!(secretRow.account && secretRow.service)
        onClicked: {
          if (secretRow.service && secretRow.account) {
            secretRow.service.emailStoreCredential(secretRow.account.id, secretInput.text);
            secretInput.text = "";
          }
        }
      }
      FlowButton {
        text: "Remove password"
        enabledButton: !!(secretRow.account && secretRow.service)
        onClicked: if (secretRow.service && secretRow.account) secretRow.service.emailClearCredential(secretRow.account.id)
      }
    }
    Text {
      textFormat: Text.PlainText
      text: secretRow.service && secretRow.account ? secretRow.service.emailAccountStatus(secretRow.account.id) : ""
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }
}
