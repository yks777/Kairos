import QtQuick
import Quickshell
import Quickshell.Io
import "../logic/ObsidianModel.js" as ObsidianModel

Item {
  id: root

  property var service: null
  property string currentDateKey: ""
  property string currentPath: ""
  property string currentContent: ""
  property var currentTasks: []
  property string todayTaskDateKey: ""
  property string todayTaskPath: ""
  property var todayTasks: []
  property bool todayTasksLoaded: false
  property bool todayTasksBusy: false
  property string lastError: ""
  property string testStatus: ""
  property bool noteLoaded: false
  property bool fileMissing: false
  property bool pendingOpen: false
  property string pendingOpenPath: ""
  property var pendingOpenDate: null
  property string pendingCreatePath: ""
  property string pendingCreateDateKey: ""
  property var pendingCreateDate: null
  property string pendingInitialTask: ""
  property var writeQueue: []
  property var activeWrite: null
  property bool writeBusy: false
  property bool pendingTaskAdd: false
  property string pendingAddText: ""
  property string pendingAddDateKey: ""
  property string observedObsidianConfig: ""
  property string vaultRoot: ""
  property bool vaultRootReady: false

  readonly property string writeScript: localPath(Qt.resolvedUrl("../scripts/obsidian-write"))
  readonly property bool obsidianEnabled: !!(root.service && root.service.settings && root.service.settings.obsidian
    && root.service.settings.obsidian.enabled === true)

  function localPath(url) {
    var value = String(url || "");
    if (value.indexOf("file://") === 0) value = value.substring(7);
    try { return decodeURIComponent(value); } catch (error) { return value; }
  }

  function testConnection() {
    var path = String(root.obsidianSettings().diaryPath || "").trim();
    if (path === "" || path.charAt(0) !== "/") {
      root.testStatus = "Enter an absolute diary folder path before testing.";
      root.bumpService();
      return;
    }
    testProc.command = ["python3", "-c",
      "import os,sys; p=sys.argv[1]; sys.exit(0 if os.path.isdir(p) and os.access(p, os.R_OK | os.W_OK) else 1)", path];
    testProc.running = true;
  }

  function detectVaultRoot() {
    root.vaultRootReady = false;
    root.vaultRoot = "";
    var path = String(root.obsidianSettings().diaryPath || "").trim();
    if (!path || path.charAt(0) !== "/") {
      root.vaultRootReady = true;
      root.bumpService();
      return;
    }
    vaultRootProc.command = ["python3", "-c",
      "import os,sys\np=os.path.normpath(sys.argv[1])\nwhile True:\n    if os.path.isdir(os.path.join(p,'.obsidian')):\n        print(p)\n        sys.exit(0)\n    parent=os.path.dirname(p)\n    if parent==p:\n        break\n    p=parent\nsys.exit(1)", path];
    vaultRootProc.running = true;
  }

  function obsidianSettings() {
    return root.service && root.service.settings && root.service.settings.obsidian
      ? root.service.settings.obsidian : {};
  }

  function obsidianConfigKey() {
    try { return JSON.stringify(root.obsidianSettings()); }
    catch (error) { return "{}"; }
  }

  function handleSettingsChanged() {
    var key = root.obsidianConfigKey();
    if (key === root.observedObsidianConfig) return;
    root.observedObsidianConfig = key;
    if (root.obsidianEnabled && root.service && root.service.stateLoaded) {
      root.detectVaultRoot();
      root.loadNote(new Date());
    }
    else if (!root.obsidianEnabled) root.clearNote();
  }

  function bumpService() {
    if (root.service && typeof root.service.bump === "function") root.service.bump();
  }

  function setError(message) {
    root.lastError = String(message || "");
    if (root.lastError !== "") errorDismiss.restart();
    else errorDismiss.stop();
    root.bumpService();
  }

  function clearNote() {
    root.currentDateKey = "";
    root.currentPath = "";
    root.currentContent = "";
    root.currentTasks = [];
    root.noteLoaded = false;
    root.fileMissing = false;
    root.pendingOpen = false;
    root.pendingOpenPath = "";
    root.pendingOpenDate = null;
    root.pendingTaskAdd = false;
    root.pendingAddText = "";
    root.pendingAddDateKey = "";
    root.vaultRoot = "";
    root.vaultRootReady = false;
    root.bumpService();
  }

  function loadNote(date) {
    if (!root.obsidianEnabled) {
      root.clearNote();
      return;
    }
    root.loadForDate(date, false);
  }

  function loadForDate(date, openAfterLoad) {
    var config = root.obsidianSettings();
    var path = ObsidianModel.resolveDailyNotePath(config.diaryPath, date);
    var key = ObsidianModel.dateKey(date);
    if (!path || !key) {
      root.currentDateKey = key;
      root.currentPath = "";
      root.currentTasks = [];
      root.currentContent = "";
      root.noteLoaded = true;
      root.fileMissing = false;
      root.pendingOpen = false;
      root.pendingOpenPath = "";
      root.pendingOpenDate = null;
      root.setError("Set an absolute Obsidian diary folder path in Settings.");
      return;
    }
    if (root.currentPath === path && root.currentDateKey === key && root.noteLoaded) {
      if (openAfterLoad) {
        root.pendingOpen = true;
        root.pendingOpenPath = path;
        root.pendingOpenDate = new Date(date);
        root.finishOpenRequest();
      }
      return;
    }
    root.currentPath = path;
    root.currentDateKey = key;
    root.currentContent = "";
    root.currentTasks = [];
    root.noteLoaded = false;
    root.fileMissing = false;
    root.pendingOpen = !!openAfterLoad;
    root.pendingOpenPath = openAfterLoad ? path : "";
    root.pendingOpenDate = openAfterLoad ? new Date(date) : null;
    root.lastError = "";
    errorDismiss.stop();
    noteFile.path = path;
    root.bumpService();
  }

  function tasksForDate(date) {
    var key = ObsidianModel.dateKey(date);
    if (!root.obsidianEnabled || !key) return [];
    if (root.currentDateKey !== key) root.loadNote(date);
    return root.currentDateKey === key ? root.currentTasks : [];
  }

  function tasksForToday() {
    if (!root.obsidianEnabled) return [];
    var date = new Date();
    var key = ObsidianModel.dateKey(date);
    var path = ObsidianModel.resolveDailyNotePath(root.obsidianSettings().diaryPath, date);
    if (!key || !path) return [];
    if (root.todayTaskDateKey !== key || root.todayTaskPath !== path) {
      root.todayTaskDateKey = key;
      root.todayTaskPath = path;
      root.todayTasks = [];
      root.todayTasksLoaded = false;
      root.todayTasksBusy = true;
      todayTasksFile.path = path;
      root.bumpService();
    }
    return root.todayTasksLoaded ? root.todayTasks : [];
  }

  function applyTodayTasks(content) {
    root.todayTasks = ObsidianModel.parseTasks(content);
    root.todayTasksLoaded = true;
    root.todayTasksBusy = false;
    root.bumpService();
  }

  function applyTodayTaskLoadFailure(error) {
    root.todayTasks = [];
    root.todayTasksLoaded = true;
    root.todayTasksBusy = false;
    if (error !== FileViewError.FileNotFound)
      root.setError("Could not read today's Obsidian note: " + error);
    else root.bumpService();
  }

  function applyContent(content) {
    root.currentContent = String(content || "").replace(/\r\n?/g, "\n");
    root.currentTasks = ObsidianModel.parseTasks(root.currentContent);
    root.noteLoaded = true;
    root.lastError = "";
    errorDismiss.stop();
    root.bumpService();
  }

  function handleLoadedContent(content, missing) {
    root.fileMissing = !!missing;
    root.applyContent(content);
    if (root.pendingOpen && root.pendingOpenPath === root.currentPath) {
      if (root.fileMissing) root.beginCreate(root.pendingOpenDate, "");
      else root.finishOpenRequest();
      return;
    }
    if (root.pendingTaskAdd && root.pendingAddDateKey === root.currentDateKey) {
      if (root.fileMissing) {
        var text = root.pendingAddText;
        var date = new Date(root.currentDateKey + "T12:00:00");
        root.pendingTaskAdd = false;
        root.pendingAddText = "";
        root.pendingAddDateKey = "";
        root.beginCreate(date, text);
      } else {
        var pendingText = root.pendingAddText;
        var pendingDate = new Date(root.pendingAddDateKey + "T12:00:00");
        root.pendingTaskAdd = false;
        root.pendingAddText = "";
        root.pendingAddDateKey = "";
        Qt.callLater(function() { root.addTask(pendingDate, pendingText); });
      }
    }
  }

  function openOrCreate(date) {
    if (!root.obsidianEnabled) return;
    var config = root.obsidianSettings();
    var diaryPath = String(config.diaryPath || "").trim();
    if (!diaryPath || diaryPath.charAt(0) !== "/") {
      root.setError("Set an absolute Obsidian diary folder path in Settings.");
      return;
    }
    root.loadForDate(date, true);
  }

  function finishOpenRequest() {
    if (!root.pendingOpen || root.pendingOpenPath !== root.currentPath) return;
    if (!root.vaultRootReady) {
      root.detectVaultRoot();
      return;
    }
    if (!root.vaultRoot) {
      root.pendingOpen = false;
      root.setError("Could not find the Obsidian vault root (no .obsidian directory near the diary folder). The daily note was loaded, but it could not be opened in Obsidian. Set a vault name in Settings if your vault uses a different directory name.");
      return;
    }
    if (root.fileMissing) {
      root.beginCreate(root.pendingOpenDate, "");
      return;
    }
    var settings = root.obsidianSettings();
    var relativePath = ObsidianModel.relativeDailyNotePath(settings.diaryPath, root.vaultRoot, root.pendingOpenDate || new Date());
    var vault = ObsidianModel.vaultName(root.vaultRoot, settings.vaultName);
    var uri = ObsidianModel.obsidianUri(vault, relativePath);
    if (!uri) {
      root.pendingOpen = false;
      root.setError("The daily note path could not be converted to a safe Obsidian URI.");
      return;
    }
    openProc.command = ["xdg-open", uri];
    openProc.running = true;
    root.pendingOpen = false;
    root.pendingOpenPath = "";
    root.pendingOpenDate = null;
  }

  function beginCreate(date, initialTask) {
    if (!root.obsidianEnabled) return;
    var config = root.obsidianSettings();
    var path = ObsidianModel.resolveDailyNotePath(config.diaryPath, date);
    var key = ObsidianModel.dateKey(date);
    if (!path || !key) {
      root.setError("The daily note path is invalid.");
      return;
    }
    root.pendingCreatePath = path;
    root.pendingCreateDateKey = key;
    root.pendingCreateDate = new Date(date);
    root.pendingInitialTask = String(initialTask || "");
    root.writeNewNote("");
  }

  function writeNewNote(initialContent) {
    var date = root.pendingCreateDate || new Date();
    var content = String(initialContent || "");
    if (root.pendingInitialTask) content = ObsidianModel.addTask(content, root.pendingInitialTask);
    var shouldOpen = root.pendingOpen && root.pendingOpenPath === root.pendingCreatePath;
    root.queueWrite(root.pendingCreatePath, content, date, shouldOpen);
  }

  function queueWrite(path, content, date, openAfter) {
    var row = {
      path: String(path || ""),
      content: String(content || ""),
      date: new Date(date),
      dateKey: ObsidianModel.dateKey(date),
      openAfter: !!openAfter
    };
    var queue = root.writeQueue.slice();
    queue.push(row);
    root.writeQueue = queue;
    if (root.currentPath === row.path && root.currentDateKey === row.dateKey) {
      root.currentContent = row.content;
      root.currentTasks = ObsidianModel.parseTasks(row.content);
      root.noteLoaded = true;
      root.fileMissing = false;
      root.bumpService();
    }
    root.startNextWrite();
  }

  function startNextWrite() {
    if (root.writeBusy || root.writeQueue.length === 0) return;
    var queue = root.writeQueue.slice();
    root.activeWrite = queue.shift();
    root.writeQueue = queue;
    root.writeBusy = true;
    mkdirProc.command = ["mkdir", "-p", ObsidianModel.parentPath(root.activeWrite.path)];
    mkdirProc.running = true;
  }

  function startPendingWrite() {
    if (!root.activeWrite || writeProc.running) return;
    writeProc.output = "";
    writeProc.stdinEnabled = true;
    writeProc.command = ["python3", root.writeScript, root.activeWrite.path];
    writeProc.running = true;
  }

  function completeWrite() {
    var completed = root.activeWrite;
    root.writeBusy = false;
    root.activeWrite = null;
    if (completed) {
      if (root.currentPath === completed.path && root.currentDateKey === completed.dateKey) {
        root.noteLoaded = true;
        root.fileMissing = false;
        root.lastError = "";
        errorDismiss.stop();
      }
      if (root.pendingCreatePath === completed.path && root.pendingCreateDateKey === completed.dateKey) {
        root.pendingCreatePath = "";
        root.pendingCreateDateKey = "";
        root.pendingCreateDate = null;
        root.pendingInitialTask = "";
      }
      var queuedSameNote = false;
      for (var i = 0; i < root.writeQueue.length; i++) {
        if (root.writeQueue[i].path === completed.path) { queuedSameNote = true; break; }
      }
      if (!queuedSameNote && root.pendingOpen && root.pendingOpenPath === completed.path) root.finishOpenRequest();
    }
    root.bumpService();
    root.startNextWrite();
  }

  function toggleTask(date, lineIndex) {
    if (!root.obsidianEnabled) return;
    var key = ObsidianModel.dateKey(date);
    if (root.currentDateKey !== key || !root.noteLoaded || root.fileMissing) return;
    var updated = ObsidianModel.toggleTask(root.currentContent, lineIndex);
    if (updated === root.currentContent) return;
    root.queueWrite(root.currentPath, updated, date, false);
  }

  function addTask(date, taskText) {
    if (!root.obsidianEnabled) return;
    var text = String(taskText || "").replace(/[\r\n]+/g, " ").trim();
    if (!text) return;
    var key = ObsidianModel.dateKey(date);
    if (!key) return;
    if (root.currentDateKey !== key || !root.noteLoaded) {
      root.pendingTaskAdd = true;
      root.pendingAddText = text;
      root.pendingAddDateKey = key;
      root.loadForDate(date, false);
      return;
    }
    if (root.fileMissing) {
      root.beginCreate(date, text);
      return;
    }
    var updated = ObsidianModel.addTask(root.currentContent, text);
    if (updated === root.currentContent) return;
    root.queueWrite(root.currentPath, updated, date, false);
  }

  FileView {
    id: noteFile
    watchChanges: true
    atomicWrites: false
    printErrors: false
    onLoaded: root.handleLoadedContent(text(), false)
    onFileChanged: noteFile.reload()
    onLoadFailed: function(error) {
      if (error === FileViewError.FileNotFound) root.handleLoadedContent("", true);
      else {
        root.noteLoaded = true;
        root.currentTasks = [];
        root.setError("Could not read the daily note: " + error);
      }
    }
  }

  FileView {
    id: todayTasksFile
    watchChanges: true
    atomicWrites: false
    printErrors: false
    onLoaded: root.applyTodayTasks(text())
    onFileChanged: todayTasksFile.reload()
    onLoadFailed: function(error) { root.applyTodayTaskLoadFailure(error); }
  }

  Process {
    id: testProc
    onExited: function(exitCode) {
      root.testStatus = exitCode === 0
        ? "Diary folder is readable and writable."
        : "Diary folder does not exist or is not readable and writable.";
      root.bumpService();
    }
  }

  Process {
    id: vaultRootProc
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: vaultRootProc.output = text
    }
    stderr: StdioCollector {}
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.vaultRoot = String(vaultRootProc.output || "").trim();
      } else {
        root.vaultRoot = "";
      }
      root.vaultRootReady = true;
      root.bumpService();
      if (root.pendingOpen && root.pendingOpenPath === root.currentPath) {
        root.finishOpenRequest();
      }
    }
  }

  Process {
    id: writeProc
    property string output: ""
    stdinEnabled: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: writeProc.output = text
    }
    stderr: StdioCollector {}
    onStarted: {
      writeProc.write(root.activeWrite ? root.activeWrite.content : "");
      writeProc.stdinEnabled = false;
    }
    onExited: function(exitCode) {
      var output = writeProc.output;
      writeProc.output = "";
      writeProc.stdinEnabled = false;
      var data = null;
      try { data = JSON.parse(String(output || "")); } catch (error) {}
      if (exitCode === 0 && data && data.ok === true) {
        root.completeWrite();
      } else {
        root.writeBusy = false;
        root.activeWrite = null;
        root.pendingOpen = false;
        root.setError(String(data && data.error || "Could not atomically save the daily note."));
        root.startNextWrite();
      }
    }
  }

  Timer {
    id: errorDismiss
    interval: 5000
    repeat: false
    onTriggered: {
      root.lastError = "";
      root.bumpService();
    }
  }

  Process {
    id: mkdirProc
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.writeBusy = false;
        root.activeWrite = null;
        root.pendingOpen = false;
        root.setError("Could not create the daily note folder (exit " + exitCode + ").");
        root.startNextWrite();
        return;
      }
      root.startPendingWrite();
    }
  }

  Process {
    id: openProc
    onExited: function(exitCode) {
      if (exitCode !== 0) root.setError("Could not open Obsidian. Check that it is installed and handles obsidian:// links.");
    }
  }

  Connections {
    target: root.service
    function onSettingsChanged() { root.handleSettingsChanged(); }
    function onStateLoadedChanged() {
      if (root.obsidianEnabled && root.service && root.service.stateLoaded) {
        root.detectVaultRoot();
        root.loadNote(new Date());
      }
    }
  }

  Component.onCompleted: {
    root.observedObsidianConfig = root.obsidianConfigKey();
    if (root.obsidianEnabled && root.service && root.service.stateLoaded) {
      root.detectVaultRoot();
      root.loadNote(new Date());
    }
  }
}
