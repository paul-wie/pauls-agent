---
name: praesi
description: Bringt Informationen des Nutzers (Freitext/Stichpunkte im Chat) in eine immer gleiche, folienartige HTML-Praesentation im Porsche-KPI-Report-Layout. Trigger "praesi" / "praesi <thema>" / "mach eine praesi".
---

# praesi

Trigger: `praesi <Thema oder Stichpunkte>`. Ergebnis: eine eigenstaendige HTML-Datei (Logo eingebettet), eine Sektion pro Folie, Navigation per Pfeiltasten, druckbar (eine Folie pro Seite). Siehe `README.md`.

## Ablauf
1. Informationen des Nutzers aus dem Chat lesen. Fehlen Titel oder Ziel, kurz nachfragen; nichts erfinden und keine Zahlen ergaenzen.
2. Inhalt in eine JSON-Datei (Schema unten) uebersetzen und als `<name>.json` im Ausgabeordner ablegen (Standard: Session-Ordner `files/` oder vom Nutzer genannter Ordner; nie in dieses Repo committen, ausser der Nutzer will es).
3. Rendern: `node .github\skills\praesi\render.js <name>.json [--out <name>.html]`
4. Pfad der HTML melden und die Folien in 1 Zeile pro Folie zusammenfassen. Warnungen weitergeben.

Das Layout kommt nur aus `template.html` + `render.js`; nie HTML von Hand schreiben oder das Design pro Praesi aendern. Designaenderung nur auf ausdruecklichen Wunsch (dann `template.html` anpassen).

## JSON-Schema
```json
{
  "title": "Titel (Pflicht)",
  "eyebrow": "kleine Ueberschrift ueber dem Titel",
  "lang": "de",
  "slides": [
    { "type": "bullets", "heading": "...", "bullets": ["Punkt", { "text": "Punkt", "sub": ["Unterpunkt"] }] },
    { "type": "text",    "heading": "...", "text": "Fliesstext" },
    { "type": "cards",   "heading": "...", "cards": [{ "label": "", "value": "", "unit": "", "detail": "", "badge": "", "badgeType": "good|warn", "info": "Tooltip" }] },
    { "type": "table",   "heading": "...", "columns": ["A", "B"], "rows": [["a1", "b1"]] }
  ]
}
```
- `**fett**` ist in Texten, Details und Tabellenzellen erlaubt.
- Jede Folie bekommt automatisch oben das Porsche-Logo und eine Fusszeile (ohne Logo): Paul Wiedemann FDC3 | Datum (tt.mm.jjjj) | Folienthema (= `heading`, auf der Titelfolie der `title`). Schrift: Porsche Next TT (Fallback Arial, wenn die Schrift lokal nicht installiert ist; sie wird nicht eingebettet).
- Skalierung: Jede Folie ist eine feste Buehne von 1920x1080 px und wird per JS automatisch an die Fenstergroesse angepasst (Seitenverhaeltnis 16:9, bei anderem Fenster Raender). Inhalt muss in die Buehne passen: max. ca. 6 Bullets bzw. 4 Karten pro Folie, sonst aufteilen.
- Die erste Folie (Titel, optional `eyebrow`) wird automatisch aus `title`/`eyebrow` erzeugt. Keine Chips, kein Footer-Feld.
- `cards`: 1 bis 4 Karten pro Folie (mehr = neue Folie anlegen).
- Eine Folie pro Thema; lange Listen auf mehrere Folien aufteilen (max. ca. 6 Bullets).
- Ein Beispiel liegt in `example.json`.
