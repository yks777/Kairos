import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."
import "../../logic/EmailModel.js" as EmailModel

ColumnLayout {
  id: root
  property var thread: null
  property var service: null
  property string messageText: ""
  property string emailComposerMode: ""
  property var emailDraft: ({})
  signal close()
  spacing: Style.space(8)
  Layout.fillWidth: true
  Layout.fillHeight: true
  readonly property bool isEmail: !!(root.thread && root.thread.platform === "email")
  readonly property var messages: { if (!root.service || !root.thread) return []; void root.service.revision; return root.service.socialThread(root.thread.accountId, root.thread.chatId); }
  function beginEmail(mode) { if (!root.isEmail || !root.service || root.messages.length === 0) return; var last = root.messages[root.messages.length - 1]; root.emailDraft = EmailModel.replyDraft(last, root.service.emailAccountById(root.thread.accountId), mode); root.emailComposerMode = mode; }
  RowLayout { spacing: Style.space(8); Layout.fillWidth: true; Text { textFormat: Text.PlainText; text: root.thread ? String(root.thread.platform || "").toUpperCase() + " · " + String(root.thread.name || "") : "Conversation"; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.letterSpacing: 1; Layout.fillWidth: true; elide: Text.ElideRight } FlowIconButton { glyph: "\uf00d"; tip: "Close conversation"; onClicked: root.close() } }
  Rectangle { height: Math.max(1, Style.space(1)); color: Color.popups.border; opacity: 0.5; Layout.fillWidth: true }
  RowLayout { visible: root.isEmail && root.emailComposerMode === "" && !(root.thread && root.thread.compose); spacing: Style.space(4); Layout.fillWidth: true; FlowButton { text: "Reply"; onClicked: root.beginEmail("reply") } FlowButton { text: "Reply all"; onClicked: root.beginEmail("replyAll") } FlowButton { text: "Forward"; onClicked: root.beginEmail("forward") } }
  ListView { id: messageList; visible: !(root.thread && root.thread.compose); model: root.messages; spacing: Style.space(8); clip: true; boundsBehavior: Flickable.StopAtBounds; Layout.fillWidth: true; Layout.fillHeight: true; delegate: ColumnLayout { required property var modelData; spacing: Style.space(3); Layout.fillWidth: true; Text { textFormat: Text.PlainText; text: (modelData.subject ? modelData.subject + " · " : "") + (modelData.sender || modelData.senderName || "Unknown sender"); color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; Layout.fillWidth: true; elide: Text.ElideRight } Text { textFormat: Text.PlainText; text: modelData.body || ""; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall; wrapMode: Text.Wrap; Layout.fillWidth: true } Text { visible: modelData.hasAttachments === true; textFormat: Text.PlainText; text: "Attachment metadata available; files are not downloaded by Kairos."; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap; Layout.fillWidth: true } Text { textFormat: Text.PlainText; text: modelData.timeLabel || ""; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption } } }
  Text { visible: root.messages.length === 0 && !root.isEmail; textFormat: Text.PlainText; text: "No message history was returned by the local bridge."; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; Layout.fillWidth: true }
  Text { visible: root.messages.length === 0 && root.thread && root.thread.compose === true; textFormat: Text.PlainText; text: "Compose a message from this account."; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; Layout.fillWidth: true }
  EmailComposer { visible: root.isEmail && root.emailComposerMode !== ""; service: root.service; account: root.service && root.thread ? root.service.emailAccountById(root.thread.accountId) : null; mode: root.emailComposerMode; draft: root.emailDraft; Layout.fillWidth: true; onClose: root.emailComposerMode = "" }
  RowLayout { visible: !root.isEmail; spacing: Style.space(6); Layout.fillWidth: true; FlowInput { id: composer; text: root.messageText; placeholder: "Type a message…"; Layout.fillWidth: true; onTextChanged: root.messageText = text; onAccepted: root.sendMessage() } FlowButton { text: "Send"; primary: true; onClicked: root.sendMessage() } }
  function sendMessage() { if (!root.service || !root.thread || !composer.text.trim()) return; var sent = root.service.socialSend(root.thread.platform, root.thread.accountId, root.thread.chatId, composer.text); if (sent) { composer.text = ""; root.messageText = ""; } }
  onThreadChanged: {
    root.emailComposerMode = "";
    root.emailDraft = ({});
    root.messageText = "";
    if (root.thread && root.thread.platform === "email" && root.thread.compose === true) {
      root.emailDraft = { to: "", subject: "", body: "", originalId: "", references: "" };
      root.emailComposerMode = "new";
    } else if (root.thread && root.service) {
      root.service.socialMarkRead(root.thread.accountId, root.thread.chatId, root.thread.platform);
    }
  }
  Component.onCompleted: if (root.thread && root.thread.compose !== true && root.service) root.service.socialMarkRead(root.thread.accountId, root.thread.chatId, root.thread.platform)
}