import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components"
import "../components/social"

Item {
  id: root
  property var service: null
  property string activeAccount: "all"
  property var openThread: null
  Layout.fillWidth: true
  Layout.fillHeight: true
  implicitHeight: Style.space(620)
  readonly property var accounts: { if (!root.service) return []; void root.service.revision; return root.service.socialAccounts(); }
  readonly property var emailAccounts: {
    var rows = [];
    for (var i = 0; i < root.accounts.length; i++)
      if (root.accounts[i].platform === "email") rows.push(root.accounts[i]);
    return rows;
  }
  readonly property var unreadItems: { if (!root.service) return []; void root.service.revision; return root.service.socialUnread(root.activeAccount); }
  readonly property var recentCalls: { if (!root.service) return []; void root.service.revision; return root.service.socialRecentCalls(root.activeAccount); }
  readonly property var ringing: { if (!root.service) return null; void root.service.tickVersion; void root.service.revision; return root.service.socialRinging(); }

  function composeEmail() {
    if (root.emailAccounts.length === 0) return;
    var account = root.emailAccounts[0];
    for (var i = 0; i < root.emailAccounts.length; i++)
      if (root.emailAccounts[i].id === root.activeAccount) account = root.emailAccounts[i];
    root.openThread = {
      platform: "email",
      accountId: account.id,
      chatId: "",
      name: "New email",
      accountName: account.name,
      compose: true
    };
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(8)
    Conversation { visible: root.openThread !== null; thread: root.openThread; service: root.service; onClose: root.openThread = null; Layout.fillWidth: true; Layout.fillHeight: true }
    ColumnLayout {
      visible: root.openThread === null
      spacing: Style.space(8)
      Layout.fillWidth: true
      Layout.fillHeight: true
      AccountTabs { accounts: root.accounts; activeId: root.activeAccount; onAccountSelected: function(id) { root.activeAccount = id; }; Layout.fillWidth: true }
      FlowButton { visible: root.emailAccounts.length > 0; text: "Compose email"; primary: true; onClicked: root.composeEmail() }
      Text { visible: root.service && root.service.socialStatus !== ""; textFormat: Text.PlainText; text: root.service ? root.service.socialStatus : ""; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
      Text { visible: root.service && root.emailAccounts.length > 0; textFormat: Text.PlainText; text: root.service ? root.service.emailStatusText : ""; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
      Text { textFormat: Text.PlainText; text: "UNREAD (" + root.unreadItems.length + ")"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.letterSpacing: 1; Layout.fillWidth: true }
      UnreadList { items: root.unreadItems; service: root.service; emptyText: root.service ? root.service.socialEmptyMessage : "No unread messages."; onItemSelected: function(item) { root.openThread = item; }; Layout.fillWidth: true; Layout.preferredHeight: Math.max(Style.space(76), parent.height * 0.45) }
      Text { visible: root.recentCalls.length > 0; textFormat: Text.PlainText; text: "RECENT CALLS"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.letterSpacing: 1; Layout.fillWidth: true }
      CallList { visible: root.recentCalls.length > 0; calls: root.recentCalls; Layout.fillWidth: true }
      RingingBanner { visible: root.ringing !== null; call: root.ringing; service: root.service; Layout.fillWidth: true }
    }
  }
}