const fs = require("node:fs");
const path = require("node:path");

function loadQmlLibrary(relativePath) {
  const absolutePath = path.resolve(__dirname, "../..", relativePath);
  const source = fs.readFileSync(absolutePath, "utf8").replace(/^\.pragma library\s*/, "");
  const moduleObject = { exports: {} };
  const evaluate = new Function("module", "exports", source);
  evaluate(moduleObject, moduleObject.exports);
  return moduleObject.exports;
}

module.exports = { loadQmlLibrary };
