const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const ObsidianModel = loadQmlLibrary("logic/ObsidianModel.js");

const date = new Date(2026, 9, 12, 9, 7);

test("daily note paths live directly in the diary folder with the local date", () => {
  const diaryPath = "/home/user/Notes Vault/Daily Notes";
  const vaultRoot = "/home/user/Notes Vault";
  assert.equal(
    ObsidianModel.resolveDailyNotePath(diaryPath, date),
    "/home/user/Notes Vault/Daily Notes/2026-10-12.md"
  );
  assert.equal(
    ObsidianModel.relativeDailyNotePath(diaryPath, vaultRoot, date),
    "Daily Notes/2026-10-12.md"
  );
  assert.equal(
    ObsidianModel.relativeDailyNotePath(vaultRoot, vaultRoot, date),
    "2026-10-12.md"
  );
  assert.equal(ObsidianModel.parentPath("/home/user/Vault/a/b.md"), "/home/user/Vault/a");
});

test("vault name defaults to vault root basename and supports an override", () => {
  assert.equal(ObsidianModel.vaultName("/home/user/Notes Vault", ""), "Notes Vault");
  assert.equal(ObsidianModel.vaultName("/home/user/Notes Vault", "Custom Name"), "Custom Name");
  assert.equal(ObsidianModel.vaultName("", ""), "");
  assert.equal(ObsidianModel.vaultName("", "Custom"), "Custom");
  assert.equal(ObsidianModel.vaultName("/home/yks/Obsidian/Meu-segundo-cerebro", ""), "Meu-segundo-cerebro");
});

test("relative path rejects diary folders outside the vault root", () => {
  assert.equal(
    ObsidianModel.relativeDailyNotePath("/vault/Daily Notes", "/other/vault", date),
    ""
  );
});

test("daily path resolution rejects traversal and non-absolute diary paths", () => {
  assert.equal(ObsidianModel.resolveDailyNotePath("relative", date), "");
  assert.equal(ObsidianModel.resolveDailyNotePath("/vault/../outside", date), "");
  assert.equal(ObsidianModel.resolveDailyNotePath("", date), "");
});

test("date-time helper formats the local timestamp", () => {
  assert.equal(ObsidianModel.formatDateTime(date), "2026-10-12 09:07");
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
    ObsidianModel.obsidianUri("My Vault", "Daily Notes/2026-10-12.md"),
    "obsidian://open?vault=My%20Vault&file=Daily%20Notes%2F2026-10-12.md"
  );
  assert.equal(ObsidianModel.obsidianUri("My Vault", "../secret.md"), "");
});
