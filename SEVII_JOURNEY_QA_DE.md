# Sevii: zusammenhängende Reiseprüfung

## Neuere Paketkopie dev17 (01.10.2026)

Aus der materialisierten dev17-Kopie schlossen Rot, Grün und Blau alle
sieben Kapitel mit normalen Zufallsbegegnungen und unveränderten
Kampfabläufen ab. Jede Reise erreichte nach sieben Center-Besuchen die
Rückfahrt nach Orania: 2.728 Routenbewegungen, 154 Kartenränder, 65 Türen
und sieben Fähren pro Figur. Die Wildkämpfe verteilen sich auf 22, 34 und
22, insgesamt 78. `package-dev17-qa/natural/journeys-all-characters.json`
enthält die einzelnen Ressourcenläufe. Die Voraussetzungen und Grenzen
entsprechen dem dev11-Lauf unten. Ein weiterer vollständiger Rot-Lauf aus
dev19 ohne normale Zufallsbegegnungen bestand nach der Zink-Ergänzung;
dev20 änderte anschließend nur Eichs Legacy-Teamkopie.

## Frühere Paketkopie dev11 (30.09.2026)

Aus der materialisierten `package-dev11`-Kopie haben Rot, Grün und Blau
jeweils alle sieben Kapitel mit normalen Zufallsbegegnungen, nativen
Kämpfen und tatsächlichen Center-Besuchen abgeschlossen. Alle drei
Reisen kehrten nach Orania zurück und endeten mit Exitcode 0. Pro Figur
wurden 2.728 erfolgreiche Routenbewegungen, 154 Kartenübergänge,
65 Türen, sieben Fähren und sieben Center-Besuche protokolliert.
Die 25, 32 und 27 Wildkämpfe ergeben zusammen 84. Speichern und Laden
erfolgt an den Kapitel-Checkpoints; der Verbrauch an KP und AP bleibt
zwischen Kämpfen und Center-Besuchen bestehen. Der Nachweis steht in
`package-dev11-qa/natural/journeys-all-characters.json`.

Liga, Startteam, Feldorden und Ausgangsort bleiben Test-Fixtures.
Sichtbare Wildpokémon und freiwillige Trainer sind in diesen drei
Reisen deaktiviert beziehungsweise nicht Teil der Route. Ein neuer
blauer Basisspielstand wurde mit derselben materialisierten Kopie separat
vollständig durchgespielt; siehe `SEVII_UPGRADE_QA_DE.md`.

## Aktuelle Paketkopie dev10 (30.09.2026)

Nach der Sperre des alten Jirachi-Kapitänszugangs absolvierte Rot aus der
materialisierten dev10-Kopie erneut alle sieben Kapitel und kehrte nach
Orania zurück (`package-dev10-qa/journeys/journey-red.json`, Exitcode 0,
2.642 Routenbewegungen). Die übrige Inselgeschichte änderte sich nicht;
die dev9-Läufe mit Grün und Blau stehen im folgenden Abschnitt. Der
Jirachi-Türtest der dev10-Kopie ist separat dokumentiert.

## Aktuelle Paketkopie dev9 (30.09.2026)

Mit der materialisierten `package-dev9`-Modkopie und aktivem Voxel Ascendant
3.0.0-rc.2 haben Rot, Grün und Blau jeweils alle sieben Kapitel durch
native Dialoge, Wege, Rätsel, Fähren sowie Speichern und Laden absolviert.
`package-dev9-qa/journeys/journeys-all-characters.json` meldet für jeden
Charakter `complete=true`, Rückkehr nach Orania, 2.642 erfolgreiche
Routenbewegungen, 150 Kartenübergänge, 51 Türen und sieben Inselfähren.
Alle drei Prozesse endeten mit Exitcode 0. Liga-Status und Startteam sind
Test-Fixtures; Zufalls- und sichtbare Begegnungen sind für diesen
Geschichtsdurchlauf deaktiviert. Die älteren Ressourcen- und Fangläufe
decken gesonderte Aspekte ab, ersetzen aber keinen aktuellen
Balance-Gesamtdurchlauf.

## Erster vollständiger Durchlauf

Ein isolierter Spielstand hat alle sieben Kapitel über tatsächliche Wege,
Türen und Fähren abgeschlossen und ist nach Orania zurückgekehrt.
Questfortschritt stammt ausschließlich aus Gesprächen, Menüs, Schritten und
Stärke-Schüben. Nach jedem Kapitel wird gespeichert und erneut geladen.

Der erste Durchlauf verwendete die normale rote Spielfigur ohne eingeschaltete
erweiterte Charakterauswahl. Während der Entwicklung des Routenhelfers wurde
dieser Spielstand an verifizierten Kapitel-Speicherständen fortgesetzt:

| Kapitel | Nativer Beleg |
| --- | --- |
| 1–2: Bojen, Mara, Archiv und Spiegel | `journey-native2.log` |
| 3: tatsächliche Waldrettung und Heimkehr | `journey-native5.log` |
| 4: Einbruch, Aktenkapsel, Eisring und Bericht | `journey-native6.log` |
| 5: Stromverteilung, drei Begleiter und Funk | `journey-native7.log` |
| 6: vier Ruinenebenen, Erscheinung und Rückweg | `journey-native8.log` |
| 7: Canyon, Stärke-Rätsel, drei Anker, Siegel, Epilog, Rückfahrt | `journey-native9.log` |

`journey-progress.json` meldet Kapitel 7 und `complete=true`, 2.652 erfolgreiche
Bewegungen des Routenhelfers, 150 Kartenübergänge, 51 Türen und sieben
Inselfährfahrten. Manuell ausgeführte Rätselschritte und abgebrochene
Testversuche sind nicht in diesen Bewegungszahlen enthalten. Alle 218
gewöhnlichen Fangziele waren vor der Rückfahrt nach dem Finale verfügbar.

## Charakterdurchgänge

`scripts/run_sevii_journeys.py` startet getrennte, frische QA-Identitäten für
RED, GREEN und BLUE. Jede benutzt die echte Charakterauswahl und führt die
Geschichte vom Orania-Anleger bis zur Rückkehr in einem Prozess aus.
Die Ergebnisse stehen in `journey-red.json`, `journey-green.json`,
`journey-blue.json` und bei vollständigem Erfolg in
`journeys-all-characters.json`. Alle drei frischen Durchgänge sind bestanden (Prozess-Exitcode 0).
Jeder erreichte Kapitel 7, den gespeicherten Epilog und Orania mit weiterhin
aktivem, korrekt gewähltem Charakter. Pro Durchgang: 2.632 erfolgreiche
Routenbewegungen, 150 Kartenübergänge, 51 Türen und sieben Inselfährfahrten.
Die Ausgangsfähre und manuelle Rätselschritte sind separat ausgeführt.
QA-Identitäten: `kasc-sevii-qa-20260928-full-journey4-{red,green,blue}`.

## Reichweite und Test-Fixtures

- Nur die Ausgangslage wird vorbereitet: Post-Liga-Flag, erforderliche
  Feldorden, ein Level-70-Turtok mit Surfer/Stärke und Start am Orania-Anleger.
  Der Anleger wird zuvor mit fehlendem Liga-Flag geprüft. Die bestehende
  KASC-Freigabe „Jenseits von Kanto“ wird als Teil der erweiterten
  Post-Liga-Ausgangslage aktiviert; sie wird durch die Inselreise nicht
  stillschweigend für normale Spieler verändert.
- Nach der ersten Überfahrt verwendet der Test keine Teleport- oder
  Warp-API. Türen und Fähren werden durch ihre normalen Spielaktionen benutzt.
- Zufalls- und sichtbare Wildbegegnungen sind für diesen Reisefunktionstest
  abgeschaltet. Er ersetzt keine Prüfung der Schwierigkeit oder des
  vollständigen Wegs durch Kanto bis zum Ligasieg.
- Fänge, Kampfbilder und alle 84 Schritt-Begegnungstabellen besitzen eigene
  native Tests; dieser Durchlauf wiederholt nicht sämtliche 218 Fänge.
- Die Navigation berücksichtigt Kartenverbindungen, Sprungkanten,
  Surferzugänge, gerissenes Eis, unsichtbare Figuren und tatsächlich
  verschobene Felsen. Sie verändert dabei keine Spielkollision oder Questflags.
- Der Rückweg im Punktloch verläuft durch die Ankerkammer und die vier
  Ebenen nach oben. Der östliche Seitenkorridor ist keine Abkürzung zur Forscherin.

Nach der Begegnungskorrektur wurden alle drei frischen Reisen mit aktivem
„Jenseits von Kanto“ wiederholt und erneut bestanden. Die Entscheidung für
einen reinen Kanto-Spielstand bleibt wirksam: Dann gibt es auf Sevii keine
gewöhnlichen Gen-3-/Gen-4-Begegnungen; das Fangortbuch erklärt den Grund.


## Wiederholung gegen das eigenständige Entwicklungspaket

Alle drei Durchgänge wurden mit `package-dev1` erneut bestanden
(`package-dev1-qa/journeys.log`, Prozess-Exitcode 0). Die isolierten Identitäten
lauten `kasc-sevii-qa-package-dev1-{red,green,blue}`. Code, Karten und Grafiken
stammen diesmal aus der materialisierten Paketkopie, nicht aus dem laufend
veränderlichen QA-Mod-Overlay. Der Host und die externen Testtreiber bleiben
identisch. Jede Reise erreicht wieder Kapitel 7 und Orania mit 2.632
Routenbewegungen, 150 Übergängen, 51 Türen und sieben Inselfährfahrten.
Alle oben genannten Grenzen der Reiseprüfung bleiben bestehen.

## Zusätzliche Reisen mit normalen Zufallsbegegnungen

Der aktuelle Quellstand ist jetzt auch mit normalen Wildbegegnungen für
Rot, Grün und Blau vollständig durchgespielt. Je Reise: sieben Kapitel,
Rückkehr nach Orania, 2.718 Routenbewegungen, 154 Kartenränder, 65 Türen
und sieben tatsächliche Center-Besuche. KP, AP, Status und Erfahrung
bleiben zwischen Kämpfen und Reisen erhalten; der Prüftreiber füllt keine
Vorräte auf. Insgesamt entstehen 96 Wildkämpfe und keine vollständige
Niederlage. Anfangsteam, Post-Liga-Freigabe und Orania bleiben Fixtures;
sichtbare Pokémon sind weiterhin ausgeschaltet. Strategie, Zufallsfolgen,
Verbrauch und Belege stehen in `SEVII_PLAYABILITY_QA_DE.md` und
`journeys-natural-all-characters.json` im QA-Verzeichnis.

Das materialisierte Paket `dev2` besteht außerdem die aktuelle vollständige
Upgrade-Reise mit einem neu erzeugten blauen Basisspielstand; siehe
`SEVII_UPGRADE_QA_DE.md`.
