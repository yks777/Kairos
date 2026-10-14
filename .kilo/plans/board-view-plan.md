# Plan: Implement Board View in PlanTab

## Goal
Replace the current Eisenhower matrix view in the Plan tab with a board view similar to Super Productivity's boards. The board view will display panels (columns) of the active board, allowing users to drag and drop tasks between panels to move them and drag within a panel to reorder tasks.

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

## Implementation Plan

### 1. Create BoardColumn Component
Create a new QML file: `components/plan/BoardColumn.qml`

This component will display a single panel (column) with:
- A header showing the panel title and an edit button (to modify panel properties)
- An "Add task" input field at the top or bottom
- A list of tasks in the panel, ordered by:
  1. The panel's `taskIds` array (if not empty) for manual order
  2. By creation date for tasks not in `taskIds` (fallback)
- Drag and drop support:
  - Accept tasks dragged from other columns to move the task to this panel (using `moveTaskToPanel`)
  - Allow dragging tasks within the column to reorder them (by updating the panel's `taskIds` via `reorderPanelTasks`)
- Visual feedback for drag and drop (highlight when dragging over)

### 2. Modify PlanView.qml
Replace the fixed `RowLayout` of four `MatrixColumn` instances with a dynamic layout that generates `BoardColumn` instances for each panel of the active board.

Changes to `PlanView.qml`:
- Keep the `MatrixToolbar` (for the completed tasks button)
- Replace the `RowLayout` containing `MatrixColumn` instances with a `RowLayout` that:
  - Iterates over `service.panelsForBoard(service.activeBoardId)`
  - For each panel, instantiates a `BoardColumn` with:
    - `panelId`: the panel's id
    - `service`: the service object
- Keep the `CompletedPopup` for showing completed tasks

### 3. BoardColumn Details
#### Properties
- `panelId`: string (id of the panel to display)
- `service`: object (the service instance)

#### Internal State
- `editorOpen`: boolean (for task editor visibility)
- `menuTaskId`: string (id of task whose menu is open)
- `dropHighlight`: boolean (visual feedback for drag over)
- `listFrozen`: boolean (to prevent interaction during drag)

#### Signals
- `cardMenu(string taskId)`: emitted when task menu is requested

#### Logic
- `panelTasks`: computed property that returns tasks for the panel in the correct order:
  1. If `panel.taskIds` is not empty, order tasks by their index in `taskIds` (tasks not in `taskIds` are appended at the end in creation order)
  2. If `panel.taskIds` is empty, order tasks by creation date
- The `tasksForPanel` function will filter tasks by `boardId` matching the panel's `boardId` and exclude completed tasks (`completedAt` is null)
- Drag and drop:
  - `DropArea` covering the list:
    - `onEntered`: set `dropHighlight = true`
    - `onExited`: set `dropHighlight = false`
    - `onDropped`: 
      - If the dropped task is from a different panel, call `service.moveTaskToPanel(task.id, panelId)`
      - If the dropped task is from the same panel, we need to reorder within the panel (update `taskIds`). This requires knowing the drag source and the drop position. We can implement this by:
        - Storing the dragged task id when drag starts
        - On drop, if the source is the same panel, calculate the new index and call `service.reorderPanelTasks(panelId, newTaskIds)`
- Task delegate: `TaskCard` (same as in MatrixColumn) with actions for toggle menu, start focus, complete, edit, remove, and drag started/finished.
- Empty state: show a message when there are no tasks.
- Add task: a button or input field that opens a task editor to create a new task in this panel (using `service.createTask(title, columnId)` but note: we need to map to a columnId for backward compatibility? Actually, the `moveTaskToPanel` function will set the `columnId` based on the panel index. However, when creating a new task, we should set its `columnId` to a placeholder? Alternatively, we can create the task without a columnId and then move it to the panel? But the service's `createTask` requires a `columnId`. We can use a dummy columnId (like "q1") and then immediately move the task to the panel using `moveTaskToPanel`? Or we can extend the service to create a task directly in a panel.

Looking at the service, there is no direct function to create a task in a panel. However, we can create a task in the default column (q1) and then move it to the panel. But that would be inefficient and might cause flicker.

Alternatively, we can modify the service to add a function `createTaskInPanel(title, panelId)` that:
  1. Creates a task with a temporary columnId (or we can set the columnId based on the panel index)
  2. Adds the task to the panel's `taskIds` (at the end if we want to append)
  3. Sets the task's `boardId` to the panel's boardId

But to keep changes minimal, we can use the existing `createTask` and then `moveTaskToPanel`. Since the task creation and move are fast, it might be acceptable.

However, note that the `createTask` function in the service sets the `columnId` to the provided parameter (or defaults to q1). We can pass a columnId that corresponds to the panel's index (so that the task appears in the correct column immediately) and then we don't need to move it? But the panel's order is determined by `taskIds`, not by `columnId`. The `columnId` is only used for the old matrix view and for the `moveTaskToPanel` function (which uses it to find the task).

Actually, the `moveTaskToPanel` function uses the task's `boardId` and `id` to find the task, and then updates its `columnId` based on the panel index. So if we create a task with the correct `columnId` (based on panel index) and the correct `boardId`, then the task will be in the correct column for the matrix view, but for the board view we rely on the panel's `taskIds` for order.

We have two options:
  a) When creating a task in a panel, we set the task's `columnId` to the panel's index-based columnId (e.g., if the panel is the second panel, use "q2") and then we also add the task id to the panel's `taskIds` (at the end). We can do this by calling `service.createTask(title, columnId)` and then `service.reorderPanelTasks(panelId, newTaskIds)` where we append the new task id to the existing `taskIds`.
  b) We extend the service with a function that does both steps.

Given that we are already planning to modify the service logic in BoardColumn, we can do option (a) in the BoardColumn without modifying the service.

But note: the service's `panelsForBoard` returns the panels, and we can get the panel's index in the board to compute the columnId.

We can compute the columnId as: `Model.COLUMNS[index]` or if index >= length of COLUMNS, then "q" + (index+1).

We have access to `Model.js` in QML? We can import it.

In BoardColumn.qml, we can do:
```qml
import "logic/Model.js" as Model
```

Then, in the component, we can get the panel object from the service? We don't have the panel object directly, only the panelId. We can get the panel by iterating over `service.panelsForBoard(service.activeBoardId)` and finding the one with matching id.

Alternatively, we can pass the panel object to the BoardColumn? But we only have the panelId.

We can compute the index by:
```javascript
function getPanelIndex(panelId) {
    var panels = service.panelsForBoard(service.activeBoardId);
    for (var i = 0; i < panels.length; i++) {
        if (panels[i].id === panelId) {
            return i;
        }
    }
    return -1;
}
```

Then, the columnId for the panel is:
```javascript
var columnId = Model.COLUMNS[index];
if (!columnId) {
    columnId = "q" + (index + 1);
}
```

### 4. Task Ordering in BoardColumn
We need to compute the list of tasks to display in the correct order.

Algorithm:
1. Get all tasks for the panel's board that are not completed: `service.tasks.filter(task => task.boardId === panel.boardId && !task.completedAt)`
   But we don't have the panel's boardId. We can get it from the panel object (which we can find by id) or we can note that the panel's boardId is stored in the panel.

We can get the panel object by:
```javascript
function getPanel() {
    var panels = service.panelsForBoard(service.activeBoardId);
    for (var i = 0; i < panels.length; i++) {
        if (panels[i].id === panelId) {
            return panels[i];
        }
    }
    return null;
}
```

Then, we can get the panel's boardId from the panel object.

2. Separate the tasks into two groups:
   - orderedTasks: tasks whose id is in panel.taskIds, ordered by their index in taskIds
   - remainingTasks: tasks whose id is not in panel.taskIds, ordered by creation date

3. Concatenate orderedTasks and remainingTasks.

### 5. Drag and Drop Implementation
We'll use a `DropArea` over the list, similar to MatrixColumn.

For drag source, we can use the same approach as MatrixColumn: the `TaskCard` has `onDragStarted` and `onDragFinished` signals that set `listFrozen` to prevent interaction during drag.

When a task is dragged from this column, we store the dragged task id in a property (e.g., `draggedTaskId`).

On drop in the DropArea:
- If there is a dragged task and it is from a different panel (we can check by comparing the panelId of the source and the target), then we call `service.moveTaskToPanel(draggedTaskId, panelId)`
- If the dragged task is from the same panel, we need to reorder the tasks in the panel. We can do this by:
  - Getting the current list of task ids in the panel (from panel.taskIds, or if empty, from the ordered task ids by creation date)
  - Removing the dragged task id from its current position
  - Inserting it at the new position (based on the drop index)
  - Calling `service.reorderPanelTasks(panelId, newTaskIds)`

We need to know the drop index. We can approximate it by the index of the task over which we dropped, or by the position in the list.

We can use the same approach as in the MatrixColumn: the DropArea is over the entire list, and we can use the `drop.y` coordinate to estimate the index.

However, for simplicity, we can implement only moving between panels and not reordering within a panel in the first iteration, and then add reordering later.

But the user likely expects to be able to reorder within a column.

Given the complexity, we might want to look at how the MatrixColumn handles drag and drop within a column? Actually, the MatrixColumn does not support reordering within a column because the columns are fixed and the order is by creation date. The user cannot reorder tasks within a quadrant in the current matrix view.

In the board view, reordering within a column is a key feature.

We can implement the reordering by using the same technique as in the board-panel component from super productivity, which uses CDK drag drop list.

In QML, we can use the `DragHandler` and `DropHandler` items, but we are using the `DropArea` from QtQuick.Controls.

Alternatively, we can use the `ListView` and its `drag` property? The ListView in QtQuick does not have built-in drag and drop for reordering.

We can implement it manually by:
  - When dragging starts, we store the dragged item's index
  - While dragging, we show a placeholder
  - On drop, we move the item in the model

But our model is not a simple list; we have a computed list based on taskIds and creation date.

Given the time constraints, we might decide to only support moving tasks between panels in the initial implementation, and leave reordering within a panel for a later improvement.

However, the user's request is to make the plan tab similar to the boards in super productivity, which includes reordering within a column.

We should attempt to implement both.

### 6. Adding Tasks
We'll add an "Add task" button at the bottom of the column that opens a task editor (similar to the existing TaskEditor) to create a new task in this panel.

When the task is created, we will:
  - Create the task with a temporary columnId (based on the panel index) using `service.createTask(title, columnId)`
  - Then, we will add the task id to the end of the panel's taskIds (if we want to append) by calling `service.reorderPanelTasks(panelId, newTaskIds)` where we append the new task id.

Alternatively, we can insert the new task at the top of the taskIds? We'll follow the convention of adding to the bottom.

### 7. Styling and Layout
We'll mimic the styling of MatrixColumn where possible, but adjust for the board look.

We'll use the same colors, fonts, and spacing from `Style` and `Color`.

### 8. Dependencies
We need to ensure that the service's methods are working correctly. We should test the service methods for panels and tasks.

### 9. Fallback
If there are no panels for the active board, we should show a message or create a default panel? The service's `activeBoard()` returns a board, and when a board is created, it gets default panels. So there should always be panels.

### 10. Testing
We will need to test:
  - Creating a new board and panel
  - Adding tasks to a panel
  - Moving tasks between panels
  - (Optional) Reordering tasks within a panel

## Open Questions
- Should we keep the matrix view as an option? The user asked to replace the plan tab with the board view, so we will replace it entirely.
- How to handle the panel edit button? We can open a dialog to edit the panel title and other properties (like filters). For now, we can just make it a placeholder or implement a simple title edit.
- Should we show the number of tasks in the panel header? Yes, similar to the matrix column.

## Subtasks
1. Create BoardColumn.qml
2. Modify PlanView.qml
3. Implement task ordering logic in BoardColumn
4. Implement drag and drop for moving between panels
5. Implement drag and drop for reordering within panel (optional for first iteration)
6. Implement add task functionality
7. Style the component
8. Test the implementation

## Resources
- Existing MatrixColumn.qml for reference
- Service.qml for panel and task methods
- Model.js for constants and utility functions
- Super Productivity's board-panel component for inspiration (but we are implementing in QML, not Angular)

## Notes
- We must be careful not to break existing functionality. Since we are replacing the PlanView, any code that relies on the matrix view (like the `tasksForColumn` function) might be unused in the plan tab, but it is still used by other parts? The `tasksForColumn` is only used in MatrixColumn, which we are removing from PlanView. However, the matrix view might be used elsewhere? We don't know. We should check if MatrixColumn is used in other QML files.

Let's check if MatrixColumn is used elsewhere.
</think>
<tool_call>
<function=grep>