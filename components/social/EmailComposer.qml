import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."

ColumnLayout {
  id: root
  property var service: null
  property var account: null
  property string mode: "reply"
  property var draft: ({})
  property string recipient: ""
  property string subject: ""
  property string body: ""
  signal close()
  spacing: Style.space(6)
  Layout.fillWidth: true
  function applyDraft() { root.recipient = String(root.draft && root.draft.to || ""); root.subject = String(root.draft && root.draft.subject || ""); root.body = String(root.draft && root.draft.body || ""); }
  Text { textFormat: Text.PlainText; text: root.mode === "replyAll" ? "REPLY ALL" : root.mode === "forward" ? "FORWARD" : root.mode === "new" ? "NEW EMAIL" : "REPLY"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.letterSpacing: 1; Layout.fillWidth: true }
  FlowInput { text: root.recipient; placeholder: "To"; Layout.fillWidth: true; onTextChanged: root.recipient = text }
  FlowInput { text: root.subject; placeholder: "Subject"; Layout.fillWidth: true; onTextChanged: root.subject = text }
  Rectangle { Layout.fillWidth: true; Layout.preferredHeight: Style.space(120); radius: Style.cornerRadius; color: "transparent"; border.color: Color.popups.border; border.width: Math.max(1, Style.space(1)); TextEdit { anchors.fill: parent; anchors.margins: Style.space(8); text: root.body; color: Color.popups.text; selectionColor: Color.accent; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall; wrapMode: TextEdit.Wrap; onTextChanged: root.body = text } }
  RowLayout { spacing: Style.space(8); Layout.alignment: Qt.AlignRight; FlowButton { text: "Cancel"; onClicked: root.close() } FlowButton { text: "Send"; primary: true; enabledButton: !!(root.service && root.account && root.recipient.trim() !== ""); onClicked: { if (!root.service || !root.account) return; var queued = root.service.emailSend(root.account.id, { to: root.recipient, subject: root.subject, body: root.body, inReplyTo: root.draft ? root.draft.originalId : "", references: root.draft ? root.draft.references : "" }); if (queued) root.close(); } } }
  onDraftChanged: root.applyDraft()
  Component.onCompleted: root.applyDraft()
}