import QtQuick

Item {
  id: root
  property string platform: ""
  property var service: null

  readonly property bool available: !!(root.service && root.service.platformAvailable(root.platform))
  readonly property var accounts: root.service ? root.service.accountsForPlatform(root.platform) : []
  readonly property var events: root.service ? root.service.eventsForPlatform(root.platform) : []
  readonly property string statusText: root.service ? root.service.platformStatus(root.platform) : "Social bridge unavailable."
}