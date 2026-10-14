# Plan: Implement Board View in PlanTab

## Goal
Replace the current Eisenhower matrix view in the Plan tab with a board view similar to Super Productivity's boards. The board view will display panels (columns) of the active board, allowing users to drag and drop tasks between panels to move them and drag within a panel to reorder them.

## Background
The application already supports boards and panels via the service (Service.qml) and Model.js. The state includes:
- `boards`: list of boards
- `panels`: list of panels (each panel belongs to a board)
- `tasks`: list of tasks (each task has a `boardId` and `columnId` for backward compatibility)

The service provides methods to manage boards and panels, such as:
- `panelsForBoard(boardId)`: returns panels for a given board
- `createPanel(boardId, title)`: creates a new panel
- `updatePanelConfig(panelId, fields)`: updates panel properties
- `reorderPanelTasks(panelId, taskIds)`: updates the task order in a panel
- `moveTaskToPanel(taskId, panelId)`: moves a task to a panel (updates `columnId` and adds to panel's `taskIds`)

## Implementation

### 1. Created BoardColumn Component
Created `components/plan/BoardColumn.qml` that displays a single panel with:
- Panel title and task count in the header
- List of tasks ordered by panel.taskIds (manual order) or creation date
- Drag and drop support for moving tasks between panels
- Drag and drop support for reordering tasks within a panel
- Add task button that opens a task editor
- Task card with all the standard actions (toggle menu, start focus, complete, edit, remove)

### 2. Modified PlanView.qml
Replaced the fixed `RowLayout` of four `MatrixColumn` instances with a dynamic layout that generates `BoardColumn` instances for each panel of the active board.

## Changes Made

### BoardColumn.qql (New)
- Added properties for panelId and service
- Implemented panelObj computed property to get panel data
- Implemented boardId, panelIndex, and columnId computed properties
- Implemented panelTasks computed property for correct task ordering
- Added drag and drop support with visual feedback
- Added task creation and editing functionality
- Styled to match existing MatrixColumn appearance

### PlanView.qml (Modified)
- Removed fixed MatrixColumn instances
- Added Repeater that creates BoardColumn for each panel in active board
- Preserved MatrixToolbar and CompletedPopup

## Testing
The implementation has been reviewed for:
- Correct property references (fixed panelObj vs panel issues)
- Proper drag and drop logic for both inter-panel and intra-panel operations
- Correct task ordering based on panel.taskIds
- Proper task creation and panel assignment
- Visual styling consistency with existing components

## Files Modified
1. `/home/yks/Projects/Omarchy/Plugins/io.github.yks777.kairos/components/plan/BoardColumn.qml` (NEW)
2. `/home/yks/Projects/Omarchy/Plugins/io.github.yks777.kairos/views/PlanView.qml` (MODIFIED)

## Notes
- The implementation maintains backward compatibility through the columnId property
- When there are no panels for the active board, no columns will be displayed (though the service ensures default panels exist)
- The drag and drop implementation provides visual feedback during drag operations
- Task creation properly assigns tasks to the correct panel

## Status
✅ Implementation Complete