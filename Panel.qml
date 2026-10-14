import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "components"
import "views"

// Standalone Kairos panel, loaded by the shell panel-loader (summon/toggle/hide).
Panel {
  id: root
  moduleName: "io.github.yks777.kairos"
  manageIpc: false

  // Injected by the shell panel-loader.
  property var shell: null
  property var manifest: null
  property var service: null
  property string omarchyPath: ""

  property var anchorItem: null
  property var hostWidget: null
  // Identity the bar uses for the open-panel dot and Tab-switching.
  readonly property var barIdentity: hostWidget || root

  // Standalone panel has no live bar injected by the shell loader; the shim
  // satisfies the members KeyboardPanel reads on its open path (position,
  // barSize, activePopout, requestPopout, releasePopout).
  readonly property QtObject barShim: QtObject {
    property string position: "bottom"
    property int barSize: 0
    property var activePopout: null
    function requestPopout(owner) {}
    function releasePopout(owner) {}
  }

  function pluginId() {
    if (root.manifest && root.manifest.id) return String(root.manifest.id);
    return "io.github.yks777.kairos";
  }

  function open(payloadJson) {
    var payload = {};
    try { payload = JSON.parse(payloadJson || "{}") || {}; } catch (error) {}
    var view = String(payload.view || "");
    var pending = "";
    if (root.service) {
      try { pending = String(root.service.consumePendingView() || ""); } catch (error) {}
    }
    if (view === "") view = pending;
    if (["day", "focus", "plan", "stats", "markets", "social", "settings"].indexOf(view) !== -1)
      root.currentView = view;
    root.controller.show();
    Qt.callLater(function() {
      if (root.opened) keyCatcher.forceActiveFocus();
    });
  }

  function close() {
    root.controller.hide();
  }

  function toggle() {
    if (root.opened) root.close();
    else root.open("{}");
  }

  function dismiss() {
    root.close();
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction);
    return false;
  }

  function goSettings() {
    if (root.currentView !== "settings") root.returnView = root.currentView;
    root.currentView = "settings";
  }

  function boardTitle() {
    if (!root.service || !root.service.boards) return "";
    var boards = root.service.boards;
    for (var i = 0; i < boards.length; i++) {
      if (boards[i].id === root.service.activeBoardId) return String(boards[i].title || "");
    }
    return boards.length > 0 ? String(boards[0].title || "") : "";
  }

  readonly property int cardWidth: {
    if (root.currentView === "plan") return Style.space(880);
    if (root.currentView === "markets") return Style.space(640);
    if (root.currentView === "social") return Style.space(620);
    if (root.currentView === "day") return Style.space(560);
    if (root.currentView === "stats") return Style.space(480);
    if (root.currentView === "settings") return Style.space(620);
    return Style.space(400);
  }

  readonly property int contentHeight: {
    if (root.currentView === "plan") return Style.space(500);
    if (root.currentView === "markets") return Style.space(520);
    if (root.currentView === "social") return Style.space(620);
    if (root.currentView === "day") return Style.space(620);
    if (root.currentView === "stats") return Style.space(540);
    if (root.currentView === "settings") return Style.space(560);
    return Style.space(460);
  }

  property string currentView: "day"
  property string returnView: "day"

  KeyboardPanel {
    id: panel
    anchorItem: centerAnchor
    owner: root.barIdentity
    bar: root.barShim
    open: root.opened
    centerOnBar: true
    gap: panel.screenH / 2 - panel.barH
      - (cardContent.implicitHeight + panel.verticalContentInset) / 2
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.cardWidth)
    contentHeight: Math.min(
      cardContent.implicitHeight + panel.verticalContentInset,
      Math.max(120, panel.screenH - (Style.bar.sizeHorizontal + Style.gapsOut * 2))
    )

    Item {
      id: centerAnchor
      anchors.fill: parent
    }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.dismiss()
      onTabRequested: function(direction) { root.switchPanel(direction); }

      ColumnLayout {
        id: cardContent
        width: parent.width
        spacing: Style.space(8)

        Header {
          boardTitle: root.boardTitle()
          onOpenSettings: root.goSettings()
          onClosePanel: root.dismiss()
        }

        NavigationTabs {
          currentView: root.currentView === "settings" ? root.returnView : root.currentView
          visible: root.currentView !== "settings"
          onSelectView: function(view) { root.currentView = view; }
        }

        DayView {
          service: root.service
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "day"
        }

        FocusView {
          service: root.service
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "focus"
        }

        PlanView {
          service: root.service
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "plan"
        }

        StatsView {
          service: root.service
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "stats"
        }

        MarketsView {
          service: root.service
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "markets"
        }

        SocialView {
          service: root.service
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "social"
        }

        SettingsView {
          service: root.service
          onBack: root.currentView = root.returnView
          Layout.fillWidth: true
          Layout.preferredHeight: root.contentHeight
          visible: root.currentView === "settings"
        }
      }
    }
  }
}