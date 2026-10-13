const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const ObsidianModel = loadQmlLibrary("logic/ObsidianModel.js");

const date = new Date(2026, 9, 12, 9, 7);

test("daily note paths use vault, folder, year, month, and local date", () => {
  const settings = { vaultPath: "/home/user/Notes Vault", dailyNotesFolder: "Daily Notes" };
  assert.equal(
    ObsidianModel.resolveDailyNotePath(settings, date),
    "/home/user/Notes Vault/Daily Notes/2026/10/2026-10-12.md"
  );
  assert.equal(
    ObsidianModel.relativeDailyNotePath(settings, date),
    "Daily Notes/2026/10/2026-10-12.md"
  );
  assert.equal(ObsidianModel.parentPath("/home/user/Vault/a/b.md"), "/home/user/Vault/a");
});

test("daily path resolution rejects traversal and non-absolute vault paths", () => {
  assert.equal(ObsidianModel.resolveDailyNotePath({ vaultPath: "relative", dailyNotesFolder: "Daily" }, date), "");
  assert.equal(ObsidianModel.resolveDailyNotePath({ vaultPath: "/vault", dailyNotesFolder: "../outside" }, date), "");
  assert.equal(ObsidianModel.resolveDailyNotePath({ vaultPath: "/vault/../outside", dailyNotesFolder: "Daily" }, date), "");
});

test("built-in daily note template is exact and uses the requested Portuguese metadata", () => {
  assert.equal(
    ObsidianModel.renderTemplate("2026-10-12 09:07"),
    "---\ndata e hora: 2026-10-12 09:07\ntags:\n  - Diario\n---\n-\n"
  );
  assert.equal(ObsidianModel.formatDateTime(date), "2026-10-12 09:07");
});

test("static templates get a timestamp while Templater markup is never executed", () => {
  const source = "---\ndata e hora: old value\ntags:\n  - Daily\n---\n\nNotes\n";
  assert.equal(
    ObsidianModel.renderConfiguredTemplate(source, "2026-10-12 09:07"),
    "---\ndata e hora: 2026-10-12 09:07\ntags:\n  - Daily\n---\n\nNotes\n"
  );
  assert.equal(
    ObsidianModel.renderConfiguredTemplate("<% tp.file.title %>", "2026-10-12 09:07"),
    ObsidianModel.renderTemplate("2026-10-12 09:07")
  );
});

test("task parsing ignores code fences and preserves checkbox line indexes", () => {
  const content = [
    "# Today",
    "- [ ] Write tests",
    "  - [x] Review code",
    "```md",
    "- [ ] This is code, not a task",
    "```",
    "- [X] Ship"
  ].join("\n");
  const tasks = ObsidianModel.parseTasks(content);
  assert.deepEqual(tasks.map((task) => [task.lineIndex, task.checked, task.text]), [
    [1, false, "Write tests"],
    [2, true, "Review code"],
    [6, true, "Ship"]
  ]);
});

test("task toggling changes only the selected checkbox", () => {
  const content = "- [ ] One\n- [x] Two\n";
  assert.equal(ObsidianModel.toggleTask(content, 0), "- [x] One\n- [x] Two\n");
  assert.equal(ObsidianModel.toggleTask(content, 1), "- [ ] One\n- [ ] Two\n");
  assert.equal(ObsidianModel.toggleTask(content, 4), content);
});

test("new tasks go after the last task in the first section with tasks", () => {
  const content = "# First\n- [ ] A\n- [x] B\n\n# Second\n- [ ] C\n";
  assert.equal(
    ObsidianModel.addTask(content, "New task"),
    "# First\n- [ ] A\n- [x] B\n- [ ] New task\n\n# Second\n- [ ] C\n"
  );
  assert.equal(ObsidianModel.addTask("# Empty\n", "Later"), "# Empty\n- [ ] Later\n");
  assert.equal(ObsidianModel.addTask("- [ ] Existing\n", "  "), "- [ ] Existing\n");
});

test("Obsidian URIs encode vault names and relative paths and reject traversal", () => {
  assert.equal(
    ObsidianModel.obsidianUri("My Vault", "Daily Notes/2026/10/2026-10-12.md"),
    "obsidian://open?vault=My%20Vault&file=Daily%20Notes%2F2026%2F10%2F2026-10-12.md"
  );
  assert.equal(ObsidianModel.obsidianUri("My Vault", "../secret.md"), "");
});
