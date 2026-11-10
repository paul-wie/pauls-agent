#!/usr/bin/env node
// Converts a Cucumber .feature file into one clean .txt file per scenario for ZenTestAI.
// Usage: node convert.js <feature-file> [--props <en_GB.properties>] [--out <dir>] [--base-url <url>]
const fs = require("fs");
const path = require("path");

const args = process.argv.slice(2);
const opt = (name, def) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : def;
};
const featureFile = args.find((a, i) => !a.startsWith("--") && !(i > 0 && args[i - 1].startsWith("--")));
if (!featureFile) {
  console.error("Usage: node convert.js <feature-file> [--props <file>] [--out <dir>] [--base-url <url>]");
  process.exit(1);
}
const featureDir = path.dirname(path.resolve(featureFile));
const featureName = path.basename(featureFile).replace(/\.feature$/i, "");
const propsFile = opt("--props", path.join(__dirname, "en_GB.properties"));
const outDir = opt("--out", path.join(featureDir, featureName));
const baseUrl = opt("--base-url", "https://ppntest.porsche.com/");

const props = {};
for (const line of fs.readFileSync(propsFile, "utf8").split(/\r?\n/)) {
  if (!line.trim() || /^[#!]/.test(line) || !line.includes("=")) continue;
  const i = line.indexOf("=");
  props[line.slice(0, i).trim()] = line.slice(i + 1).trim();
}

const keyRe = /^[A-Za-z]\w*(\.[\w-]+)+$/;
const missing = new Set();
const resolveToken = (t) => {
  if (t in props) return props[t];
  if (keyRe.test(t) && !/^(www\.|https?:)/i.test(t)) missing.add(t);
  return t;
};
const resolveString = (s) => {
  if (s.includes("-->")) return s.split("-->").map((p) => resolveToken(p.trim())).join(" > ");
  if (s in props) return props[s];
  return s.split(" ").map(resolveToken).join(" ");
};
const resolveLine = (l) => l.replace(/"([^"]*)"/g, (_, m) => '"' + resolveString(m) + '"');

const lines = fs.readFileSync(featureFile, "utf8").split(/\r?\n/).map((l) => l.trim());
const warnings = [];
const scenarios = [];
let current = null;
let inExamples = false;
let header = null;
const cells = (l) => l.replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
for (const l of lines) {
  if (/^Scenario( Outline| Template)?:/.test(l)) {
    current = { title: l.replace(/^Scenario( Outline| Template)?:\s*/, ""), steps: [], outline: /Outline|Template/.test(l), rows: [] };
    scenarios.push(current);
    inExamples = false;
  } else if (/^Background:/.test(l)) {
    warnings.push(`Background ignored: ${l}`);
    current = null;
  } else if (/^Examples?:/.test(l)) {
    inExamples = true;
    header = null;
  } else if (current && inExamples && l.startsWith("|")) {
    if (!header) header = cells(l);
    else current.rows.push(Object.fromEntries(header.map((h, i) => [h, cells(l)[i] ?? ""])));
  } else if (current && !inExamples && (/^(Given|When|Then|And|But)\s/.test(l) || l.startsWith("|"))) {
    current.steps.push(l);
  }
}

const loginRe = /^(Given|When|Then|And)\s+"([^"]+)"\s+is on Ppnadmin home page$/;
fs.mkdirSync(outDir, { recursive: true });
let counter = 0;
const substitute = (s, row) => s.replace(/<([^<>]+)>/g, (m, k) => (k in row ? row[k] : m));
const render = (sc, row, suffix) => {
  const out = [];
  for (const step of sc.steps) {
    const raw = row ? substitute(step, row) : step;
    const m = raw.match(loginRe);
    if (m) {
      out.push(`Given Login as "${m[2]}" on "${baseUrl}"`);
      out.push('And user clicks on "PPN Admin"');
    } else {
      out.push(resolveLine(raw));
    }
  }
  const left = out.filter((l) => /<[^<>\s]+>/.test(l));
  if (left.length) warnings.push(`Unreplaced placeholder in "${sc.title}${suffix}": ${left[0]}`);
  const slug = (sc.title + suffix).replace(/[^A-Za-z0-9]+/g, "_").replace(/^_|_$/g, "");
  const name = `${featureName}_${String(++counter).padStart(2, "0")}_${slug}.txt`;
  fs.writeFileSync(path.join(outDir, name), out.join("\n") + "\n", "utf8");
  console.log(`${name} (${out.length} steps)`);
};
for (const sc of scenarios) {
  if (sc.outline && sc.rows.length) sc.rows.forEach((row, i) => render(sc, row, ` Example ${i + 1}`));
  else {
    if (sc.outline) warnings.push(`Scenario Outline without Examples rows: ${sc.title}`);
    render(sc, null, "");
  }
}
console.log(`Output: ${outDir}`);
if (missing.size) console.log("WARNUNG unaufgeloeste Keys:", [...missing].sort().join(", "));
warnings.forEach((w) => console.log("WARNUNG:", w));
