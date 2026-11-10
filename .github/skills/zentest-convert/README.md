# zentest-convert

Wandelt eine Cucumber-`.feature`-Datei in einzelne, saubere `.txt`-Testfaelle um, die man in ZenTestAI einfuegen kann ("Testinhalt einfuegen").

## Voraussetzungen
- Node.js (Befehl `node` muss funktionieren).
- Die `.feature`-Datei. Die Translation-Datei `en_GB.properties` liegt bereits im Skill-Ordner (mit `--props` kann eine andere angegeben werden, z. B. eine neuere Version; dann die Datei im Skill-Ordner ersetzen).

## Benutzung

**Mit dem Copilot-CLI-Agent (im Repo `pauls-agent`):**
```
zentest convert "C:\Pfad\zu\02_215EditUser.feature"
```

**Direkt per Kommandozeile:**
```powershell
node .github\skills\zentest-convert\convert.js "C:\Pfad\zu\02_215EditUser.feature"
```
Optionen:

| Option | Bedeutung | Standard |
|---|---|---|
| `--props <datei>` | Translation-Datei | `en_GB.properties` im Skill-Ordner |
| `--out <ordner>` | Zielordner | Unterordner mit dem Namen der Feature-Datei |
| `--base-url <url>` | URL im Login-Step | `https://ppntest.porsche.com/` |

## Ergebnis
Ein neuer Ordner mit **einer `.txt` pro Testfall**, z. B. `02_215EditUser_01_XTA_Global_Edit_user.txt`. Die Originaldateien bleiben unveraendert.

Was passiert:
- Translation-Keys werden durch den englischen Text ersetzt (`navigation.users` -> `Users`), Breadcrumbs werden `a > b`.
- Es bleiben nur Steps: keine Tags, `#`-Kommentare, `Feature`/`Scenario`, Einrueckung oder Leerzeilen.
- `Given "<user>" is on Ppnadmin home page` wird zu `Given Login as "<user>" on "<base-url>"` und `And user clicks on "PPN Admin"`.
- Scenario Outline: Pro Zeile der `Examples`-Tabelle entsteht eine eigene Datei mit eingesetzten Werten.

## In ZenTestAI importieren
Inhalt **einer** `.txt` in das Feld "Testinhalt einfuegen" kopieren und auf "Simulieren" klicken (ein Testfall pro Import). Ein JSON-Upload hat nicht funktioniert.

## Hinweise
- Unbekannte Translation-Keys bleiben im Text stehen und werden als `WARNUNG` ausgegeben, ebenso nicht ersetzte Platzhalter.
- `Background` wird nicht unterstuetzt (Warnung).
