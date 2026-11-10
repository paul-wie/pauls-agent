# praesi

Macht aus deinen Stichpunkten eine folienartige HTML-Praesentation im immer gleichen Porsche-Layout (Look des KPI-Reports): dunkler Verlauf, rote Akzente, helle Karten, Logo.

## Voraussetzungen
- Node.js (`node` muss funktionieren).
- Fuer die Nutzung per Agent: dieses Repo mit dem Copilot CLI.

## Benutzung

**Mit dem Agent:**
```
praesi Thema XY: Punkt 1, Punkt 2, Zahlen ...
```
Der Agent erzeugt eine JSON-Datei und daraus die HTML.

**Direkt per Kommandozeile:**
```powershell
node .github\skills\praesi\render.js meine-praesi.json --out meine-praesi.html
```
Die JSON hat die Struktur aus `example.json` (Titel, Chips, Folien vom Typ `bullets`, `text`, `cards`, `table`). Details stehen in `SKILL.md`.

## Ergebnis
Eine einzelne `.html` (Logo ist eingebettet, kein Internet noetig).
- Die Praesentation skaliert automatisch auf die Fenstergroesse (16:9-Buehne, Fenster verkleinern/vergroessern oder Vollbild mit F11).
- Navigation: Pfeiltasten, Bild auf/ab, Leertaste oder Scrollen (eine Folie rastet ein).
- Drucken / PDF: Browser-Druck, eine Folie pro Seite.
- Info-Kreis `i` auf Karten zeigt einen Tooltip (z. B. Berechnungsgrundlage).

## Hinweise
- Der Agent erfindet keine Zahlen; er nutzt nur, was du ihm gibst.
- Design aendern: `template.html` (nur auf bewussten Wunsch).
