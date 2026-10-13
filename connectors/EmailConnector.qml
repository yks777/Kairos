import QtQuick

Item {
  id: root
  property var service: null
  readonly property string platform: "email"
  readonly property var accounts: root.service ? root.service.accounts : []

  readonly property var events: root.service ? root.service.events : []
  readonly property bool available: !!(root.service && root.service.available)
  readonly property string statusText: root.service ? root.service.statusText : "Email service unavailable."
}