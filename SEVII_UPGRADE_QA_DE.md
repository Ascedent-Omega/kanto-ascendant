# Upgrade eines gespeicherten KASC-Basisspielstands auf Sevii

## Hinweis zum Entwicklungsstand dev22 (01.10.2026)

Bei einem übernommenen Spielstand wird das Level eines neuen stationären
Sevii-Legendenkampfs erst beim Kampfstart aus der aktuellen, gültigen Party
bestimmt: der höhere Wert aus gerundetem Durchschnitt und höchstem Level
minus acht, danach für Legendäre plus zwei, mindestens das verfasste Level
und höchstens 100. Boxen und früher erreichte Höchstlevel zählen dafür
nicht. Regirock, Regice und Registeel haben jeweils Level 65 als Minimum.

Davon getrennt werden alte Fangbelege und Besitzquellen eingelesen:
Pokédex, Team, Boxen, ursprüngliche Heiligtums-/Ereignisbelege sowie
Legacy- und Bankhistorie. Ein bereits gefangenes Regi wird im aktuellen
Durchlauf nicht erneut angeboten; nach NG+ kann es mit neuen Questbelegen
erneut erscheinen. Bei nicht lesbarer maßgeblicher Historie bleibt ein Fang
gesperrt. Ein alter Spielstand ohne Sevii-Fortschritt muss Insel-Finale
und Tanoby-Waage regulär spielen; die alten Heiligtümer sind geschlossen.

Die unten dokumentierte vollständige Upgrade-Reise wurde mit dev11
ausgeführt, nicht mit dev21. Die Herkunft einzelner alter Regi-Fänge wurde
in 174 Besitzhistorien- und 51 Regi-Unit-Prüfungen abgedeckt; ein separater
nativer Upgrade-Lauf mit einem bereits gefangenen Regi steht vor einer
Freigabe noch aus. Das Paket meldet weiterhin `releaseReady=false`.

## Aktuelle Paketkopie dev11 (30.09.2026)

Ein neuer isolierter blauer Spielstand wurde mit dem unveränderten
KASC-Basiscommit `b30cfad48` erzeugt. Danach lud die materialisierte
dev11-Paketkopie mit Voxel Ascendant 3.0.0-rc.2 diesen Spielstand und
spielte alle sieben Kapitel bis zur Rückkehr nach Orania. Das Ergebnis
`upgrade-dev11/journey-upgrade-blue11.json` bestätigt `complete=true`,
`upgradedFromBase=true`, `oldSavePreserved=true`, 2.642 erfolgreiche
Routenbewegungen, 150 Kartenübergänge, 51 Türen und sieben Fähren.
Team, Box einschließlich Lavados, alter Fangbeleg, Geld und ursprünglich
vorhandene Items wurden beim Laden und nach jedem Kapitel geprüft.
Basis- und Upgrade-Prozess endeten jeweils mit Exitcode 0.

Liga, Team und ursprüngliche Items sind im echten Basisklienten
vorbereitete QA-Daten; Zufalls- und sichtbare Begegnungen sind in
diesem Upgrade-Lauf deaktiviert. Die drei aktuellen Frischreisen mit
normalen Wildkämpfen stehen in `SEVII_JOURNEY_QA_DE.md`.

## Aktueller Legenden- und Voxel-Stand dev9 (30.09.2026)

Ein neuer isolierter Basisclient aus demselben unveränderten KASC-Commit
erzeugte den Spielstand `sevii-dev9-upgrade-blue-20260930`. Danach lud der
aktuelle Sevii-Quellstand mit aktivem Voxel Ascendant 3.0.0-rc.2 genau diesen
Spielstand. Der native Durchlauf bestand alle sieben Kapitel bis zur
Rückkehr nach Orania. Das Ergebnis
`.qa/sevii-expedition-20260928/upgrade-dev9/journey-upgrade-blue9.json`
meldet `complete=true`, `upgradedFromBase=true`, `oldSavePreserved=true`,
Charakter BLUE, 2.642 erfolgreiche Routenbewegungen, 150 Kartenübergänge,
51 Türen und sieben Fährfahrten. Der Prüftreiber verglich Team, Box,
alten Lavados-Beleg, Geld und ursprünglich vorhandene Items beim Laden
und nach jedem Kapitel. Der neue Client zeigte beim ersten Laden seinen
Mod-Änderungsbericht; dieser wurde im Prüftreiber bestätigt. Die
Voxel-Aktivierung erfolgte nur für die isolierte Testidentität.

Dieser Durchlauf verwendet den aktuellen QA-Quellstand mit denselben
Laufzeitmodulen wie `package-dev9.zip`, nicht eine materialisierte Kopie
des ZIP. Die unten beschriebenen vorbereiteten Liga-/Teamdaten und
deaktivierten Wildbegegnungen gelten auch hier. Ein Gesamtspieltest des
fertigen Pakets bleibt offen.

Der vollständige Durchlauf ist bestanden. Ein separat gestarteter Client
mit dem unveränderten KASC-Commit
`b30cfad48b3884abb3770e2696b6e2a716f2cf35` erzeugte und speicherte zuerst
den Testspielstand. Danach lud ein neuer Prozess mit der Sevii-Erweiterung
genau denselben isolierten Speicherbereich. Der Test erzeugt bei diesem
zweiten Start kein neues Spiel und setzt keinen Insel-Fortschritt vor.

## Belege

- Basislauf: `upgrade-base-blue2.log`, Exitcode 0,
  `SEVII_OLD_BASE_SAVE_CREATED BLUE 1 1`.
- Hashes unveränderter Basisdateien und Commit: `upgrade-base-runtime.json`.
- Daten vor dem Upgrade: `upgrade-before.json`.
- Vollständige Inselreise: `upgrade-journey-blue2.log`, Exitcode 0.
- Ergebnis: `journey-upgrade-blue.json`, `complete=true`, Kapitel 7,
  `upgradedFromBase=true`, `oldSavePreserved=true`, Charakter BLUE aktiv.
- Tatsächlicher Weg: **2.632 Routenbewegungen, 150 Kartenübergänge,
  51 Türen, sieben Insel-Fährfahrten**, anschließend wieder Orania.

Die Dateien liegen im isolierten Verzeichnis
`.qa/sevii-expedition-20260928`. Verwendete Testidentität:
`kasc-sevii-qa-20260928-upgrade-blue2`. Der Basisklient liegt dort unter
`engine-baseline2`; seine Lua-Dateien wurden mit `git archive` direkt aus
dem genannten Commit gewonnen. Fehlende optionale Grafikdateien stammen
aus dem vorhandenen QA-Overlay. Im Basislauf existiert kein
`seviiExpedition`-Export.

## Erhaltene Daten

Der Basisspielstand enthält ein Turtok mit eigenem Namen, DVs, OT-Daten
und drei Feld-/Kampfattacken, ein Lavados in der ersten Box, dessen
Fangbeleg im vorhandenen Endgame-System, Geld, Orden sowie Milch und
Netzbälle aus dem alten Itemkatalog. Beim ersten Laden werden das Team
und alle vorhandenen Boxfelder exakt verglichen. Nach jedem geprüften
Kapitel und erneuten Laden prüft der Lauf:

- unveränderte Boxbelegung und alle ursprünglichen Pokémon-Felder;
- unveränderten alten Lavados-Ereignisbeleg;
- ursprüngliche Team-Identitäten einschließlich Namen, DVs und OT;
- unverändertes Geld und keinen Verlust ursprünglich vorhandener Items.

Die alten Ausrüstungs-/Fähigkeitsdienste ergänzen beim ersten Übergang
von AUTO auf Gen 3 ihre eigenen Felder `_kascEquipmentHandle` und
`_kascAbility67`. Genau diese neuen Felder sind zugelassen und werden auf
Format beziehungsweise gültige Fähigkeitsbindung geprüft. Sie ersetzen
keine vorhandenen Felder. Andere unerwartete Ergänzungen schlagen fehl.
Der erste Versuch stoppte an dieser zunächst zu strengen Vergleichsregel;
der Datenvergleich zeigte ausschließlich diese zwei vorgesehenen
Ergänzungen. Der zweite vollständige Lauf verwendet eine frisch mit der
Basis erstellte Testidentität.

## Grenzen des Nachweises

Liga-Sieg, freigeschaltetes „Jenseits von Kanto“, Team, Items und alter
Fangbeleg sind vorbereitete QA-Daten im echten Basisklienten, kein
gespielter Liga-Durchlauf. Die Inselgeschichte selbst entsteht vollständig
durch native Dialoge, Reisen und Rätsel. Zufällige und sichtbare Begegnungen
sind ausgeschaltet; die gesonderten Fangtests decken diese Systeme ab.
Dies belegt das Upgrade des angegebenen Basisstands mit Charakter Blau,
nicht beliebige historische, beschädigte oder fremde Spielstände. Die
drei frischen Reisen mit Rot, Grün und Blau bleiben separat dokumentiert.

Keine installierte Spielerkopie, kein Spieler-Speicherstand und kein
Spielerarchiv wurde verwendet oder verändert.

## Wiederholung mit dem aktuellen entpackten Paket dev2

Die isolierte Identität `kasc-sevii-qa-20260928-upgrade-blue3` wurde neu mit
derselben unveränderten Basis erzeugt. Die dokumentierten Basiscode-Hashes
wurden vor dem Start nochmals verglichen. Anschließend lud
`package-dev2-engine` ausschließlich den materialisierten Mod aus
`package-dev2-unpacked` und spielte wieder alle sieben Kapitel bis Orania.

`upgrade-current/base-blue3.log` und `upgrade-current/journey-blue3.log`
beenden sich beide mit Exitcode 0. `upgrade-current/journey-upgrade-blue3.json`
bestätigt `complete`, `upgradedFromBase`, `oldSavePreserved`, Charakter BLUE,
2.632 Routenbewegungen, 150 Kartenränder, 51 Türen und sieben Inselfähren.
Alle oben beschriebenen Bestandsvergleiche bestehen unverändert. Das neue
Paket enthält zusätzlich die Hoenn-Besitzhistorien, Feldflöten, Gluttherme
und gemeinsame Pension. Die Fixture- und Begegnungsgrenzen des früheren
Upgrade-Laufs gelten weiterhin. Normale Wildbegegnungen wurden getrennt
für alle drei Charaktere durchgehend gespielt; siehe
`SEVII_PLAYABILITY_QA_DE.md`.

## Wiederholung mit Paket dev4

Die unveränderte Basis erzeugte für `kasc-sevii-dev4-upgrade-blue` erneut
einen frischen isolierten Spielstand. `package-dev4-qa/upgrade-blue/base.log`
endet mit `SEVII_OLD_BASE_SAVE_CREATED BLUE 1 1` und Exitcode 0.
Danach lud die entpackte dev4-Kopie denselben Spielstand und spielte alle
sieben Kapitel mit echten Schritten, Dialogen, Rätseln und Rückfahrt nach
Orania (`package-dev4-qa/upgrade-blue/journey.log`, Exitcode 0).
`journey-upgrade-blue4.json` bestätigt `complete`, `upgradedFromBase` und
`oldSavePreserved` bei 2.632 Routenbewegungen, 150 Kartenrändern, 51 Türen
und sieben Inselfähren. Team, Box, Lavados-Beleg, Geld und vorhandene Items
blieben beim Laden und nach jedem Kapitel erhalten. Die in diesem Dokument
genannten Fixture- und Reichweitengrenzen gelten unverändert.

## Wiederholung mit Paket dev5

Die unveränderte Basis erzeugte für `kasc-sevii-dev5-upgrade-blue` erneut
einen frischen isolierten blauen Spielstand. `package-dev5-qa/upgrade-blue/base.log`
endet mit `SEVII_OLD_BASE_SAVE_CREATED BLUE 1 1` und Exitcode 0. Die
entpackte dev5-Kopie lud denselben Spielstand und spielte alle sieben Kapitel
bis zur Rückfahrt nach Orania (`package-dev5-qa/upgrade-blue/journey.log`,
Exitcode 0). `journey-upgrade-blue5.json` bestätigt `complete=true`,
`upgradedFromBase=true` und `oldSavePreserved=true` bei 2.632 Bewegungen,
150 Kartenrändern, 51 Türen und sieben Fähren. Team, PC, Geld, Inventar und
Lavados-Beleg blieben beim Laden und nach jedem Kapitel erhalten. Die
vorbereiteten Post-Liga-Daten und abgeschalteten Zufallsbegegnungen gelten
weiter; dieser Lauf belegt genau den geprüften alten Basisstand.

## Wiederholung mit Paket dev6

Die unveränderte Basis erzeugte für `sevii-package-dev6-upgrade-blue-20260930`
einen neuen isolierten blauen Spielstand (`package-dev6-qa/upgrade-blue/base.log`,
Exitcode 0). Die entpackte dev6-Kopie lud diesen Stand und spielte sieben
Kapitel bis Orania (`journey.log`, Exitcode 0). `journey-upgrade-blue6.json`
bestätigt `complete=true`, `upgradedFromBase=true` und
`oldSavePreserved=true` bei 2.638 Bewegungen, 150 Kartenrändern,
51 Türen und sieben Fähren. Team, PC, Geld, Inventar und Lavados-Beleg
blieben erhalten. Ligastatus und Team stammen aus dem kontrollierten
alten Basistest; Zufalls- und sichtbare Begegnungen waren aus.
