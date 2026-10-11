# Sevii-Erweiterung: Einbau und Prüfstand

Stand: 01.10.2026. Entwicklungszweig `codex/sevii-expedition-20260928`,
Basis `b30cfad48`, KASC 6.7.29-rc.3. Eigenständiger lokaler Arbeitsstand;
keine Veröffentlichung und keine Änderung vorhandener Spielerprofile.

Aktualisierung vom 30.09.2026: Die alten Regi-Heiligtümer und Wetterkammern
sind geschlossen. Tanoby trägt die drei Regis; die charaktergebundenen
Wetterlegenden erhalten nach eigener schwarzer Schreintür, 130 Hoenn-Arten
und Insel-Finale jeweils ein Sevii-Siegel. Jirachi bleibt nach allen 134
anderen Hoenn-Arten an der Konvergenztür. Voxel Ascendant ist für die
Inselüberfahrt erforderlich und aktiviert auf Sevii den Voxel-Modus.
Der frühere Kapitänszugang zu Jirachis Wunschkammer ist mit Sevii gesperrt.
Ältere Prüfbelege in diesem Dokument beschreiben den früheren Stand.

Die neue illustrierte Regionskarte wird beim ersten Anlegen auf Eiland Eins
freigeschaltet. Sie zeigt die sieben Inseln bereits vor dem Fliegen und
liefert mit SELECT eigene Ortsbeschreibungen. START wechselt zwischen der
Kanto- und der Sevii-Übersicht. Die sieben sicheren Anflugpunkte werden
erst nach dem reparierten Funksignal in Kapitel 5 und nur für bereits
besuchte Inseln freigegeben. Auch der Rückflug nach Kanto ist bis dahin
gesperrt; die Fähre bleibt jederzeit benutzbar. Die
1672 × 941 Pixel große Originalillustration und die Karten-UI liegen
im mitgelieferten Begleitmod `vasc_kanto_sevii_fly_map_widescreen`.

## Umfang

Spielbar sind die sieben Inseln mit sieben Storykapiteln, örtlichem Finale
und anschließendem freien Erkunden. Die zusätzliche Fähre am Orania-Pier
öffnet im ersten Durchlauf nach der Liga; im NG+ steht sie schon beim ersten
Besuch in Orania bereit. Der Auftakt auf Eiland Eins beginnt
bei Forscherin Mara mit zwei Messbojen. SURFER wird benötigt.
Die vollständige Lieferprüfung steht in `SEVII_DELIVERY_CHECKLIST_DE.md`;
dieses Dokument ersetzt keine Freigabe des noch laufenden Entwicklungsstands.
Die Messungen und der Kapitelabschluss werden unter
`sevii_expedition_v1` über die Mod-Speicher-API gesichert.

Importiert werden 135 Feuerrot-Gebiete: die sieben Inselorte, Küsten,
Häfen, Häuser, Zentren, Nebenrouten, Höhlen, Ruinen und der Trainerturm.
Die Quellenliste steht in `scripts/sevii_maps_bprd.json`. Wegen der
Gen-1-Block- und Übergangsgrenzen werden daraus 266 Laufzeitkarten.
Die Kapitäne verbinden alle sieben Häfen und Orania; die Inselzentren heilen.
Die Rückfahrt von jedem Inselhafen nach Orania ist ab der ersten Ankunft
möglich und hängt von keinem Storykapitel ab. Auch erneutes Einschiffen
von Orania aus ist nach dem ersten Besuch möglich. Freies Fliegen wird
dagegen erst im fünften Kapitel freigeschaltet.

Sevii besitzt ein eigenes Level-Scaling. Im ersten Durchlauf gilt mindestens
das verfasste Level. Als Teamreferenz dient der höhere Wert aus gerundetem
Teamdurchschnitt und höchstem Teamlevel minus acht; Eier zählen nicht.
Gewöhnliche wilde Pokémon erreichen mindestens Referenz minus zehn,
Inseltrainer mindestens die Referenz, ihr Ass mindestens Referenz plus zwei
und stationäre Insellegenden mindestens Referenz plus zwei (höchstens
Level 100). Im NG+ darf das Inselniveau auch nach unten folgen: wilde
Pokémon liegen bei Teamreferenz minus drei, Trainer bei plus zwei, ihre
Asse bei plus vier und Legenden bei plus acht (mit Untergrenzen 2/5/15).
KASCs globaler Schwierigkeitsbonus für Trainer und die
optionale Wildlevel-Skalierung wirken weiterhin zusätzlich. Die Regel
ändert keine Kanto-Begegnungen und nicht das Level bereits wandernder,
über beide Regionen persistierender Latias/Latios. Die Untergrenzen
halten das erste Nachspiel herausfordernd, ohne die frühe NG+-Überfahrt
in einen Level-60-Sprung zu verwandeln. Die 14 Inseltrainer und acht
Turmgegner bieten nach dem ersten Sieg erneute Kämpfe mit dem konfigurierten
KASC-Levelzuwachs und derselben einstellbaren Revachenpause; der feste
Erstpreis bleibt einmalig.

Kapitel 2 ergänzt Inselarchiv und Spiegelzeichen-Rätsel am Kap Kante.
Kapitel 3 ergänzt Linas Rettung mit sichtbarer Begleiterin im Beerenforst;
Kapitel 4 ergänzt das Eisprotokoll und eine begehbare Siegelrekonstruktion.
Kapitel 5 ergänzt die Station GEZEITENLINIE mit Notstromrätsel, echter
Schleuse und einer dreiköpfigen Rettungsgruppe. Kapitel 6 ergänzt vier
Ruinenebenen und eine sichtbare Giratina-Erscheinung. Kapitel 7 ergänzt
Stärke-Kalibrierung, Ankerstationen, lokale Versiegelung und Epilog. Die regionalen Vogelformen bleiben
eine optionale Idee innerhalb der bestehenden Legendenkontinuität. Der gewöhnliche Fangumfang
umfasst jetzt 218 Arten in 23 Lebensräumen; der Musterbusch wurde dafür
in sechs Begegnungsbereiche aufgeteilt.
Die verbindliche Richtung steht in [SEVII_STORY_DE.md](SEVII_STORY_DE.md);
die geprüften bisherigen Fundorte und Vorschläge in
[SEVII_SPECIES_PLAN_DE.md](SEVII_SPECIES_PLAN_DE.md).

## Lokaler Kartenimport

Voraussetzung: Python 3 mit Pillow und die geprüfte deutsche Feuerrot-ROM
BPRD Revision 0 (16 MiB, SHA-1
`18a3758ceeef2c77b315144be2c3910d6f1f69fe`). Im Wurzelverzeichnis dieses
Entwicklungsstands ausführen:

```sh
python3 scripts/import_sevii_bprd.py \
  '/Users/maarten/Downloads/Pokemon - Feuerrote Edition (Germany).gba' \
  --output assets/sevii_local
```

Der Importer prüft die ROM-Identität, dekodiert Karten, Kollisionen,
Paletten, komprimierte Grafiken und Türverbindungen und schreibt
`bundle.json`, lokale Atlanten, Vorschaubilder und `import-report.json`.
Anschließend kompiliert `scripts/build_sevii_habitats.py` den verfassten
Katalog `sevii_habitats.json` zu `habitats.json`: ausschließlich erreichbare
und rückkehrbare Flächen, höchstens zehn Arten pro Begegnungstabelle.
Überfüllte Lebensräume oder fehlende Zielarten brechen den Import ab.
Formatreferenz:
[pret/pokefirered, global.fieldmap.h](https://github.com/pret/pokefirered/blob/master/include/global.fieldmap.h).
Offsets beziehen sich ausschließlich auf die geprüfte deutsche Revision.

Die erzeugten Dateien sind unter `assets/sevii_local/` von Git ausgeschlossen.
Ohne dieses Bundle registriert `sevii_expedition.lua` keine Karten oder Fähre.
ROM und extrahierte Bilddaten gehören nicht in ein Quellcode-Release.

Die Karten nutzen `trueColor`. Im getesteten Client zeigt der Farbmodus
`redpp` die Feuerrot-Paletten; der GBC-Farbmodus färbt die Grafik um.
Optionale Hoenn-Artdateien müssen installiert sein, damit die zugehörigen
neuen Begegnungen freigegeben werden. Der Inhaltsschalter und das Generationsprofil gelten weiter. Die
charakterabhängige Familienbeschränkung sowie Honig-/Dex-Pflicht werden
auf Sevii nach der Liga gezielt umgangen, um die Fanglücken schließen zu können.

## Prüfung

`tests/sevii_expedition_test.lua` prüft gegen die echten nativen Kartenklassen:
Kartenabmessungen, sichere Türankünfte, erreichbare Rückwege, gegenseitige
Kartenverbindungen, versperrte unbekannte Ausgänge, unveränderte M.S.-Anne-
Warps, Champ-Zugang, Untersuchungsfortschritt, erneutes Laden, Begegnungs-
und Grafikfreischaltungen sowie das Fehlen legendärer Fangquellen.
Zusätzlich wird jede importierte Zelle gegen die native Graserkennung
geprüft. Aktueller Stand: **78.549 Prüfungen bestanden**; historische native
Erstläufe unten sind als solche zu lesen. Neuere Einzelbelege stehen in der
Liefercheckliste und den Fachprüfberichten.

Beispiel für einen LuaJIT-Aufruf aus diesem Verzeichnis, mit den jeweiligen
lokalen Engine- und generierten Datenpfaden:

```sh
KASC_ENGINE=/path/to/gen1recomp \
KASC_NATIVE_DATA=/path/to/engine/data/generated \
luajit tests/sevii_expedition_test.lua
```

`tests/sevii_native_driver.lua` läuft im echten LÖVE-Client mit einem
eigenständigen Testprofil. Er überprüft Fähre, Türen, Forschungsdialoge,
Speichern/Laden, SURFER und einen kontrollierten Wingull-Fang. Die Reise
zwischen Messpunkten wird teilweise per Test-Teleport vorbereitet; das ist
kein Nachweis eines vollständig ohne Hilfsmittel durchgespielten Rundwegs.
Die Geometrieprüfung ergänzt dafür die Weg-Erreichbarkeit.

`scripts/audit_sevii_geometry.py` baut unabhängig vom Runtime-Modul einen
gerichteten Zellgraphen für alle Inseln auf. Er berücksichtigt Wasser,
Sprungkanten, erzwungene Türen, Kartenränder und beide Möglichkeiten auf
dünnem Eis. Er prüft mögliche Wege; nicht jede Reihenfolge des Eisrätsels.
Reine Wand-/Meer-Kulissen werden gesondert ausgewiesen. Ergebnis:
278 aktive Türen, 31.939 begehbare Zellen, keine gestrandeten oder
unerreichbaren aktiven Türen und keine unerreichbaren Gebiete mit Landfläche.

```sh
python3 scripts/audit_sevii_geometry.py assets/sevii_local/bundle.json \
  --report assets/sevii_local/geometry-audit.json
```

Abgeschlossener nativer Prüflauf: Profil `kasc-sevii-qa-20260928-v8`,
Exitcode 0, Abschlussmarke
`SEVII_NATIVE_SEVEN_FERRIES_STORY_SAVE_SURF_CAPTURE_ICE_PASS` in `native-v8.log`.
Wingull wurde mit seinen tatsächlichen Artgrafiken dargestellt und im
nativen Fangsystem gefangen; der Besitz wurde im Pokédex geprüft.
Zusätzlich wurden alle sieben Häfen angefahren und verlassen, eine
Sprungkante benutzt und eine Eiskachel zweimal betreten: erster Schritt
zeichnet einen Riss, zweiter Schritt führt ins Untergeschoss. Das Eis friert
beim Verlassen dieses Geschosses wieder zu. Screenshots dokumentieren
alle Inselankünfte und die Landung nach dem Eisfall.

Lokaler Prüfstand:
`/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/`.
Die Engine-Basis liegt bei `e64f6ff6`; getestet wird Rot, nicht Blau, Gelb
oder eine 3D-Ansicht. Die optionalen Bilder im Prüfstand wurden ausschließlich
bei passender SHA-256 aus dem lokalen Altbestand eingebunden. Sie verändern
den Quellcode-Arbeitsstand nicht.

## Fangorte und Generationsfortschritt

`sevii_encounters.lua` löst Nationaldex-Schlüssel über das kanonische
Backend auf. Private HEVO-Dexnummern dienen ausschließlich ihrem bestehenden
Grafikregister. Fehlende Art- oder passende klassische Kampfgrafiken sperren
die betreffende Begegnung. Das verhindert auch den beobachteten Rückfall
von Chelast auf eine gepolsterte, falsch positionierte Altgrafik.

In AUTO schaltet Maras Forschungsbeginn Gen 3 frei; beide Messungen und
der Abschlussbericht schalten Gen 4 frei. Ein ausdrücklich gewähltes
Generationsprofil hat weiter Vorrang. Dafür sind weder Hoenn-Besitz noch
Honig oder ein bestimmter Charakter-Wandertrainer nötig.

`tests/sevii_habitats_test.lua`: 22.099 Prüfungen, sämtliche 218 Ziele über
alle 256 nativen Zufallswerte abgedeckt, Rot/Grün/Blau-Lücken geschlossen,
keine fremden Zufallsersetzungen und kein Fang auf grasfreien Außenwegen.
Die Bilddateien in diesem Unit-Test sind Platzhalter der Prüfumgebung;
der separate native Test nutzt die tatsächlichen Grafikdateien.

`tests/sevii_native_catalog_driver.lua` prüft echte Artregistrierungen,
Lernsets und AUTO/manuelle Generationsprofile. Der anfängliche Grafik-Audit
musste um die klassischen Kampfbilder bereits vorhandener Arten erweitert
werden. Die zusätzlichen Dateien im QA-Paket wurden gegen ihre hinterlegten
SHA-256 geprüft (`sevii-extra-art-receipt.json`, `sevii-classic-art-receipt.json`).

`tests/sevii_native_capture_driver.lua` prüft jede Art über ihre verfasste
Begegnungstabelle und die aktive Mod-Hookkette, echten Kampf, Fangdialog,
Party/PC-Aufbewahrung sowie Speichern/Laden. Test-Teleports und kontrollierter
Zufall ersetzen dabei keinen vollständigen Rundweg zu Fuß. Screenshots
entstehen erst nach Ablauf der Einblendung. Ergebnis: 218/218 Fänge und sämtliche gespeicherten Identitäten in
Party/PC wiedergefunden; `captures-native.json`, `captures-all.log`.

Der zusätzliche physische Lauf-Test entdeckte einen Fehler, den der direkte
Aufruf der Begegnungstabellen nicht zeigen konnte: Die native Klasse
`Map.isGrassCell` berücksichtigt nur einen `grassTile`, importierte Atlanten
besitzen aber mehrere Grasbilder. `sevii_expedition.lua` erkennt nun für
seine eigenen Karten sämtliche importierten Graskacheln; andere Karten
verwenden weiterhin ihre native Prüfung.
`tests/sevii_native_walking_encounters_driver.lua` kontrolliert nur den
Zufall innerhalb des nativen Würfelvorgangs. Der Spieler geht tatsächlich
auf die Zielfläche; `onStepComplete` wählt das Gelände und öffnet den Kampf.
Ergebnis: **84/84 Tabellen** über Gehschritte geprüft, Gras, Wasser und
Innenräume (`walking-all.log`, `walking-all.json`, Exitcode 0).
Test-Teleports stellen die Ausgangspositionen bereit; das ist weiterhin
kein vollständiger Rundweg zwischen sämtlichen Lebensräumen.

`sevii_guide.lua` zeigt an allen sieben Häfen die tatsächlichen Arten,
Gebiete, Himmelsrichtungen, Geländearten, Level und Zugangsvoraussetzungen.
Arten mit fehlenden Grafiken oder gesperrtem Profil bleiben mit Erklärung
auffindbar. Keine internen Karten-IDs erscheinen in den Beschreibungen.

## Zweites Kapitel und native Spieloberfläche

`sevii_chapters.lua` erweitert den bestehenden Zustand um `chapters.two`.
Der Archivar im Inselarchiv auf Eiland Zwei erklärt das Lied; ein Stein am
östlichen Ufer des oberen Kap-Beckens fragt die gespiegelte Zeichenfolge
ab. Falsche Antworten und Abbrechen verbrauchen nichts. Der Bericht im
Archiv speichert `chapterTwoComplete`, ohne Maras alte Fortschrittsbelege
oder die Generationsfreischaltung zu überschreiben.

`chapter-two-native.log`: tatsächliche NPC-Dialoge, falsche Antwort,
Abbruch, richtige Lösung, Abschluss und zweimaliges Speichern/Laden,
`SEVII_NATIVE_CHAPTER_TWO_PASS`. Die Spiegelerscheinung ist bisher erzählt;
eine sichtbare Zerrwelt-Animation bleibt offen.

`guide-native4.log`: sieben tatsächliche Hafengespräche, alle 218
Arteneinträge, Detailansicht und Rückkehr zur zuvor gewählten Art,
`SEVII_NATIVE_GUIDE_PASS`. Die Detailansicht nutzt die vorhandene
Fullscreen-Hilfe; eine normale Textbox über einer breiten Liste würde den
Hintergrund falsch skalieren. Bildprüfung: `guide-turtwig.png`.

Die 906 bereits vorhandenen HEVO-Animationsdateien mussten im QA-Overlay
als tatsächliche Dateien bereitgestellt werden: LÖVE meldet Symlinks als
`type=symlink,size=0`, der vorhandene schnelle Animationsscan akzeptiert nur
Dateien. Prüfsummen: `sevii-hevo-materialized-receipt.json`. Das ist eine
Eigenschaft des Entwicklungsprüfstands und muss im Paketbau berücksichtigt
werden. Ein vollständiger Nachtest aller 19 HEVO-Arten ist bestanden.

`crystal_animation.lua` begrenzt zusätzlich die vertikale Verschiebung
registrierter Crystal-Gäste: vollständige native Karten bis 56 Pixel Höhe
bleiben zwischen Bildschirmoberkante und Spielername sichtbar. Die bisherige
Johto-Regel gilt dadurch auch für HEVO. Externe Arten, skalierte Pixelkarten,
Kanto und große Grafikquellen behalten ihre eigenen Regeln. 298 gezielte
Geometrieprüfungen in `tests/sevii_crystal_clearance_test.lua` bestehen.
Nach der Korrektur bestätigt `captures-hevo-bounds.log` 19/19 erneute
native Fänge, vollständige Bildgrenzen und tatsächliches Speichern/Laden.

## Waldrettung und Eisprotokoll

`sevii_forest_rescue.lua` ergänzt `chapters.three`. LINA wartet in der
nordwestlichen Lichtung, folgt nach dem Gespräch als native, passierbare
Begleiterin und verlässt die Gruppe am südlichen Waldtor. Der Bericht in
ihrem Haus beendet Kapitel 3. Nach Flucht, Ortswechsel oder Trennung kann
die Rettung erneut begonnen werden; frühere Beobachtungen bleiben erhalten.
Der bestehende Pokémon-Begleiter wird nicht umgestellt.

`tests/sevii_forest_rescue_test.lua`: 27 Prüfungen. Der native Test
`forest-native2.log` besteht mit 146 physischen Schritten über fünf
Kartenfragmente und 145 Begleiterprüfungen. Er enthält Unterbrechung,
Neubeginn, tatsächliches Speichern/Laden auf dem Rückweg und den Hausdialog.

`sevii_ice_memory.lua` ergänzt `chapters.four`. HAGEN steht am Höhleneingang,
die Aktenkapsel im westlichen Untergeschoss. Nach dem Lesen beginnt die
Siegelrekonstruktion am südlichen Feld des Ankersteins in der hinteren
Kammer. Acht tatsächliche Schritte zeichnen einen geschlossenen Ring;
Abweichungen und Verlassen der Kammer setzen nur den Versuch zurück.
Der Bericht bei Hagen speichert `chapterFourComplete`. Die Rekonstruktion
setzt weder den Finale-Zustand noch einen Giratina-Sieg oder -Fang.

Der Kartenimport ab Revision 4 ergänzt die Originalgrafik für gesprungenes
Eis und erzeugt alle benötigten Blockvarianten. Die Kollision bleibt in
jeder Variante gleich. Die Speicherdaten steuern das tatsächlich gerenderte
Blockbild: Risse auf der ersten Eisebene, Fortschritt auf den acht markierten
Feldern in der hinteren Kammer. Beim Wiederbetreten der ersten Eisebene
friert das Eis wieder zu. Die acht Ringfelder und ihre Zugänge sind für
sichtbare Wildbegegnungen reserviert, damit keine zufällige Figur den
vorgeschriebenen Weg blockiert.

`tests/sevii_ice_memory_test.lua`: 181 Prüfungen einschließlich Voraussetzungen,
Abbruch, Wiederholung, Zwischenstand und identischer Variantkollision.
`ice-native1.log`, Exitcode 0: sichtbarer Riss, Speichern/Laden, echter Fall,
Weg zur Aktenkapsel, Wiederzufrieren, falscher Weg, Kammerwechsel, acht
richtige Gehschritte, erneutes Laden mitten im Rätsel und Abschlussdialog.
Visuell geprüft: `ice-cracked.png`, `chapter-four-trace.png` und
`chapter-four-seal.png`. Die Zerrwelt-Erscheinung ist noch Dialogtext;
eine eigenständige sichtbare Inszenierung folgt in den späteren Kapiteln.

## Verlorene Station

`sevii_station.lua` ergänzt `chapters.five`. NOAH erklärt die drei Einheiten
Notstrom. Zuerst muss die Sonde abgetrennt werden; dann versorgen zwei
Einheiten die Belüftung und eine die Schleuse. Der Funk braucht ebenfalls
zwei Einheiten. Überlast wird ohne Verlust der vorhandenen Einstellung
abgewiesen. Die Konsole verwendet eine eigene Stationsliste mit
Verbraucherhilfe; sie wird nicht als Item-Beutel dargestellt.

Der Import ab Revision 5 erzeugt eine geschlossene und offene Variante der
Schleusenzelle (22,8). Ihre native Kollision sperrt beziehungsweise öffnet
den Zugang zum nordöstlichen Raum. Ein Notriegel auf der Innenseite lässt
Spieler mit älteren Speicherständen wieder heraus; er vergibt weder
Strom noch Questfortschritt. Das Grundlayout des Imports bleibt für den
allgemeinen Wegeaudit offen. Der geschlossene Zustand wird zusätzlich durch
Unit-Test und tatsächliches Anlaufen der Schleuse im Client geprüft.

ADA, RORY und JUROB folgen dem Spieler als drei passierbare native Figuren.
Die Gruppe stellt die vorherigen Schritte nach; die Auswahl des eigenen
Pokémon-Begleiters bleibt erhalten. Beim Verlassen der Station vor der
Rettung kehren die drei in den Nordraum zurück. Stromverteilung und
Sondenabschaltung bleiben gespeichert. Am Sammelplatz müssen alle drei den
Gang verlassen haben; erst dann wird die Rettung anerkannt und die Gruppe
steht sichtbar beim Eingang. Danach kann die Belüftung abgeschaltet und der
Funk eingeschaltet werden. Maras Gespräch speichert `chapterFiveComplete`.

Rory stammt aus Sinnoh. Der Nutzer hat Galar als Beispiel für die regionalen
Formen der drei Vögel präzisiert; eine Galar-Pflicht für diese Stationsgeschichte
wurde entfernt. Der Funkbericht identifiziert die Zerrwelt, noch nicht
Giratina, und verweist auf das Ruinental auf Eiland Sechs.

`tests/sevii_station_test.lua`: 49 Prüfungen einschließlich eines 26-Schritt-
Rückwegs mit insgesamt 72 Begleiterschritten im isolierten Modell.
`station-native5.log`, Exitcode 0: tatsächliche NPC-Gespräche und Menüeingaben,
geschlossene Schleuse, Notausgang, Überlast, native Rettungsgruppe, Trennung,
Wiederholung, Speichern/Laden während der Begleitung und Funkabschluss.
Bei einem Speichern mitten in einer Schrittanimation wird die tatsächlich
angesteuerte nächste Zelle wiederhergestellt; Unterkachel-Animationszeit
ist kein gespeicherter Questzustand. Vor dem Laden prüft der native Test,
dass dieser gespeicherte Zielpunkt dem echten NPC-Schrittziel entspricht.
Bilder: `station-gate-closed.png`, `station-evacuation.png`,
`station-assembly.png`, `station-power-rescue.png`, `station-power-radio.png`.
Der zusätzliche UI-Prüflauf `station-ui.log` besteht mit Stationsüberschrift,
Verbraucherhilfe und Rückkehr ins Spiel. `station-console-final.png` zeigt
die eigenständige Konsole statt des Beutel-Skins.

## Bekannte Grenzen

- Der native Gesamtlauf v8 besteht auch mit aktiviertem Wilds. Dabei wurde
  für einzelne Backend-Arten (beispielsweise Rexblisar) eine fehlende
  vorregistrierte Oberweltgrafik gemeldet. Kampfgrafik und Fang funktionieren.
  Die Wilds-Registrierung läuft vor den späteren Backend-Artregistrierungen;
  zugleich besitzt `wilds_compat.lua` bereits eine Nationaldex-Auflösung für
  die Laufzeit. Die Warnung allein beweist deshalb noch keinen tatsächlich
  gezeichneten Ersatz. Vor dem Paket sind die realen sichtbaren Figuren und
  ihre endgültige Grafikquelle zu prüfen und nötigenfalls zu korrigieren.

- Wasser und andere GBA-Tileanimationen sind im ersten Import statisch.
- GBA-Grafikebenen sind zusammengeführt; spezielle Höhenüberlagerungen
  und Brücken benötigen einen späteren gezielten Ausbau.
- Gerichtete Sprungkanten sind über die native Feld-API umgesetzt.
  Sprungkanten direkt über einer internen Fragmentgrenze benötigen noch
  eine gezielte Prüfung; die aktiven Türwege bestehen bereits das Audit.
- Dünnes Eis besitzt jetzt echte Rissbilder, Falllogik und Wiederzufrieren.
  Feuerrots Gleit-Eis ist noch nicht als automatische Rutschbewegung umgesetzt.
- Zwanzig Bewohner, sieben Versorgungsläden, zwei Beerenläden sowie
  sieben PCs und Journalstellen beleben die Häuser und Zentren. Noch
  fehlen weitere Funktionen; 14 optionale Inseltrainer und acht Turmetagen
  mit Preisen, Fortschritt und Dachabschluss sind vorhanden.
- Der ausgegrabene Insel-Tunnel verwendet das echte Post-Liga-Layout.
  Der Turmaufzug führt zurück zur Lobby; unbenutzte Warp-Ereignisse außerhalb
  der sichtbaren Stockwerkslayouts bleiben gesperrt.
- Die Inselheilung setzt den bisherigen Kanto-Heilort nicht um. Nach einer
  Niederlage bleibt damit der bestehende Rücksetzpunkt erhalten.
- Vor Entfernen dieses Prototyps mit der Fähre nach Kanto zurückkehren und
  dort speichern. Ein gespeicherter Standort auf einer entfernten Karte
  kann ohne diese Kartendaten nicht weiter geladen werden.
- Aktueller Stand: Alle fangbaren Legenden haben einen eigenen Fangbeleg pro
  Durchlauf. Ein NG+ beginnt die Begegnungskette neu und bewahrt ältere
  Pokémon sowie dauerhafte Besitzbelege.

## Kapitel 6: Punktloch und Giratina

`sevii_ruins.lua` ergänzt `chapters.six`. Iona steht im Punktloch-Eingang,
je ein Inschriftenstein auf den vier Unterebenen und der Grenzstein in der
tiefsten Kammer. Alle sechs Objektzellen werden durch `S.walkable` geprüft
und vom vorhandenen Spawn-Schutz reserviert. Einstieg verlangt Ligaabschluss
und `chapterFiveComplete`.

`S.onStep` meldet tatsächlich betretene Kartenübergänge über
`chapters.beforeWarp`. Die Sequenz N/W/O/S benötigt die jeweilige gelesene
Inschrift; falsche Abzweige und Verlassen setzen nur die laufende Wegtiefe
zurück. Geladene Zwischenstände bleiben nur auf der dazugehörigen Ebene
gültig. Rückwege bleiben offen.

`sevii_apparition.lua` zeigt eine eigene Stack-Szene mit drei bestätigten
Phasen, ruhiger Portalbewegung und bestehender kanonischer Giratina-Grafik.
Die Szene nutzt keine Kampf-, Geschenk-, Fang- oder Pokédex-API. Erst nach
dem dritten Bild werden `witnessed`, `identity=GIRATINA` und
`boundaryCopied` gespeichert. Fehlende oder unlesbare Grafik gewährt keinen
Fortschritt und erlaubt Wiederholung nach Reparatur. Ionas anschließender
Bericht setzt `chapterSixComplete`; kein Finale-/Fangzustand wird gesetzt.

Grafik: `assets/non_crystal_pixel_2d_67/gen2ified/front/487.png`, SHA-256
`27c91300dad039b7fba69c166edff803b1afafec843458361a22126309f777f7`.
Im QA-Overlay als echte Datei mit `sevii-giratina-art-receipt.json`
nachgewiesen; muss in das spätere lokale Paket aufgenommen werden.

`tests/sevii_ruins_test.lua`: 30 Prüfungen zu Gates, Weg, Serialisierung,
fehlender Grafik, Abschluss und Abbruch. Der native Treiber geht tatsächlich
durch vier Ebenen, probiert einen falschen Weg, lädt mitten im Rätsel und
nach der Szene, prüft die Seitentür und läuft alle vier Ebenen zurück.
`ruins-native2.log` besteht; Bildprüfung entdeckte danach die geerbte
Kartenpalette. Die Szene besitzt deshalb eine eigene True-Color-Zone und
helle Textleisten. `ruins-native3.log`, Exitcode 0, wiederholt den vollständigen
Durchlauf mit dieser Korrektur. `ruins-apparition-2.png` wurde visuell geprüft:
Giratina in korrekten Farben, lesbarer Titel und Weiter-Hinweis.

Der gemeinsame QA-Weghelfer unterstützt jetzt optional `extraWarpAt`, damit
er skriptgesteuerte Sevii-Löcher ebenso wie native Türen umgeht. Dies betrifft
nur Testnavigation, nicht das Laufzeitverhalten der Karten.

## Kapitel 7: Kalibrierung, Versiegelung und Nachspiel

`sevii_finale.lua` ergänzt `chapters.seven`. Selmas Feldlager steht im
Canyon-Haus; die Kalibrierung verwendet die echte Tanoby-Schlüsselkarte.
Importrevision 6 ersetzt die sieben ungenutzten Originalmarkierungen durch
drei Mulden bei (5,4), (7,4), (9,4). Die Kollisionsgeometrie bleibt gleich.
Drei echte native `SPRITE_BOULDER`-Objekte beginnen bei (6,8), (7,9), (8,8).
Das Rätsel ist mit 63 Bewegungen und 19 Schüben lösbar.

Normale Sevii-Storyobjekte sind explizit `pushable=false`, damit Stärke
Inschriften und Anker nicht aus ihren Interaktionspositionen verschiebt.
Nur die Finale-Kalibriersteine werden nach Liga, Kapitel 6 und Campbriefing
beweglich. Die Hebehilfe schaltet die native `strengthActive`-Funktion für
den Kartenbesuch ein; Kollision, Schubanimation und Ereignis stammen aus
der Engine. `onBoulderMoved` speichert alle drei tatsächlichen Positionen.
Laden rekonstruiert sie; Zurücksetzen stellt Steine und sichere Startposition
wieder her. Abgeschlossene Kalibrierung verriegelt die drei Steine.

`game.ready` kann vor der ersten geladenen Karte eintreten. Die Installation
prüft deshalb ausdrücklich `overworld.map`, damit der Rekursionsschutz
nicht durch einen verfrühten Zugriff dauerhaft aktiv bleibt. Diese
Startreihenfolge ist in der Modellprüfung abgedeckt.

Die drei Mannschaften erscheinen nach der Kalibrierung in Monean, Dilford
und Viapois. Ihre tatsächlichen Gespräche speichern je einen vorbereiteten
Anker. Das seitliche Pult in Dilford verlangt alle drei.
`sevii_apparition.lua` erhält einen getrennten Finale-Modus mit drei
Bildphasen und eigener True-Color-Zone. Erst nach der letzten bestätigten
Phase entstehen `seviiRiftSealed`, `chapters.seven.sealed`,
`outcome=LOCAL_RIFT_SEALED` und `antagonistRemains=true`. Fehlende Grafik
verhindert Fortschritt und lässt die vorbereiteten Anker bestehen.

Selmas abschließender Bericht setzt `chapterSevenComplete`,
`expeditionComplete`, die im Journal lesbare Auszeichnung und
`futureRiftLead=DISTANT_UNCHARTED_SIGNAL`. Weder Fang noch endgültiger
Giratina-Sieg werden registriert. Bojen und Spiegelstein erhalten ruhige
Nachspieltexte; Begegnungstabellen bleiben unverändert.

Prüfungen:
- `sevii_finale_test.lua`: 286 Prüfungen, 63 Bewegungen, 19 modellierte
  Schübe, falsche Vorbedingungen, sichere Rücksetzung, Serialisierung,
  Szenenabschluss, Idempotenz und Erhalt früherer Daten.
- `finale-native4.log`, Exitcode 0: echte Schübe mit Kollision/Animation,
  Rücksetzen, erneute Hebehilfe nach Laden, drei reale Ankerdialoge,
  Siegelszene, Epilog, erneutes Laden und ruhiger Bojentext. Alle
  Sevii-Begegnungstabellen vor/nach Versiegelung identisch. Dieser Test
  isoliert Kapitel 7 mit einem Kapitel-6-Fixture und Teleports zwischen
  getrennten Schauplätzen; er belegt keinen gesamten Reisepfad.
- `aftermath-native1.log`, Exitcode 0: Spiegelstein und Ruinenanker
  widerstehen nativer Stärke; deutsche Finale-Beschriftung gerendert.
- `finale-calibration-complete.png`, `finale-seal-2.png`,
  `finale-seal-3.png` und `finale-de-3.png` visuell geprüft.
- Import-/Wegeaudit weiterhin 266 Karten, 278 Türen, 31.939 Zellen;
  Habitat-Kompilierung weiterhin 218 Arten / 84 Tabellen.

Offen bleiben weitere Bevölkerung und Gebäudefunktionen, zusätzliche
Gen-2-/Gen-3-Items, der globale Legendenaudit, zusammenhängende
Charakterdurchläufe und das lokale Paket.


## Bevölkerung, Dienste und erste zusätzliche Items

`sevii_population.lua` registriert 20 feste Bewohner mit Vorher-/Nachhertexten,
sieben native Versorgungsläden, sieben PCs und sieben Forschungsjournalstellen.
Die Gespräche verwenden vorhandene Räume und lassen Türen sowie Story-NPCs frei.
Alle Figuren sind fest; Stärke verschiebt keine Händler oder Bewohner.

Der Quartiermeister in Haus 2 auf Eiland Eins vergibt nach Kapitel 1 fünf
Hyperbälle, nach Kapitel 3 drei Top-Genesungen, nach Kapitel 5 fünf Top-Schutz
und nach dem Epilog drei Sonderbonbons. `Bag.add` muss das gesamte Paket
annehmen, bevor `population.rewards[id]` gesetzt wird. Bei vollem Beutel kann
die Lieferung später abgeholt werden; der gespeicherte Beleg verhindert Duplikate.

Die Beerenhändler in `ThreeIsland_House3` und `SixIsland_WaterPath_House2`
verwenden den nativen `ShopMenu`-Ablauf. Zehn Johto- und fünfzehn Hoenn-Beeren
werden nach aktivem Generationsprofil und bestätigter Effektbereitschaft gefiltert.
Itemdefinitionen, Wirkungen und Preise bleiben bei ihren bisherigen Modulen.
Der weitergehende Item-Auftrag ist in `SEVII_ITEM_PLAN_DE.md` festgehalten.

Prüfung: `sevii_population_test.lua` besteht 40 Prüfungen (einschließlich
nativer Sprite-IDs, voller Beutel, Wiederholung und ungeeigneter Gen-Profile).
`population-native3.log` besteht Käufe, sieben PCs und Journalstellen,
40 Bewohnergespräche, Belohnungsabholung und Speichern/Laden. Eine gekaufte
Lydzibeere wurde im nativen Ausrüstungsmenü getragen und in einer echten
Kampfrunde mit Angriff +1 verbraucht; der Verbrauch übersteht erneutes Laden.
Die gerenderten Bilder `sevii-pc-storage.png` und `sevii-hoenn-berry-shop.png`
sind visuell geprüft. Der native Item-Abgleich ist auf registrierte Identitäten
und benannte Quellen begrenzt; er beweist keine globale Unerhältlichkeit.


## Vierzehn freiwillige Inseltrainer

`sevii_trainers.lua` ergänzt zwei Trainer pro Insel, mit drei Pokémon und
Leveln von 60 bis 72. Explizite Gen-1–4-Profile erhalten vollständige,
thematisch passende Teamvarianten; höhere Profile verwenden die Gen-4-Teams.
Die kanonischen Arten werden beim Start aus dem vorhandenen Backend aufgelöst.
Kein Trainer verwendet legendäre Pokémon. Ein fehlender Art-Datensatz blockiert
den Start, statt einen fremden Ersatz still einzusetzen.

Jede Figur besitzt eine eigene Trainerklasse mit vorhandenem Porträt und
nativer KI. Ein nur während des Konstruktors aktiver `trainer.party`-Hook
liefert die passende Mannschaft; keine fremde Partyregistrierung wird verändert.
Der normale Engine-Kampf verantwortet Schaden, EP, Preisgeld und Niederlage.
Die Sieg- und Itembelege liegen unter `sevii_expedition_v1.trainers[id]`.
Ein Sieg beendet die einmalige Herausforderung. Voller Beutel oder ungeeignetes
Profil lassen die Itembelohnung für spätere Abholung beim Trainer bestehen.
Doppelte Abschluss-Callbacks lösen keine zweite Auszahlung oder Rückkehr aus.

Kampfstart erfordert Liga-Sieg, unmittelbare Nähe, freie Oberwelt und ein
kampffähiges Pokémon. Die Einladung zeigt die Levelspanne; Absagen und
Abbrechen geben die Steuerung frei. Die Figuren stehen auf Land mit vier
begehbaren Nachbarzellen, nicht auf einem Türfeld. Der native Checkpoint-Schutz
lehnt Zwischenspeichern dieser eigenen Abschlussabläufe ab; vor und nach dem
Kampf funktioniert normales Speichern. Kein unvollständiger Abschluss wird
als rekonstruierbarer Standard-Trainerkampf ausgegeben.

`trainers-native2.log` besteht 14 echte Siegabläufe und einen normalen
Blackout. Der erste Sieg verwendet unveränderte Gegner-KP; die übrigen 13
setzen nach Prüfung der drei Arten und Level die Gegner-KP für den Ablaufcheck
herab. Das ist kein Schwierigkeits- oder Gesamtreisenachweis. Alle 14 Items,
volle Tasche, spätere Abholung, Wiederholung, doppelte Callbacks und erneutes
Laden sind geprüft. `trainer-profiles-native3.log` prüft 168 Slots unter
Gen 1–4 ohne nicht implementierte Attacken-Platzhalter, eine zunächst
zurückgestellte Belohnung nach Profilwechsel und das Laden nach einem
abgebrochenen Kampf ohne verwaiste Kampfsperre.
`sevii-trainer-mira.png` und `sevii-trainer-challenge.png` wurden gerendert
und visuell geprüft. Die Integrationsprüfung besteht 78.256 Prüfungen.


## Giratina-Sperre und zusätzliche Itemquellen

`sevii_legend_policy.lua` schützt beide Giratina-Formen vor neuen
Geschenkausgaben und Fangversuchen. Die sechs vorhandenen Geschenkprofile
bleiben als Herkunft alter Pokémon erhalten. Offene Belege werden sicher
zurückgestellt; andere Codes funktionieren weiter. `legend-policy-native3.log`
prüft auch Speicherausfall und Altbesitz. Details und Rücknahmegrenzen stehen
in `SEVII_LEGEND_AUDIT_DE.md`; die später ergänzte NG+-Regel erlaubt
genau einen Fang jeder fangbaren Legende pro Durchlauf.

Die eigenen Trainer referenzieren nur tatsächlich registrierte `ai_classes`.
Fehlt zur Portraitklasse ein solches Objekt, bleiben die drei gewöhnlichen
KI-Schichten aktiv. Der native Lauf meldet keine ungelösten Sevii-KI-Verweise.

`sevii_population.lua` ergänzt einen Aprikokoballhändler in Haus 1 auf
Eiland Drei und sechs einmalige Naturfunde. Die Bälle verwenden unverändert
ihren vorhandenen Wirkungsbesitzer. Fundbelege werden erst nach erfolgreichem
`Bag.add` gespeichert. Alle sechs Fund-/Verkaufswege und ein gekaufter
Freundesball im tatsächlichen Fangablauf bestehen `finds-native3.log`.
Die Fang-Zufallswerte und Reisen sind Test-Fixtures. Integration: 78.270
Prüfungen; Bevölkerung: 73 Prüfungen. Die feste Gen-2-/Gen-3-Itemabdeckung
stieg zunächst auf 46 registrierte Identitäten, ohne Vollständigkeit zu behaupten.


## Trainerturm: acht Etagen und Dachabschluss

`sevii_tower.lua` ergänzt acht Trainer auf den vorhandenen Turmkarten.
`sevii_trainers.lua` stellt dafür den gemeinsamen nativen Kampfbesitzer
über `T.register` bereit. Die 14 bisherigen Inseltrainer bleiben in
`T.rows`; `T.allRows` enthält alle 22. `requiredId` sperrt höhere Kämpfe,
bis die vorige Etage gewonnen wurde. Jede Etage hat drei Pokémon und eine
passende Variante für explizite Gen-1–4-Profile. Keine Legenden im Team.

Siege und Preise bleiben in `trainers[id]` gespeichert. Es gibt keinen
Verlust bereits gewonnener Etagen bei Niederlage, Heilpause oder Laden.
Ein volles Inventar lässt den jeweiligen Preis reserviert. Auf dem Dach
vermerkt die Protokollantin nach acht Siegen `towerComplete`; der Titel ist
anschließend im Expeditionsjournal sichtbar. Das Titelgespräch ist idempotent.
Die Lobby erläutert Regeln und zeigt Siege/offene Preise.

`tower-native2.log` besteht acht Kämpfe mit vollständigen Gegner-KP, eine
normale Niederlage, Sperre der zweiten Etage vor dem ersten Sieg, echten
Auf- und Abstieg über die Treppen, Speichern auf Etage 4, spätere Preisabholung,
Dachabschluss, erneutes Laden und den Ausgang zur Insel. Ein geheiltes
Level-100-Team vor jedem Kampf und feste Zufallswerte sind QA-Fixtures;
das ist kein Beweis einer ausgewogenen Schwierigkeit für normale Teams.
`trainer-profiles-native4.log` prüft 264 Teamslots über 22 Trainer/Gen 1–4;
keine nicht implementierten Platzhalterattacken. `tower-ui2.log` prüft den
sichtbaren Journaltitel und die eigene Menüüberschrift. Integration: 78.291
Prüfungen. Die acht zusätzlichen Preise erhöhen die festen Itemquellen
auf insgesamt 54 registrierte Gen-2-/Gen-3-Identitäten.


## Eigenständiges privates Entwicklungspaket

`scripts/build_sevii_package.py` erzeugt aus der geprüften lokalen Laufzeit
nur in einem **neuen** Ausgabeordner ein materialisiertes Mod-Paket.
Es kontrolliert die aktuellen Lua-Module sowie die unabhängig erfassten
gewöhnlichen und besonderen Artgrafiken. Anschließend werden alle Dateien
kopiert und mit SHA-256 inventarisiert. Weder Spielstände noch ROM-Dateien
werden aufgenommen; bestehende Installationen werden nicht geändert.

```sh
python3 scripts/build_sevii_package.py \
  --runtime /path/to/qa-engine/mods/kanto_ascendant \
  --asset-evidence /path/to/qa/asset-hashes.json \
  --output /path/to/new-sevii-development-package
python3 scripts/build_sevii_package.py \
  --verify-only --output /path/to/new-sevii-development-package
```

`--zip` erstellt optional nach erfolgreicher Prüfung ein zusätzliches ZIP.
Das Paket enthält den Mod, nicht die Engine. Die ROM-abgeleiteten Inselkarten
sind ausschließlich das lokale Importergebnis; dies ist kein öffentliches
Quellcode- oder Grafikrelease. Dateien sind tatsächlich enthalten und hängen
nicht mehr an Symlinks zum Arbeitszweig oder Artcache.

Der erste materialisierte Stand `package-dev1` enthält 48.633 inventarisierte
Dateien mit 339.863.753 Bytes Nutzdaten. `package-manifest.json` bleibt
bewusst auf `status=development` und `releaseReady=false`. Diese Felder werden
nicht durch bestandene Hash-Prüfungen automatisch zu einer Inhaltsfreigabe.
Die Paketkopie wird gegen eigene native Testprofile geprüft; Spielstände der
Benutzerinstallation werden nicht benutzt. Sechs Prüfungen belegen das
Ablehnen veränderter, fehlender oder zusätzlicher Dateien, externer Links,
ROM-/Save-Dateien und unsicherer Pfade.

## Nach dem ersten Entwicklungspaket ergänzt

Die fünf ursprünglichen Hoenn-Legenden Kyogre, Groudon, Rayquaza, Deoxys
und Jirachi besitzen gemeinsame dauerhafte Besitzbelege und zusätzlich
Fangbelege für den aktuellen Durchlauf. Wetterlegenden und Jirachi haben
ihre verlegten Sevii-Orte; Deoxys bleibt auf der Entstehungsinsel.
Getrennte Forschungsbestätigungen halten die Abschlusskette auch bei
bereits erhaltenen Pokémon offen, ohne einen Fang vorzutäuschen.
Ein NG+ erlaubt nach erneuten Voraussetzungen wieder je einen Fang;
Details in `SEVII_LEGEND_AUDIT_DE.md`.

Schwarze und weiße Flöte ergänzen den Händler auf Eiland Eins. Der neue
Ratenadapter `sevii_field_flutes.lua` beeinflusst normale Zufallsbegegnungen
im aktuellen Gebiet und bewahrt die gespeicherten Wandererorte mit ihrer
eigenen 5-Prozent-Probe. Kauf, Beutel, physischer Schrittvergleich, Laden,
Gebietswechsel und tatsächliche Wanderer-Hookkette sind nativ geprüft.
Der aktuelle Itemabgleich enthält 76 feste Quellen und 30 Itemeffekte.
Das eingefrorene ZIP `package-dev1` enthält diese späteren Änderungen nicht.

Die Gluttherme besitzt jetzt einen freiwilligen Rastdienst. Die Pension auf
Eiland Vier öffnet den vorhandenen KASC-Pensionsbesitzer mit lokalem Titel;
Eltern, Eier, Training und Gebühren bleiben mit Route 5 gemeinsam. Beide
Gebäude sind samt Vor-Liga-Sperre, Dialogen und Speichern/Laden im Client
geprüft. Der erste Vergleich aller 22 Trainer mit gewöhnlichen Teams und
unverändertem Kampfzufall ist bestanden. Seine konkreten Grenzen stehen in
`SEVII_PLAYABILITY_QA_DE.md`; ein Level-100-Test wird dafür nicht herangezogen.
