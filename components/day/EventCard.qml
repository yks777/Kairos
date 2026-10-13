import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../../logic/CalendarModel.js" as CalendarModel
import ".."

Rectangle {
  id: root

  property var event: ({})
  property var service: null
  property bool expanded: false

  radius: Style.cornerRadius
  color: Color.popups.background
  border.width: Math.max(1, Style.space(1))
  border.color: hoverArea.containsMouse ? Color.accent : Color.popups.border
  implicitHeight: cardColumn.implicitHeight + Style.space(16)
  Layout.fillWidth: true

  readonly property var details: {
    var serviceRevision = root.service ? root.service.revision : 0;
    serviceRevision;
    if (root.service && typeof root.service.calendarEventDetails === "function")
      return root.service.calendarEventDetails(root.event);
    return CalendarModel.eventDetails(root.event, null, "Google Maps");
  }

  function attendeeStatusLabel(status) {
    var value = String(status || "NEEDS-ACTION").toUpperCase();
    if (value === "ACCEPTED") return "Going";
    if (value === "DECLINED") return "Declined";
    if (value === "TENTATIVE") return "Maybe";
    if (value === "DELEGATED") return "Delegated";
    return "Awaiting reply";
  }

  function attendeeSummary(attendees) {
    var rows = attendees || [];
    var counts = { going: 0, maybe: 0, declined: 0, waiting: 0 };
    for (var i = 0; i < rows.length; i++) {
      var status = String(rows[i].status || "NEEDS-ACTION").toUpperCase();
      if (status === "ACCEPTED") counts.going++;
      else if (status === "TENTATIVE") counts.maybe++;
      else if (status === "DECLINED") counts.declined++;
      else counts.waiting++;
    }
    var parts = [];
    if (counts.going) parts.push(counts.going + " going");
    if (counts.maybe) parts.push(counts.maybe + " maybe");
    if (counts.declined) parts.push(counts.declined + " declined");
    if (counts.waiting) parts.push(counts.waiting + " awaiting");
    return rows.length + (rows.length === 1 ? " guest" : " guests")
      + (parts.length ? " · " + parts.join(", ") : "");
  }

  ColumnLayout {
    id: cardColumn
    anchors.fill: parent
    anchors.margins: Style.space(8)
    spacing: Style.space(6)

    RowLayout {
      id: heading
      Layout.fillWidth: true
      spacing: Style.space(8)

      Rectangle {
        width: Style.space(4)
        height: Style.space(30)
        radius: Style.space(2)
        color: String(root.event.color || "") !== "" ? root.event.color : Color.accent
      }

      Text {
        textFormat: Text.PlainText
        text: String(root.event.timeRange || "")
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.weight: Font.DemiBold
        Layout.preferredWidth: Style.space(104)
      }

      Text {
        textFormat: Text.PlainText
        text: String(root.event.title || "(untitled)")
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        visible: String(root.event.calendar || "") !== ""
        textFormat: Text.PlainText
        text: String(root.event.calendar || "")
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        Layout.maximumWidth: Style.space(100)
      }

      Text {
        textFormat: Text.PlainText
        text: root.expanded ? "−" : "+"
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }

      TapHandler {
        onTapped: {
          root.expanded = !root.expanded;
          if (root.expanded && root.service && typeof root.service.calendarLoadDetails === "function")
            root.service.calendarLoadDetails(String(root.event.uid || ""));
        }
      }
    }

    ColumnLayout {
      visible: root.expanded
      Layout.fillWidth: true
      spacing: Style.space(6)

      RowLayout {
        visible: root.details.meeting !== null || (root.details.links && root.details.links.length > 0)
        Layout.fillWidth: true
        spacing: Style.space(6)

        FlowButton {
          visible: root.details.meeting !== null
          text: "Join"
          primary: true
          onClicked: {
            if (root.service && root.details.meeting && typeof root.service.openUrl === "function")
              root.service.openUrl(root.details.meeting.url);
          }
        }

        Text {
          visible: root.details.meeting !== null
          textFormat: Text.PlainText
          text: root.details.meeting ? root.details.meeting.label : ""
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Repeater {
          model: root.details.links || []
          delegate: FlowButton {
            required property var modelData
            text: String(modelData.label || "Open link")
            onClicked: {
              if (root.service && typeof root.service.openUrl === "function") root.service.openUrl(modelData.url);
            }
          }
        }
      }

      RowLayout {
        visible: String(root.details.location || "") !== "" || String(root.details.directions || "") !== ""
        Layout.fillWidth: true
        spacing: Style.space(6)

        Text {
          textFormat: Text.PlainText
          text: String(root.details.location || "")
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }

        FlowButton {
          visible: String(root.details.directions || "") !== ""
          text: "Directions"
          onClicked: {
            if (root.service && typeof root.service.openUrl === "function") root.service.openUrl(root.details.directions);
          }
        }
      }

      Text {
        visible: String(root.details.description || "") !== ""
        textFormat: Text.PlainText
        text: String(root.details.description || "")
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      Text {
        visible: root.details.organizer !== null
        textFormat: Text.PlainText
        text: root.details.organizer ? "Organizer: " + CalendarModel.personLabel(root.details.organizer) : ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      Text {
        visible: String(root.details.status || "").toUpperCase() === "CANCELLED"
        textFormat: Text.PlainText
        text: "Cancelled"
        color: Color.urgent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }

      ColumnLayout {
        visible: root.details.attendees && root.details.attendees.length > 0
        Layout.fillWidth: true
        spacing: Style.space(3)

        Text {
          textFormat: Text.PlainText
          text: root.attendeeSummary(root.details.attendees)
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          Layout.fillWidth: true
        }

        Repeater {
          model: root.details.attendees || []
          delegate: Text {
            required property var modelData
            textFormat: Text.PlainText
            text: "• " + (modelData.name || modelData.email || "Guest") + " · " + root.attendeeStatusLabel(modelData.status)
            color: modelData.organizer ? Color.accent : Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }
      }
    }
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    z: 2
  }
}
