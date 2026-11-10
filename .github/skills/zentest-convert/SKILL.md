---
name: zentest-convert
description: Wandelt eine Cucumber-.feature-Datei (mit Translation-Keys) in bereinigte Einzel-Testfaelle als .txt fuer den ZenTestAI-Import um. Aufruf "zentest convert <datei>". Nutzen bei "zentest convert", "zentestai", "feature konvertieren", "testfaelle fuer zentest bereinigen" oder wenn der Nutzer eine .feature-Datei gibt.
---

# zentest-convert

Trigger: `zentest convert "<pfad>\xyz.feature"` (optional: `props <pfad>` fuer die en_GB.properties, `out <ordner>`, `base-url <url>`). Bei fehlendem Pfad nachfragen.
Siehe `README.md` fuer die Nutzeranleitung.

Eingabe: eine `.feature`-Datei (+ `en_GB.properties` mit den Translations).
Ausgabe: neuer Ordner `<feature-name>\` mit **einer .txt pro Szenario**, nur Steps.

## Aufruf

```powershell
node .github\skills\zentest-convert\convert.js "<pfad>\02_215EditUser.feature" [--props "<pfad>\en_GB.properties"] [--out "<ordner>"] [--base-url "https://ppntest.porsche.com/"]
```
Defaults: `--props` = `en_GB.properties` im Skill-Ordner (mitgeliefert); `--out` = Unterordner mit dem Namen der Feature-Datei; `--base-url` = `https://ppntest.porsche.com/`.
Die Zahlen/Texte kommen nur aus dem Script, nie von Hand aendern. Die Originaldateien werden nie veraendert.

## Regeln (vom Nutzer festgelegt)
1. Translation-Keys in Anfuehrungszeichen werden durch den englischen Text aus `en_GB.properties` ersetzt; Breadcrumbs `a-->b` werden `a > b`. Unbekannte Keys bleiben stehen und werden als WARNUNG gemeldet.
2. Ein Szenario = eine Datei `<feature>_<NN>_<Szenario_Titel>.txt`.
3. Nur Steps (`Given/When/Then/And/But`, Datentabellen-Zeilen `|`): keine Einrueckung, keine Leerzeilen, keine `#`-Kommentare, keine Tags, kein `Feature:`/`Scenario:`.
4. `Given "<user>" is on Ppnadmin home page` funktioniert in ZenTestAI nicht und wird ersetzt durch:
   ```
   Given Login as "<user>" on "https://ppntest.porsche.com/"
   And user clicks on "PPN Admin"
   ```
   (danach folgt z. B. `When user navigates to "Users" tab`).
5. **Scenario Outline:** Die Werte der `Examples`-Tabelle werden in die Platzhalter (`<user>` usw.) eingesetzt, pro Tabellenzeile entsteht eine eigene Datei (`..._Example_1.txt`, `..._Example_2.txt`, ...). In den Dateien steht nie eine Tabelle oder `Examples`. Bleibt ein Platzhalter uebrig, warnt das Script. `Background` wird nicht unterstuetzt (Warnung).

## Ablauf
1. Pfad der .feature-Datei (und ggf. properties) vom Nutzer holen; der Ordner liegt ausserhalb des Repos, das ist ok.
2. Script ausfuehren, Ausgabe lesen (Anzahl Steps, WARNUNGEN).
3. Stichprobe einer Datei zeigen und Warnungen melden.
4. Import: In ZenTestAI das Textfeld "Testinhalt einfuegen" nutzen und den Inhalt **einer** Datei einfuegen (ein Fall pro Import). JSON-Upload hat nicht funktioniert.

## Offen
- Wording der Steps `Login as ... on ...` und `user clicks on "PPN Admin"` ist vom Nutzer so gewaehlt/bestaetigt worden; bei Aenderungswunsch nur `loginRe`-Ersetzung in `convert.js` anpassen.
