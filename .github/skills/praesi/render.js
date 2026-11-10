#!/usr/bin/env node
// Renders a presentation JSON into one standalone slide-style HTML file (Porsche KPI-report look).
// Usage: node render.js <input.json> [--out <file.html>]
const fs = require("fs");
const path = require("path");

const args = process.argv.slice(2);
const input = args.find((a, i) => !a.startsWith("--") && !(i > 0 && args[i - 1] === "--out"));
if (!input) {
  console.error("Usage: node render.js <input.json> [--out <file.html>]");
  process.exit(1);
}
const outIdx = args.indexOf("--out");
const outFile = outIdx >= 0 ? args[outIdx + 1] : input.replace(/\.json$/i, "") + ".html";

const spec = JSON.parse(fs.readFileSync(input, "utf8").replace(/^\uFEFF/, ""));
const esc = (s) => String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const rich = (s) => esc(s).replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>");

const warnings = [];
const heading = (s) => (s.heading ? `<h2>${esc(s.heading)}</h2>` : "");
const logo = "data:image/png;base64," + fs.readFileSync(path.join(__dirname, "assets", "logo.png")).toString("base64");

const renderers = {
  bullets: (s) => {
    const li = (b) => {
      if (typeof b === "string") return `<li>${rich(b)}</li>`;
      const sub = (b.sub || []).length ? `<ul>${b.sub.map((x) => `<li>${rich(x)}</li>`).join("")}</ul>` : "";
      return `<li>${rich(b.text)}${sub}</li>`;
    };
    return `${heading(s)}<ul class="points">${(s.bullets || []).map(li).join("")}</ul>`;
  },
  text: (s) => `${heading(s)}<p class="text">${rich(s.text)}</p>`,
  cards: (s) => {
    const cards = s.cards || [];
    const span = Math.max(3, Math.floor(12 / Math.min(Math.max(cards.length, 1), 4)));
    const html = cards.map((c) => {
      const info = c.info ? `<i class="info" tabindex="0">i<span class="tip">${esc(c.info)}</span></i>` : "";
      const badge = c.badge ? `<span class="badge ${c.badgeType === "warn" ? "warn" : "good"}">${esc(c.badge)}</span>` : "";
      const unit = c.unit ? `<small>${esc(c.unit)}</small>` : "";
      return `<div class="card hero" style="grid-column: span ${span}"><div class="label"><span>${esc(c.label)}</span>${info}</div>` +
        `<div class="value">${esc(c.value)}${unit}</div>` +
        (c.detail ? `<div class="detail">${rich(c.detail)}</div>` : "") + badge + `</div>`;
    }).join("");
    return `${heading(s)}<div class="grid">${html}</div>`;
  },
  table: (s) => {
    const cols = s.columns || [];
    const head = `<tr>${cols.map((c) => `<th>${esc(c)}</th>`).join("")}</tr>`;
    const body = (s.rows || []).map((r) => `<tr>${cols.map((_, i) => `<td>${rich(r[i])}</td>`).join("")}</tr>`).join("");
    return `${heading(s)}<table>${head}${body}</table>`;
  },
};

const AUTHOR = "Paul Wiedemann FDC3";
const dateDe = new Date().toLocaleDateString("de-DE", { day: "2-digit", month: "2-digit", year: "numeric" });
const frame = (inner, topic, cls = "slide") =>
  `<div class="stage"><div class="frame"><section class="${cls}"><div class="slide-top"><img class="logo" src="${logo}" alt="PORSCHE"></div>${inner}` +
  `<div class="slide-foot"><span>${AUTHOR}</span><span class="sep">|</span><span>${dateDe}</span>` +
  `<span class="topic">${esc(topic)}</span></div></section></div></div>`;

const titleSlide = () =>
  frame((spec.eyebrow ? `<div class="eyebrow">${esc(spec.eyebrow)}</div>` : "") + `<h1>${esc(spec.title)}</h1>`, spec.title, "slide title-slide");

const slides = [titleSlide()];
(spec.slides || []).forEach((s, i) => {
  const r = renderers[s.type];
  if (!r) { warnings.push(`Slide ${i + 1}: unknown type "${s.type}" skipped`); return; }
  slides.push(frame(r(s), s.heading || spec.title));
});

const tpl = fs.readFileSync(path.join(__dirname, "template.html"), "utf8");
const html = tpl.replace("{{LANG}}", esc(spec.lang || "de")).replace("{{TITLE}}", esc(spec.title)).replace("{{SLIDES}}", () => slides.join("\n"));
if (/\{\{[A-Z]+\}\}/.test(html)) throw new Error("Unreplaced placeholder in output");
fs.writeFileSync(outFile, html, "utf8");
console.log(`Output: ${outFile} (${slides.length} slides)`);
warnings.forEach((w) => console.log("WARNUNG:", w));
