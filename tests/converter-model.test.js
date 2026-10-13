const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const ConverterModel = loadQmlLibrary("logic/ConverterModel.js");
const NumberFormat = loadQmlLibrary("logic/NumberFormat.js");

test("length conversion supports metric and imperial units", () => {
  assert.ok(Math.abs(ConverterModel.convertUnit(100, "length", "m", "ft") - 328.0839895) < 0.0001);
  assert.equal(ConverterModel.convertUnit(1, "length", "km", "m"), 1000);
});

test("temperature conversion handles Celsius, Fahrenheit, and Kelvin", () => {
  assert.equal(ConverterModel.convertUnit(0, "temperature", "C", "F"), 32);
  assert.equal(ConverterModel.convertUnit(0, "temperature", "C", "K"), 273.15);
  assert.equal(ConverterModel.convertUnit(32, "temperature", "F", "C"), 0);
});

test("fiat conversion uses USD as a pivot", () => {
  const rates = { USD: 1, EUR: 0.92, BRL: 5.2 };
  assert.ok(Math.abs(ConverterModel.convertCross(100, "USD", "EUR", rates, {}) - 92) < 1e-10);
  assert.ok(Math.abs(ConverterModel.convertCross(92, "EUR", "BRL", rates, {}) - 520) < 1e-10);
});

test("crypto prices can be converted through the same USD pivot", () => {
  const prices = { bitcoin: 50000, ethereum: 2500 };
  assert.equal(ConverterModel.convertCross(1, "BTC", "USD", {}, prices), 50000);
  assert.equal(ConverterModel.convertCross(1, "BTC", "ETH", {}, prices), 20);
});

test("amount parsing accepts Brazilian and US grouping conventions", () => {
  assert.equal(NumberFormat.parseAmount("1.234,56"), 1234.56);
  assert.equal(NumberFormat.parseAmount("1,234.56"), 1234.56);
  assert.equal(NumberFormat.parseAmount("  -2 500,5 "), -2500.5);
  assert.equal(Number.isNaN(NumberFormat.parseAmount("not a number")), true);
});

test("formatResult groups large values and trims unnecessary decimals", () => {
  assert.equal(NumberFormat.formatResult(1234.567), "1,234.57");
  assert.equal(NumberFormat.formatResult(1.5), "1.5");
  assert.equal(NumberFormat.formatResult(NaN), "—");
});

test("all supported unit categories have at least two units", () => {
  for (const category of Object.values(ConverterModel.UNIT_CATEGORIES)) {
    assert.ok(category.units.length >= 2);
  }
  assert.equal(ConverterModel.CRYPTO_LIST.length, 15);
});
