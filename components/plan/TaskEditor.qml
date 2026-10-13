import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."

RowLayout {
  id: root

  signal saved(string title)
  signal cancelled()

  spacing: Style.space(6)
  Layout.fillWidth: true

  FlowInput {
    id: input
    placeholder: "Task title..."
    Layout.fillWidth: true
    onAccepted: root.submit()
    onCancelled: root.cancel()
  }

  FlowButton {
    text: "Add"
    primary: true
    enabledButton: String(input.text || "").trim() !== ""
    onClicked: root.submit()
  }

  FlowIconButton {
    glyph: "×"
    tip: "Cancel task creation"
    boxSize: Style.space(32)
    onClicked: root.cancelled()
  }

  function focusInput() { input.focusInput(); }

  function submit() {
    var title = String(input.text || "").trim();
    if (title === "") return;
    input.text = "";
    root.saved(title);
  }

  function cancel() {
    input.text = "";
    root.cancelled();
  }
}
