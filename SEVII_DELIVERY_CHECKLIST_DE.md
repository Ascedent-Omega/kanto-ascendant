# Vollständige Sevii-Erweiterung – Lieferziel und aktueller Nachweis

## Aktueller Legendenvertrag (01.10.2026)

Die drei alten Regi-Heiligtümer sind geschlossen. Regirock, Regice und
Registeel sind ausschließlich nach der Tanoby-Waage, der Hoenn-Forschung
und der Liga an ihren jeweiligen Inschriften erhältlich. Vorhandener Besitz
bleibt erhalten. Jede fangbare Legende kann pro Durchlauf genau einmal
gefangen werden; NG+ öffnet ihre Begegnung nach erneuter Erfüllung der
Questbedingungen, ohne ältere Exemplare aus Bank oder Archiv zu entfernen.
Groudon (Rot, Glutberg),
Kyogre (Blau, Eisfallhöhle) und Rayquaza (Grün, Trainerturmdach) haben
eigene Sevii-Siegel. Erst der Besuch der schwarzen Tür im eigenen Riss-Schrein,
die 130 gewöhnlichen Hoenn-Arten und das abgeschlossene Insel-Finale wecken
das persönliche Siegel. Jirachi bleibt allein an der Konvergenztür; dafür
sind alle 134 Hoenn-Arten außer Jirachi und die bisherigen Pfad- und
Forschungsbedingungen erforderlich. Voxel Ascendant 3.0.0-rc.2 ist für
Sevii verpflichtend: Die Fähre prüft das aktive Mod und die Inselkarten
schalten dessen Darstellung ein.
Mit installiertem Sevii führt nur die Konvergenztür zu Jirachis Wunschkammer;
der frühere Kapitänszugang ist geschlossen.

Die Sevii-Regionskarte ist ab der ersten Ankunft verfügbar, mit START
gegen Kanto wechselbar und mit SELECT für Ortsinformationen nutzbar.
Nach Kapitel 5 sind nur bereits besuchte Inseln per FLIEGEN erreichbar;
vorher ist auch ein Rückflug nach Kanto gesperrt. Die Fähre nach Orania
bleibt davon unabhängig. Die Karte wird im Begleitmod des dev13-Testpakets
mit einem 1672 × 941 Pixel Master geliefert.

Die folgenden älteren QA-Protokolle sind historische Belege für den damaligen
Stand. Aussagen zu offenen Heiligtümern, ursprünglichen Wetterkammern und
dem Paket dev6 gelten **nicht** als Prüfung dieses neuen Vertrags.

## Archiv: frühere Kontinuitätsentscheidung (überholt)

Die zuletzt gewünschte Richtung sind **alternative Fundorte**, keine zusätzliche
charakterfremde Legende pro Durchlauf. Groudon, Kyogre und Rayquaza bleiben in
ihren ursprünglichen Charakterpfaden und Räumen. Der verworfene freie
„Drei Horizonte“-Zugang ist aus der Laufzeitverdrahtung und der Fangliste
entfernt; sein Entwurf liegt ausschließlich außerhalb des Pakets im QA-Archiv.

Regirock, Regice und Registeel bleiben in ihren alten Heiligtümern. Tanoby
bietet nach „Der schlafende Riese“ nur eine Alternative: Der originale
Heiligtumszugang (Option, Gen 3, Ruhmeshalle, Hoenn-Dex) und das jeweilige
Originalrätsel **dieses Durchlaufs** müssen zusätzlich freigeschaltet sein.
Die Insel liest dafür direkt `available` und `accessLight` des bestehenden
Heiligtumsmoduls; sie setzt keine Freischaltung selbst. Auch beim Fang wird
diese Voraussetzung erneut geprüft. Ein Fang/Geschenk sperrt dieselbe Art
an beiden Orten dauerhaft; Formen und NG+ erzeugen kein zweites Exemplar.
Der Forschungsabschluss auf Sevii benötigt weiterhin keinen Besitz der Regis.
Die alten Durchlaufbelege, einschließlich der Entstehungsinsel-Voraussetzung,
werden nicht durch einen Insel-Fang vorgetäuscht.

Die bisherigen nativen Läufe v4/v5 belegen die frühere Fang-/Historienlogik,
**nicht** die jetzt strengeren Zugangsvoraussetzungen. Aktueller Unit-Stand:
78 Riesenquest-, 51 Heiligtums-, 85 Historien- und 78.430 Integrationsprüfungen
bestanden. **`regi-return-native7.log`, Exitcode 0**, prüft jetzt zusätzlich die
Ablehnung ohne Hoenn-Zugang und ohne jedes Originalrätsel. Alle drei alten
Rätsel wurden mit nativen Eingaben vor den alternativen Fängen gelöst; die
ursprünglichen Pokémon blieben bis zum Fang auf Sevii am alten Ort sichtbar.
Beim Fang wird die ursprüngliche Freigabe erneut geprüft. Nach Laden bleibt
jede Art einmal vorhanden. Erinnerungsabschlüsse, Speicherausfall/Wiederholung,
exakte Rückwege und tatsächliche Legacy-Übernahme sind bestanden.
`regi-return.json` nennt ausdrücklich `originalPuzzlesBeforeCaptures`.
Der Lauf umfasst 1.863 Sevii-Schritte, 110 Kartenränder, 28 Türen und vier
Fährfahrten. Liga/Finale, Team, Hoenn-Dex und alte Kanto-Zuwege sind weiterhin
Fixtures; dies ersetzt weder einen Balancenachweis noch den NG+-Menütest.
Lauf v6 wurde wegen einer im Prüftreiber erkannten falschen Rückfahrt
gezielt beendet und liefert keinen Erfolgsnachweis.


Dieser Arbeitsstand ist **noch nicht die fertige Erweiterung**. Das Ziel
bleibt eine in sich abgeschlossene Sevii-Erweiterung nach der Pokémon-Liga,
mit den Fanglücken der drei Charakterpfade und Gen-4-Inhalten. Ein erster
Inselabschnitt oder eine importierte Kartenwelt allein erfüllt das Ziel nicht.

## Anforderungen und Belege

| Anforderung | Aktueller Stand | Nachweis beziehungsweise noch nötige Arbeit |
| --- | --- | --- |
| Eintritt erst nach der Liga | Implementiert | `S.depart` und `S.sail` verlangen `EVENT_BEAT_CHAMPION_RIVAL`; vor der Liga keine Inselbegegnungen. Automatisierte Zugangstests. |
| Rückfahrt und Herausforderung | In Paket dev21 nativ geprüft | Die Fähre bringt den Spieler ab der ersten Ankunft von jedem der sieben Inselhäfen nach Orania; 13 Fahrten ohne Storyfortschritt geprüft. Sevii nutzt Team-Level als Untergrenze über den verfassten Leveln: gewöhnliche Wild-Pokémon Referenz −10, Trainer Referenz, Ass und örtliche Legendäre Referenz +2. Mit Level-90-Team im echten Client: Wild 80, Trainer 90, Regirock 92. Kanto bleibt unverändert; persistente Latias/Latios behalten ihr festes Level. |
| Alle sieben Sevii-Inseln als verbundene Welt | Import und Transport implementiert | 135 Originalgebiete / 266 Laufzeitkarten, sieben Häfen, echte Fährfahrten im nativen Prüflauf v8. |
| Türen, Wege und Rückwege | Geometrieprüfung bestanden; zusätzliche Spieltests nötig | 278 Türen, 31.939 begehbare Zellen; kein unerreichbares Gebiet mit Landfläche, kein gestrandeter Türausgang. Reine Kulissenfragmente sind separat ausgewiesen. Der Zellgraph prüft mögliche Wege, nicht jede Folge von Eisrätselzuständen. |
| Eigenständige abgeschlossene Inselgeschichte | Sieben Kapitel mit örtlichem Abschluss implementiert | Alle Kapitel einzeln sowie drei frische, zusammenhängende Reisen mit ausdrücklich gewähltem Rot, Grün und Blau bis zur Rückkehr nach Orania bestanden; siehe `SEVII_JOURNEY_QA_DE.md`. |
| Giratina aus der Zerrwelt, dauerhaft nicht fangbar | Szenen, Fang- und Geschenk-Sperren implementiert | Beide kanonischen Formen und sechs aktive Geschenkprofile nativ geprüft. Alte Pokémon/Belege bleiben erhalten; neue Ausgaben und auch Meisterball-Fänge gesperrt. Weitere globale Erwerbswege bleiben Teil des Legendenaudits. |
| Alle Lücken der roten, grünen und blauen Wandertrainer | Fangorte und vollständiger nativer Fangtest bestanden | Rot 75/75, Grün 77/77, Blau 78/78 fehlende Arten im Katalog. Alle 218 gewöhnlichen Ziele nativ würfelbar; Inhaltsschalter, Generationsprofil und die bestehende Freigabe „Jenseits von Kanto“ bleiben wirksam. |
| Gen-4-Pokémon und ausreichender Platz | 93 gewöhnliche Arten in 23 Lebensräumen zusammen mit Hoenn implementiert | 84 Begegnungstabellen; Musterbusch in sechs Bereiche geteilt. Echte kanonische Identitäten und klassische Kampfgrafiken im QA-Paket. 218/218 Fang-/Box-/Speichertests bestanden; Barschwa sowie beide Perlu-Zweige nach echten Fängen und Itemkauf nativ geprüft. |
| Legendäre pro Durchlauf einzigartig | Gewöhnliche Fangtabellen bleiben legendenfrei; Fangbelege sperren weitere Fänge im aktuellen Durchlauf und öffnen nach NG+ neu | Die drei Regis gehören nur zu Tanoby, die alten Heiligtümer sind geschlossen. Groudon/Rot, Kyogre/Blau und Rayquaza/Grün erwachen nach eigenem Schreinbesuch und 130 Hoenn-Arten auf Sevii; Jirachi verbleibt nach dem vollständigen Hoenn-Eintrag an der Konvergenztür. Der echte Legacy-Übergang wurde für alle katalogisierten Legenden nativ geprüft; ein vollständiger NG+-Menüdurchlauf bleibt offen. |
| Spielbare, belebte Inseln | Teilweise implementiert | 20 Bewohner mit Nachspieltexten, sieben Versorgungsläden, zwei Beerenläden, sieben PCs, sieben Journalstellen und vier Kapitelbelohnungen nativ geprüft. 14 freiwillige Inseltrainer und acht Turmetagen mit einmaligen Itempreisen nativ geprüft. Drei Medizinläden mit sieben geprüften Feld-/Kampf-Items ergänzt. Turmaufstieg, Titel und Rückweg funktionieren. Gluttherme und gemeinsame Pension mit Route 5 sind jetzt nativ geprüft; siehe `SEVII_PLAYABILITY_QA_DE.md`. |
| Bisher fehlende Gen-2-/Gen-3-Items | Begonnen, **noch offen** | 89 Item-Identitäten mit festen Sevii-Quellen und 34 registrierte Beutel-Itemeffekte unter 190 geprüften Identitäten. Zink ist auf Eiland Sieben erhältlich und erhöht ab Gen 3 nur die Spezial-Verteidigung; die native Nutzung mit Kalzium und Speichern/Laden ist geprüft. Vier einmalige Typverstärker wurden nativ gesammelt, angelegt, geladen und verkauft. Ewigstein, Glücks-Ei und Münzamulett besitzen gesonderte Tragewirkungen. Weitere Wirkungen, Fundorte und Erwerbswege laut `SEVII_ITEM_PLAN_DE.md` bleiben offen. |
| Selbstständiger Abschluss und danach freies Erkunden | Lokaler Abschluss und Nachspiel implementiert | `seviiRiftSealed` und `expeditionComplete` über Szene/Epilog gespeichert; alle Fangtabellen danach unverändert. Bojen und Spiegelstein melden Beruhigung. Rückreisen aus jedem Hafen bereits geprüft; vollständige Nachspiel-Reise bleibt Teil des Gesamtdurchlaufs. |
| Fertiges installierbares lokales Paket | Entwicklungsstand dev24 gebaut und auf Integrität geprüft; finale Inhaltsfreigabe **offen** | dev24 enthält durchlaufbezogene Legendenfänge, die abschaltbare Fangserien-Card und den GS-Ball/Ivy-Übergang. 35 isolierte Lua-Tests, sechs Paketprüfungen, ZIP-CRC, natives Finale, englischen/deutschen Eich-Dialog und vollständigen NG+-Menü-/Namenslauf bestehen. Die native Balanceprobe gewann 22/22 Kämpfe. Voxel Ascendant 3.0.0-rc.2 bleibt erforderlich, `releaseReady=false`. Rot, Grün und Blau bestanden aktuelle natürliche Gesamtreisen auf dem in diesem Finale unveränderten dev23. Offene Item-Wirkungen und finale Installationsprüfung bleiben. |
| Durchlauf von Beginn bis Finale mit allen Charakteren | **Mit dev17 bestanden, einschließlich normaler Zufallsbegegnungen** | Rot, Grün und Blau absolvierten sieben Kapitel, 78 natürliche Wildkämpfe und 21 tatsächliche Center-Besuche; Speichern/Laden und Rückfahrt nach Orania bestanden. Vorbereitetes Post-Liga-Team; sichtbare Pokémon aus. Ein zusätzlicher vollständiger Rot-Lauf aus dev19 bestand. Details und Grenzen in `SEVII_PLAYABILITY_QA_DE.md`. |
| Upgrade eines vorhandenen Basis-Spielstands | **Mit materialisiertem Paket dev11 bestanden** | Unveränderte KASC-Basis `b30cfad48` erzeugt einen neuen isolierten blauen Spielstand; die dev11-Paketkopie mit Voxel Ascendant lädt ihn und spielt alle sieben Kapitel bis Orania. Ursprüngliche Pokémon-, Item-, Geld- und Lavados-Belege erhalten. `upgrade-dev11/journey-upgrade-blue11.json`; Details und Grenzen in `SEVII_UPGRADE_QA_DE.md`. |

Der nach `dev3` weiterentwickelte Quellstand bestand zusätzlich eine neue
grüne Ressourcenreise (`current-journey-green/journey.log`, Exitcode 0):
sieben Kapitel, 2.718 Routenbewegungen, 154 Kartenränder, 65 Türen,
sieben Inselfähren, 26 natürliche Wildkämpfe und sieben Center-Besuche.
Dieser Lauf umfasst bereits die neuen Besitzsperren für alte Legenden;
Ausgangsteam, Ligastatus und sichtbare Begegnungen haben die dokumentierten
Test-Fixtures der drei bisherigen Ressourcenreisen.

## Nächste Implementierungsschritte

1. Der Fang-/Box-/Speicherlauf und echte Schrittbegegnungen in allen
   84 Tabellen sind bestanden. Sichtbare Wildbegegnungen sind auf drei
   repräsentativen Wald-, Gebäude- und Wasserkarten geprüft; vollständige
   Reisen zwischen den Lebensräumen zusätzlich prüfen. Der Katalog umfasst
   218 Arten; alle drei Charakterlücken sind im Katalog geschlossen.
2. Fangortbuch und Kapitel-2-Dialogtest sind im echten Client bestanden.
   Zusätzliche klassische Kampfgrafiken sind im isolierten QA-Paket mit
   geprüfter SHA-256 verknüpft, müssen aber noch ins Installationskonzept.
3. AUTO startet auf Sevii mit Gen 3 und erweitert sich nach Maras Bericht
   auf Gen 4. Explizite Gen-Profile bleiben unverändert. Native und Unit-
   Tests decken die evidenzbasierte Freischaltung ab.
4. Drei zusammenhängende Expeditionen mit tatsächlichen Reisen sind
   bestanden: Rot, Grün und Blau, jeweils sieben Kapitel, Finale,
   gespeicherter Epilog und Rückkehr nach Orania.
5. Die vorhandenen Bewohner, Journalstellen, Läden und Kapitelbelohnungen
   um weitere Gebäudefunktionen und fehlende Gen-2-/Gen-3-Items
   ergänzen. Item-Erwerbswege und Wirkungen getrennt prüfen.
6. Legendäre Pfade getrennt prüfen. Box, Bank, Tausch und Freilassen
   eröffnen im selben Durchlauf keine zweite Begegnung; NG+ erlaubt nach
   erneuten Quests einen Fang pro Art und Durchlauf.
7. Frische Durchläufe für alle drei Charaktere und der Upgrade-Durchlauf
   eines blauen Basisspielstands sind bestanden, jeweils mit Speichern/Laden.
   Die noch offenen Inhalte und Legendenpfade fertigstellen und verifizieren;
   anschließend das vollständige Paket erstellen und prüfen.

## Verifizierter letzter Prüflauf

- Vollständiger nativer Fanglauf: **218/218** einschließlich Party/PC und
  erneutem Laden (`captures-native.json`, `captures-all.log`).
- Kapitel 2 und Fangortbuch: native NPC-/Dialog-/Menütests bestanden.
- Crystal-Grafikgeometrie: **298 Prüfungen bestanden**; nach der
  Höhenkorrektur alle **19 HEVO-Arten** erneut nativ gefangen und gespeichert
  (`captures-hevo-bounds.log`, Exitcode 0).
- Physische Begegnungstests: **84/84 Tabellen**, `walking-all.log`, Exitcode 0.
- Waldrettung: **146 echte Schritte**, fünf Kartenfragmente, Speichern/Laden
  mit Begleiterin, `forest-native2.log`, Exitcode 0; 27 zusätzliche Unit-Prüfungen.
- Eisprotokoll: Rissbilder, Fall, Wiederzufrieren, acht Schritte des Siegels,
  falscher Weg und Speicherzwischenstand, `ice-native1.log`, Exitcode 0;
  181 zusätzliche Unit-Prüfungen.
- Stationsrettung: Notstrom, echte Schleuse, drei Begleiter, Zwischenstände
  und Funkbericht, `station-native5.log`, Exitcode 0; 49 zusätzliche Unit-Prüfungen.
  Eigene Konsolenansicht und Verbraucherhilfe in `station-ui.log` geprüft.
- Ruinenweg: vier echte Ebenen, falsches Loch, Speichern unterwegs und
  vollständiger Rückweg zum Bericht, `ruins-native3.log`, Exitcode 0;
  30 zusätzliche Unit-Prüfungen. Giratina-Bild nach Palettenkorrektur visuell geprüft.
- Finale: 63 Bewegungen / 19 echte Stärke-Schübe, Zurücksetzen, Laden
  mitten im Rätsel, Ankerdialoge, Siegelszene, Epilog und ruhige Boje:
  `finale-native4.log`, Exitcode 0. 286 zusätzliche Modellprüfungen.
  Reisen zwischen Camp, Kalibrierkammer und Ankerkammern nutzt dieser
  isolierte Test als Teleport-Fixtures, daher noch kein Gesamtreisenachweis.
- Nachspiel: feste Storysteine widerstehen echter Stärke; deutsche
  Finale-Beschriftung geprüft, `aftermath-native1.log`, Exitcode 0.
- Bevölkerung und Dienste: `population-native3.log`, Exitcode 0; sieben
  Läden/PCs/Journalstellen, 40 Bewohnergespräche, volle Tasche mit späterer
  Belohnungsabholung und Wiederladen. 40 zusätzliche Unit-Prüfungen.
- Beeren: 10 Johto-/15 Hoenn-Beeren; tatsächliche Käufe und gespeicherte
  Bestände. Gekaufte Lydzibeere über Ausrüstung getragen, geladen, in einer
  nativen Kampfrunde verbraucht (Angriff +1), nach erneutem Laden verbraucht.
- Item-Abgleich: `item-audit-native3.log`, 190 registrierte Identitäten,
  56 Archiv-TMs, 65 Bereitschaftseinträge über Gen 2–7; kein globaler
  Vollständigkeitsnachweis. Details in `SEVII_ITEM_PLAN_DE.md`.
- Inseltrainer: `trainers-native2.log`, Exitcode 0. 14 Siege, normale
  Niederlage mit Rückkehr zum Heilort, ein Kampf mit vollständigen Gegner-KP,
  13 Kämpfe mit verkürzten KP-Fixtures, alle Belohnungen, spätere Abholung,
  doppelte Callback-Abwehr und Speichern/Laden. Noch kein Balancenachweis.
- Trainerprofile: `trainer-profiles-native3.log`, 168 Teamslots über Gen 1–4,
  keine Platzhalterattacken, zurückgestellte Belohnung nach Profilwechsel,
  Laden nach abgebrochenem Kampf, Menürückkehr und nativer
  Checkpoint-Schutz. Eigene Trainerkämpfe bieten keinen Kampf-Zwischenspeicher.
- Giratina: `legend-policy-native3.log`, sechs Geschenkprofile und zwei
  Formen, Fang-/Code-Sperren, Speicherausfall, alte Reservierungen und
  Altbesitz geprüft. Details und offene globale Fragen in `SEVII_LEGEND_AUDIT_DE.md`.
- Weitere Items: `finds-native3.log`, sieben Aprikokoballkäufe, sechs
  Fund-/Verkaufswege, volle Tasche und gespeicherte Fundbelege. Ein gekaufter
  Freundesball im tatsächlichen Fangablauf verbraucht, Bindung nach Laden
  erhalten. Bevölkerungstest jetzt 73 Prüfungen.
- Trainerturm: `tower-native2.log`, acht Siege gegen Gegner mit vollen KP,
  normale Niederlage, gesperrte Reihenfolge, tatsächliche Treppen aufwärts
  und abwärts, volle Tasche, Speichern auf Etage 4, Dachzeremonie und Rückkehr
  nach draußen. Ein jeweils geheiltes Level-100-Testteam und feste
  Zufallswerte ersetzen keinen Balancenachweis. `tower-ui2.log` prüft den
  sichtbaren Journaltitel und die eigene Menüüberschrift.
- Trainerprofile erweitert: `trainer-profiles-native4.log`, **264 Teamslots**
  über alle 22 Trainer und Gen 1–4; keine Platzhalterattacken.
- Unit-/Integrationsprüfung: **78.301 Prüfungen bestanden**.
- Geometrieaudit: alle sieben Inseln ohne gestrandete oder unerreichbare
  aktive Türen; reine Wand-/Meer-Kulissen separat ausgewiesen.
- Native LÖVE-Ausführung: `native-v8.log`, Exitcode 0,
  `SEVII_NATIVE_SEVEN_FERRIES_STORY_SAVE_SURF_CAPTURE_ICE_PASS`.
- Nativer Umfang: Kapitel 1, Save/Load, SURFER, Wingull-Fang, Reisen zu
  allen sieben Inseln, Hafen-Ausgänge, Sprungkante und Eisfallmechanik.
- Bilder: `island-2-arrival.png` bis `island-7-arrival.png`,
  `icefall-landing.png` im lokalen QA-Verzeichnis.

Der aktuelle Stand ist als **Fortschritt** einzuordnen: sieben spielbare
Kapitel, Fangortkatalog, Generationsevidenz und Fangortbuch sind vorhanden.
Weitere Gebäudefunktionen und Items, der globale Legendenaudit, die
breitere Sichtprüfung der Wildgrafiken und das
installierbare Gesamtpaket bleiben offen.
Es gibt keinen externen Blocker; die restlichen Inhalte sind Entwicklungsarbeit.

- Frische Charakterreisen: `journeys-all-characters.json`, **3/3 bestanden**,
  jeweils 2.632 Routenbewegungen, 150 Kartenübergänge und 51 Türen.
  Questfortschritt entsteht durch tatsächliche Spielaktionen; nach jedem
  Kapitel gespeichert und geladen. Die Fixture-Grenzen stehen im Reisebericht.

- Medizin: `medicine-native6.log`, Exitcode 0. Sieben Käufe, sieben echte
  Feldanwendungen und sieben Kampfrunden; Verbrauch, Heilung, Status,
  Wiederbelebung und Freundschaft mit Speichern/Laden. 83 Funktionsprüfungen;
  Bevölkerungstest auf 77 Prüfungen erweitert.

- Begegnungsfreigabe korrigiert: Die bestehenden reinen Kanto-Spielstände
  erzeugen keine erweiterten Sevii-Wildarten. Auch alte zwischengespeicherte
  Tabellen dürfen die aktuelle Sperre nicht umgehen. Fangortbuch erklärt
  die Bedingung; 22.103 Habitat-Prüfungen bestanden. Alle drei frischen
  Reisen danach erneut bestanden (`full-journey4`); der aktualisierte
  Vollfangtest ist ebenfalls bestanden.

- Meeresforschung: Drei vorhandene Entwicklungsitems als feste Quelle auf
  Eiland Sechs. `evolution-native8.log` und `evolution-native9.log` prüfen
  echte Fänge, Käufe, Beutel-Entwicklungen zu Milotic/Aalabyss/Saganabyss
  und Speichern/Laden. Bevölkerungstest jetzt 81 Prüfungen.

- Wiederholung nach Freigabekorrektur: `captures-expanded1.log` und
  `captures-expanded.json`, **218/218 Fänge**, Team/PC und Wiederladen
  bestanden. `walking-expanded1.log`: **84/84** echte Schrittbegegnungen
  bestanden. `catalog-gated1.log` bestätigt die reale Sperre im versiegelten
  Spielstand, 218 nach Freigabe, 0 unter Gen 1 und 125 unter Gen 3.

- Sichtbare Wildbegegnungen: `visible-native8.log`, Exitcode 0 und
  `visible-probe.json`, **3/3 Karten bestanden**. Natürlich erzeugte
  Pokémon im Beerenforst, in der verlassenen Station und im Wasser an der
  Bond-Brücke durch echtes Betreten berührt, nativ gefangen und nach Laden
  im Team/PC wiedergefunden. Die konkrete Art wird vom Spiel ausgewählt;
  die Testnamen bezeichnen Lebensräume, keine erzwungenen Arten. Die
  Ausgangslage, Kartenwechsel und die Position des Spielers neben einem
  bereits natürlich erzeugten Pokémon sind Testvorbereitungen. Die drei
  Bilder zeigen sichtbare Körper; dies ist kein Grafiknachweis für alle
  218 Arten. Der beschleunigte Test wartet auf die tatsächliche
  Auftauchanimation, bevor er ein Pokémon berührt.

- Hoenn-Forschungsbälle: `balls-native3.log`, Exitcode 0, und
  `research-balls.json`: vier gekaufte Bälle tatsächlich geworfen, Pokémon
  gefangen und nach Laden im Team/PC erhalten. Fehlwurf und Heilmittelrunde
  erhöhen den Timerbonus korrekt. 106 Funktionsprüfungen, Bevölkerungstest
  jetzt 84 Prüfungen. `item-audit-native8.log`: 68 feste Sevii-Quellen und
  22 registrierte Effekte innerhalb der 190 geprüften Item-Identitäten.

- Basis-Upgrade: `upgrade-base-blue2.log` und `upgrade-journey-blue2.log`,
  beide Exitcode 0. Alle sieben Kapitel und Rückkehr nach Orania mit dem
  vorher durch die unveränderte KASC-Basis gespeicherten Spielstand.
  Ursprüngliche Team-/Boxdaten, Items, Geld und Lavados-Beleg erhalten;
  vorgesehene Ausrüstungs-/Fähigkeits-Ergänzungen gesondert validiert.
- Legendenkatalog: `legend-catalog-native1.log`, Exitcode 0, 23 kanonische
  Sonderarten mit Formen, Geschenkprofilen und bestehenden Hoenn-Besitzern.
  Zum Zeitpunkt des Katalogtests benötigten 13 Gen-4-Sonderarten eigene geprüfte einmalige Zugänge;
  ein Geschenkprofil allein ist kein Fangort. `SEVII_LEGEND_SOURCES.json`
  hält den konkreten Befund fest, ohne globale Einzigartigkeit zu behaupten.

- Gen-4-Besitzhistorie: `legend-history-native4.log`, Exitcode 0; tatsächliche
  Ei-/Geschenkauslieferung, Speicherausfall und Wiederholung, Fang und
  Duplikatsperre sowie Legacy-Archivtransaktion/frischer Datenaufbau. Entfernen
  der Pokémon als Fixture, kein Freilassen-/NG+-Menütest. 44 Funktionsprüfungen.
- Giratina-Kontrolllauf: `legend-policy-native4.log`, Exitcode 0; beide Formen,
  sechs Geschenkprofile, alte Belege und Meisterball-Sperre weiterhin geprüft.
- Erstes Legendenmysterium: `mystery-native4.log`, Exitcode 0. Heatran am
  Glutberg nach Expedition und örtlicher Versiegelung: 654 echte Schritte,
  vier Kartenränder und 16 Türen, drei Messstellen, Ventilrätsel mit
  Zwischenstand, native Flucht/Wiederholung, Fang, Laden und Rückfahrt
  nach Orania. 51 Funktionsprüfungen; aktuelle Integration 78.311 Prüfungen.
  Zwölf weitere Gen-4-Sonderpfade bleiben zu implementieren.

- Drei Stimmen: `guardians-native1.log`, Exitcode 0; Selfe, Vesprit und Tobutz
  nach zusammenhängender Nebenquest tatsächlich gefangen und nach Laden
  jeweils einmal gespeichert. 1.420 Schritte, 76 Kartenränder, 27 Türen,
  fünf Fähren, Erinnerungsfragen mit Zwischenstand, zurückgebrachte Schleife,
  echte Turmzeremonie, Forschungsbericht und Rückfahrt. Die acht zuvor
  verdienten Turmsiege sind hier eine Fixture; ihre Kämpfe wurden separat
  geprüft. 61 neue Funktionsprüfungen, Integration jetzt 78.323 Prüfungen.
  Aktuell verbleiben neun Gen-4-Sonderpfade. 32 Spezialgrafiken sind in
  `SEVII_SPECIAL_ASSETS.json` für das spätere Paket mit Prüfsummen aufgeführt.

- Eine Nacht im Mondlicht: `dreams-native2.log`, Exitcode 0; Cresselia und
  Darkrai nach Questfortschritt tatsächlich gefangen und nach Laden jeweils
  einmal gespeichert. 859 Schritte, 50 Kartenränder, 40 Türen, echte falsche
  Türschleife und neun korrekte Türen, Laden mitten im Weg, erwachter Bewohner,
  friedlicher Abschluss und Rückfahrt. 41 Funktionsprüfungen; Integration
  jetzt 78.339 einschließlich fehlgeschlagener Host-Kartenwechsel.
  Sechs Gen-4-Sonderarten sind geprüft, sieben bleiben offen.
- Aktualisierter Legendenkatalog: `legend-catalog-native2.log`, Exitcode 0,
  erkennt die sechs neuen Fangbesitzer und prüft für alle 23 Sonderarten
  weiterhin den Ausschluss aus gewöhnlichen Sevii-Begegnungen. Grafikpfade
  und fehlende Dateien der offenen Arten werden jetzt ebenfalls erfasst.
  57 Spezialgrafik-/Rufdateien sind im zusätzlichen Paketmanifest aufgeführt.

- Rocket-Übergang: `rocket-transition-native2.log`, Exitcode 0. Darkrais
  alter Rocket-Pfad wird durch die bestehende Sevii-Quest abgelöst; offene
  Dialoge/Kampagnen laufen weiter. Alte Darkrai-/Regigigas-Fangbelege werden
  dauerhaft übernommen, tatsächliche Box-Verwahrung genau einmal
  zurückgegeben, Laden und Legacy-Übernahme geprüft. Regigigas' bisheriger
  unbesessener Rocket-Zugang bleibt erhalten, bis sein Inselpfad fertig ist.
  Quellenabgleich um Rocket erweitert; keine zusätzliche Inselquest in
  diesem Prüfschritt abgeschlossen. Es bleiben sechs geprüfte und sieben
  offene Gen-4-Inselpfade.

- Der schlafende Riese: `giant-native3.log`, Exitcode 0. Drei echte
  Tanoby-Inschriften, Gegengewichte mit Fehlversuch/Reset, gespeicherte
  Teilanordnung, Bericht, Level-75-Regigigas-Fang, genau ein Exemplar nach
  Laden und Rückfahrt nach Orania. 1.115 Schritte, 62 Übergänge, 18 Türen,
  eine Fähre. 41 Quest- und 78.351 Integrationsprüfungen bestanden.
- Regigigas ersetzt jetzt seinen früheren Rocket-Fangpfad. Aktuelle
  Migration erneut mit `rocket-transition-native3.log`, Exitcode 0,
  geprüft; Genesect bleibt als eigenständige Rocket-Rettung verfügbar.
  `legend-catalog-native4.log` erfasst neue und abgelöste Besitzer.
  Spezialpaket jetzt 74 hashgeprüfte Dateien für sieben Arten.
  **Sieben von 13 Gen-4-Inselpfaden geprüft; sechs bleiben offen.**

- Heimweg der Strömung: `tidal-native1.log`, Exitcode 0. Planke bergen und
  verbauen, drei geordnete Küstensignale, Zwischenstände speichern/laden,
  sichtbare Rückkehr der Forscherin, Hausbericht, Phione und Manaphy
  tatsächlich fangen, jeweils genau ein Exemplar nach Laden, Rückfahrt
  nach Orania. 1.358 Schritte, 76 Übergänge, 18 Türen, eine Fähre.
  46 Quest- und 78.369 Integrationsprüfungen bestanden. Spezialpaket jetzt
  90 hashgeprüfte Dateien für neun Arten; Kataloglauf v5 bestanden.
  **Neun von 13 Gen-4-Inselpfaden geprüft; vier bleiben offen.**
  Das globale Erwerbs-/Einzigartigkeitsaudit sowie Items, Gebäudefunktionen
  und das fertige Installationspaket bleiben erforderlich.

- Pension: `legend-breeding-native3.log` und `nursery-native2.log`, jeweils
  Exitcode 0. Neue Sonder-Eier gesperrt, vorhandene Eltern/Eier als Besitz
  erfasst. Altes Phione-Ei tatsächlich abgeholt und ausgebrütet; gewöhnliches
  Karpador-Ei weiterhin per Welt-Schritt produziert. 54 Historienprüfungen.
  Die Sonder-Ei-Sperre ist eine Sevii-Einzigartigkeitsregel, keine Behauptung
  über das kanonische Zuchtverhalten. Historische Eier bleiben erhalten.

- Was wieder wächst: `garden-native1.log`, Exitcode 0. Oda/Rika, trockenes
  Beet, physisch entferntes Geröll, falsche/richtige Schleusenwahl, einmalig
  verbrauchte Samen, gespeicherte Dankeswahl, Bericht, Level-65-Shaymin-Fang
  und Rückfahrt. 1.764 Schritte, 110 Übergänge, 14 Türen, eine Fähre.
  43 Questprüfungen; Integration 78.381. 98 Spezialdateien für zehn Arten
  hashgeprüft, Quellenkatalog v6 bestanden. Wasser und Wachstum werden
  erzählt, nicht als zusätzliche Landschaftsanimationen dargestellt.
  **Zehn von 13 Gen-4-Inselpfaden geprüft. Dialga, Palkia und Arceus offen.**
  Ältere Legendenkontinuität, weitere Items/Gebäudefunktionen sowie das
  fertige Paket und abschließende Gesamtprüfungen bleiben erforderlich.

- Takt und Grenze: `time-space-native1.log`, Exitcode 0. Dialga/Palkia
  Level 75, beide Fänge und Einzelbesitze nach Laden; Uhrenrätsel, Rundweg
  mit Fehlversuch, echtem Verlassen/Neustart und Rückfahrt geprüft.
  1.892 Schritte, 92 Übergänge, 39 Türen, eine Fähre; 54 Questprüfungen.
- Sieben Zeugnisse: `testimonies-native1.log`, Exitcode 0. Alle sieben
  Inselberichte über echte Reisen kopiert; vorhandener Heatran kann jetzt
  das Druckrätsel abschließen, ohne dupliziert zu werden. Soras Buch,
  Vorlesen, Arceus Level 80, Einzelbesitz nach Laden, Rückfahrt bestanden.
  1.764 Schritte, 64 Übergänge, 72 Türen, acht Fähren. Sechs andere
  Forschungsabschlüsse sind Fixtures mit separaten nativen Questnachweisen.
  58 Zeugnis-, 58 Heatran- und 78.423 Integrationsprüfungen bestehen.
  **Alle 13 Gen-4-Sonderpfade nativ geprüft; 122 Spezialdateien vorhanden.**
  Die Gesamt-Erweiterung ist damit noch nicht fertig: ältere Legenden,
  weitere Item-/Gebäudefunktionen und Paket-/Upgrade-Abschluss bleiben offen.

- Weitere Heilmittel: `recovery-native3.log`, Exitcode 0. AP-Top mit echter
  Attackenauswahl/Abbruch, einmalige Zauberasche mit Beutelgrenze und
  Wiederbelebung sowie drei wiederverwendbare Glasflöten in echten
  Kampfrunden und nach Laden geprüft. 54 Effekt-, 93 Bevölkerungs- und
  78.429 Integrationsprüfungen. Itemaudit v9: 73 feste Sevii-Identitäten,
  27 registrierte Effekte unter 190 geprüften Identitäten. Testbedingungen
  und Grenzen stehen im Itemplan; weitere Items bleiben offen.

- Lavados-Kontinuität: `moltres-continuity-native1.log`, Exitcode 0.
  Tatsächliches Geschenk, vollständiger Vulkanweg inklusive Magmar,
  freiwilliger Abschluss an einem Fundmarker ohne zweiten Fang,
  Speicherausfall/Wiederholung, Rückweg nach Zinnober, genau ein Lavados
  nach Laden, neue Fang-/Geschenkausgaben gesperrt und tatsächliche Legacy-
  Transaktion geprüft. Beide Formen teilen denselben Beleg. 61 Historien-
  und 20 Vulkanprüfungen; übrige ältere Legenden weiterhin offen.

- Kontrollläufe nach Lavados: `legend-policy-native5.log` und
  `legend-history-native5.log`, beide Exitcode 0. Giratina-Sperren weiter
  bestanden; erster echter Lavados-Fang weiterhin möglich, zweiter Ball
  gesperrt, Besitzbeleg nach Laden und tatsächlicher Legacy-Übernahme
  erhalten. Der Lauf wiederholt auch die bisherigen Heatran-/Geschenkfälle.

- Drei Hoenn-Hüter: Regirock, Regice und Registeel nach der vollständigen
  Tanoby-Forschung sowie jeweiligem Originalrätsel und Hoenn-Zugang alternativ auf Sevii fangbar, jeweils Level 65 mit gemeinsamer
  Besitzhistorie. `regi-return-native4.log`, Exitcode 0: alle drei plus
  Regigigas tatsächlich gefangen, nach Laden jeweils einmal vorhanden;
  danach drei alte Heiligtumsrätsel und Abschlüsse ohne Duplikate sowie
  Legacy-Übernahme bestanden. 1.319 Sevii-Schritte, 68 Übergänge, 24 Türen,
  eine Fähre. Begrenzungen der Test-Ausgangspunkte stehen im Legendenaudit.
  61 Quest-, 85 Historien-, 51 Heiligtums- und 78.429 Integrationsprüfungen.
  **18 der 23 Hoenn-/Gen-4-Sonderarten haben nun Insel-Fangpfade oder ein erweitertes Insel-Wandergebiet.**
  Von den übrigen fünf Hoenn-Arten bleiben Groudon, Kyogre und Rayquaza auf Wunsch an ihren bisherigen Orten und in ihren Charakterpfaden. Für Latias und Latios ist die Erweiterung ihres bestehenden Wandergebiets mit gespeicherten Aufenthaltsorten umgesetzt und an Land sowie auf Wasser nativ geprüft; 5 % gelten ausschließlich im aktuellen Gebiet des Wanderers. Alle 45 Außenkarten des Kanto-Grundspiels sowie Vulkanfuß und Himmelsplattform sind im nativen Schritt-/Fluchttest abgedeckt; der ursprüngliche Zugang zur Himmelsplattform bleibt Pflicht. Für Jirachi und Deoxys bleiben zusätzliche Inselangebote offen; alle Angebote müssen bestehende Forschung und NG+ wahren. Die Besitzkontinuität älterer Legenden bleibt weiter zu prüfen.
  Spezialpaket: 187 hashgeprüfte Dateien für 18 Arten (einschließlich der beiden Eon-Wanderer); lebender Quellenkatalog v9 und
  Pensionsabgleich v4 bestanden.

- Abschließender Regi-Kontrolllauf: `regi-return-native5.log`, Exitcode 0,
  wiederholt den vollständigen Insel-/Heiligtumsnachweis mit exakt
  begehbaren Rückkehrpunkten, ohne automatische Positionsreparatur.
  `regi-return.json` bestätigt vier Einzelbesitze, drei alte Rätselabschlüsse
  ohne weitere Fänge sowie tatsächliche Legacy-Übernahme. Dieser Lauf belegt
  den Stand vor der oben dokumentierten Zugangskorrektur.

- Aktueller Quellenkatalog: `legend-catalog-native10.log`, Exitcode 0.
  23 Identitäten, 13 Gen-4-Inselpfade und drei Regi-Alternativen mit
  dokumentierten Originalvoraussetzungen. Keine Sevii-Fangbesitzer für
  Groudon, Kyogre oder Rayquaza; die ursprünglichen Charakterkammern
  bleiben registriert. Katalogabgleich ersetzt keine nativen Freischaltungstests.

- Premierball: `balls-native5.log`, Exitcode 0, fünf Ballkäufe und Fänge
  samt Laden; erfolgloser Premierwurf verbraucht einmal, erfolgreicher
  Premierfang bei vollem Team landet im PC. 118 Ball-, 96 Bevölkerungs-
  und 78.430 Integrationsprüfungen. `item-audit-native10.log`, Exitcode 0:
  jetzt 74 feste Gen-2-/Gen-3-Itemquellen und 28 registrierte Effekte.
  Katalogpreis und fehlender Kaufbonus sowie Test-Fixtures sind im Itemplan
  ausdrücklich vermerkt. Zink ist wegen des bisher gemeinsamen Spezial-
  Trainingswerts weiterhin nicht als funktionsfähig freigegeben.


Aktueller Eon-Nachweis: `eon-native4.log` (Exitcode 0): alle 45 Kanto-
Außenkarten per echtem Schritt und Flucht geprüft, stabile DVs/Statuswerte,
falscher Aufenthaltsort, Schutz, beide Sevii-Fänge, Laden und tatsächliche
Legacy-Übernahme bestanden. 53 Kontinuitäts-, 16 Oberflächen-, 99 Historien-
und 78.497 Integrationsprüfungen bestanden. Abdeckung und QA-Fixtures stehen in `SEVII_LEGEND_AUDIT_DE.md`.

Quellenkatalog v11 (`legend-catalog-native11.log`, Exitcode 0) aktualisiert:
23 Identitäten, 13 Gen-4-Pfade, drei Regi-Alternativen und zwei Erweiterungen
der originalen Eon-Wanderer. Beide Eon-Arten haben keine fehlenden Artefakte
im isolierten QA-Paket; der aktuelle Katalog nennt ihre erweiterten Karten.


- KASC-Außenkarten: `eon-native5.log`, Exitcode 0. 47 echte Schritt-/Flucht-
  Begegnungen, beide Sevii-Fänge und Legacy bestanden. 55 Kontinuitäts-,
  24 Oberflächen-, 99 Historien- und 78.497 Integrationsprüfungen.
- Erstes eigenständiges Testpaket `package-dev1`: 48.633 inventarisierte
  Dateien, 339.863.753 Bytes, keine externen Symlinks, keine ROM-/Save-Dateien.
  Sechs negative/positive Paketintegritätsprüfungen bestanden. Der Quellen-
  katalog v12 besteht bereits im materialisierten Paket. Eine bestandene
  Integritätsprüfung ersetzt keine Freigabe der Gesamterweiterung.


- Eigenständiges Paket, alle Charaktere: `package-dev1-qa/journeys.log`,
  Exitcode 0. Rot, Grün und Blau durchlaufen jeweils alle sieben Kapitel,
  speichern/laden nach jedem Kapitel und kehren nach Orania zurück.
  Je 2.632 Bewegungen, 150 Kartenübergänge, 51 Türen und sieben Inselfähren.
  Die Laufzeit verwendet das materialisierte Paket, keine Code-/Grafiklinks
  zum Entwicklungszweig. Engine-Dateien und QA-Treiber bleiben externe
  Testwerkzeuge; die Post-Liga-/Team-Fixtures und Begegnungsabschaltung gelten
  wie beim vorherigen Reisetest. Details in `SEVII_PACKAGE_QA_DE.md`.

- ZIP-Transportprüfung: `package-dev1.zip` vollständig entpackt und erneut
  verifiziert. CRC und 48.633 Datei-Hashes/Größen bestanden; SHA-256 und
  Paketgrenzen stehen in `SEVII_PACKAGE_QA_DE.md`. Kein Release-/Installations-
  oder Gesamtabschlussstatus wurde dadurch gesetzt.

- Ursprüngliche Hoenn-Kontinuität: `hoenn-continuity-capture3.log` und
  `hoenn-continuity-witness2.log`, jeweils Exitcode 0. Fünf alte Fangorte,
  echte Erstfänge beziehungsweise getrennte Forschungsabschlüsse nach
  Geschenk/Freilassen-Fixture, Deoxys-Dreieck, Jirachi-Zertifikat, Laden,
  gesperrter Doppel-Meisterball ohne Verbrauch und tatsächliche Legacy-
  Übernahme. Keine neuen Wetterportale oder Charakterfreigaben.
  `legend-catalog-native13.log` bestätigt alle sechs alten Modulbindungen.
- Schwarze/weiße Flöte: `field-flutes-native1.log`, Exitcode 0. Zwei native
  Käufe und Beutelbenutzungen, echter Schritt-/Kampfvergleich, lokale
  Speicherung, Profilgrenzen, Gebietswechsel und unveränderte Wandererprobe.
  `item-audit-native11.log` zählt 76 feste Quellen und 30 Itemeffekte.
  Beide Ergänzungen liegen nach dem eingefrorenen Entwicklungspaket dev1.

- Spielbarkeitsvergleich: `balance-native2.log`, Exitcode 0. Alle 14
  Inseltrainer mit gewöhnlichem Level-62-Team, acht Turmetagen mit Level-75-
  Team, volle Gegner-KP und unveränderter Kampfzufall. Alle 22 gewonnen,
  aber 25 eigene K. o. über den Lauf. Frische Teams pro Kampf, kein
  zusammenhängender Ressourcen-Durchlauf; Details im Spielbarkeitsbericht.
- Zusätzliche Gebäude: `services-native2.log`, Exitcode 0. Die Gluttherme
  heilt über den alten Heilungsbesitzer; die Pension auf Eiland Vier teilt
  Route 5s Elternplätze, Eier und Gebühren. Native Abgabe/Abholung in beiden
  Richtungen, Geldmangel, Training und Laden ohne Duplikat geprüft.

- Zweite natürliche Kampfzufallsfolge: `balance-native3.log`, Exitcode 0,
  erneut alle 22 Kämpfe gewonnen. Insgesamt 44 volle Kämpfe über beide
  Folgen; die Roster wurden nicht für den Test vereinfacht. Der weiterhin
  fehlende zusammenhängende Ressourcen-Durchlauf ist separat ausgewiesen.

- Nach dev4: Luxusball im Quellstand ergänzt. 172 Ball-, 104 Bevölkerungs-
  und 78.501 Integrationsprüfungen bestanden; der native Balllauf kaufte und
  fing mit allen sieben Forschungsbällen. Der Luxusball-Beleg überstand
  Speichern und Laden. Neue native Iteminventur: 79 feste Inselquellen und
  33 registrierte Wirkungen unter 190 Gen-2-/Gen-3-Identitäten. Belege:
  `luxury-ball-qa/research-balls.json` und `luxury-ball-qa/item-access-audit.json`.
  Das eingefrorene Paket dev4 bleibt unverändert und enthält diese Ergänzung
  noch nicht.

- Ebenfalls nach dev4: Sanftglocke als einmaliger Fund in der Pension auf
  Eiland Vier und als passiver Freundschaftsbonus umgesetzt. Der native
  Fundlauf bestand einschließlich Beutelgrenze, Ausrüstungsmenü, Wirkung,
  Speichern/Laden und Ablegen. Aktuelle Prüfzahlen: 178 Ball-, 109
  Bevölkerungs- und 78.503 Integrationsprüfungen. Die neue Inventur
  `soothe-bell-qa/item-access-audit.json` zählt 80 feste Inselquellen und
  33 Beutel-Itemeffekte; die Glocke hat eine gesonderte Tragewirkung.

- Neues Entwicklungspaket dev5 mit beiden Freundschaftsitems: 48.634 Dateien,
  339.893.037 Bytes, ZIP-SHA-256
  `875a7c5db5cb55d845ffbb79fd59652ca52ada607f1a6269dfa7f9ccfdc46d41`.
  CRC, vollständiges Entpacken und Hashprüfung bestanden. Die getrennte
  Paket-Engine bestand Itemaudit und eine vollständige blaue Reise mit 34
  natürlichen Kämpfen und sieben Center-Besuchen. Es bleibt ein Testpaket,
  `releaseReady=false`; siehe `SEVII_PACKAGE_QA_DE.md`.

- Das dev5-Basisspielstand-Upgrade bestand ebenfalls: unveränderte KASC-Basis
  erstellt eine neue isolierte blaue Speicherung; die entpackte Paketkopie
  lädt genau diesen Stand und spielt sieben Kapitel bis Orania. Bericht
  `package-dev5-qa/upgrade-blue/journey-upgrade-blue5.json` meldet
  `complete=true`, `upgradedFromBase=true` und `oldSavePreserved=true`.
  Ursprüngliche Pokémon, Inventar, Geld und Lavados-Beleg sind nach allen
  sieben Kapiteln erhalten.

- Nach dem eingefrorenen dev5-Paket: Ewigstein als einmaliger Höhlenfund und
  Tragewirkung implementiert. `everstone-qa5/finds.log` bestand neun
  volle-Beutel-/Fund-/Verkaufsketten sowie die native Ausrüstung und den
  Evolutionsblock vor und nach Speichern/Laden. Nach dem Ablegen war die
  Entwicklung wieder möglich. 15 Ewigstein-, 114 Bevölkerungs- und 78.505
  Integrationsprüfungen bestanden. `everstone-qa5/item-access-audit.json`
  zählt 81 feste Inselquellen und 33 Beutel-Itemeffekte unter 190 Identitäten.
  Das dev5-Paket enthält den Ewigstein noch nicht.

- Ebenfalls nach dev5: Glücks-Ei als einmaliger Dachpreis nach acht Siegen im
  Trainerturm. Ein voller Beutel verschiebt die Ausgabe mitsamt Titel. Der
  vollständige native Lauf `lucky-egg-qa4/tower.log`, Exitcode 0, bestand
  acht Turmetagen, Preisübergabe, Speichern/Laden, Abstieg, echtes Anlegen
  und einen Wildkampf mit 50 % Erfahrungspunktebonus. Die separate
  Wiederholungsprüfung `lucky-egg-qa3/lucky-egg.log` bestätigte 14 auf 21
  Erfahrungspunkte und den Erhalt nach Laden. Die Inventur zählt 82 feste
  Sevii-Quellen und 33 Beutel-Itemeffekte; das Ei hat eine gesonderte
  Tragewirkung. Dev5 enthält beide neuen Items noch nicht.

- Münzamulett nach Abschluss des vierten Kapitels als einmaliger Fund in der
  verlassenen Station auf Eiland Fünf ergänzt. `amulet-qa1/finds.log`,
  Exitcode 0, prüfte 10 volle-Beutel-Fundketten, echtes Anlegen, doppeltes
  Preisgeld in einem Trainerkampf, Speichern/Laden, Ablegen und Verkauf ohne
  erneuten Fund. 22 Trainingsitem-, 120 Bevölkerungs- und 78.507
  Integrationsprüfungen bestanden. `amulet-audit/item-access-audit.json`
  zählt 83 feste Sevii-Quellen und 33 Beutel-Itemeffekte unter 190
  Identitäten. Auch dieses Item liegt nach dev5.

- Entwicklungspaket dev6 mit den drei neueren Trageitems eingefroren:
  48.636 echte Dateien, 339.901.974 Bytes Nutzdaten, ZIP-SHA-256
  `edaa9be831c713fe221ae913e756fc34ae9b30ac61bf160f718af7a3afb98206`.
  CRC, Entpacken, vollständige Hashprüfung, sechs Integritätsprüfungen,
  nativer Itemaudit und Zehn-Funde-Lauf bestanden. Die entpackte Kopie
  spielte alle sieben Kapitel mit Blau, 35 natürlichen Kämpfen und sieben
  Center-Besuchen bis Orania (`complete=true`, Exitcode 0). Die Upgrade-
  Probe mit einem frischen alten Basisspielstand bestand ebenfalls alle
  sieben Kapitel bis Orania (`oldSavePreserved=true`, Exitcode 0).
  Dev6 bleibt `releaseReady=false`.

- Die entpackte dev6-Kopie bestand zusätzlich den 23-Arten-Legendenkatalog,
  alte Kanto-/Johto-Besitzkontinuität, den nativen Regi-Rückweg nach den
  Originalrätseln und die Kanto-/Sevii-Wanderung von Latias und Latios.
  `package-dev6-qa/catalog.log`, `old-legends.log`, `regi.log` und
  `eon.log` endeten jeweils mit Exitcode 0. Diese Prüfläufe benutzen
  dokumentierte Start-Fixtures und ersetzen keinen vollständigen
  NG+-Menütest.

- `package-dev6-qa/giratina.log` bestand die nicht fangbare Zerrweltfigur
  auch im entpackten Paket: sechs aktive Geschenkprofile, Code-Vorprüfung,
  beide Formen, Meisterball-Sperre und Erhalt einer bereits historisch
  vorhandenen Ausgabe nach Laden (Exitcode 0).

- Im entpackten dev6-Paket wurden alle **84/84** Habitat-Tabellen durch
  echte Land- oder Wasserschritte bis zum nativen Kampfstart geprüft
  (`package-dev6-qa/walking-all.log`, Exitcode 0). Der erneute vollständige
  Fang-/Box-/Speicherlauf bestand **218/218** Zielarten aus nativen
  Begegnungspools samt Ladebelegen (`package-dev6-qa/captures.log`, Exitcode
  0). Die Testanreise zu den Lebensräumen erfolgte per Teleport; die
  getrennten Kapitelreisen und Schrittprüfungen decken die Wege ab.
