# Eigenständiges Sevii-Testpaket – noch keine Inhaltsfreigabe

Die nach dev26 begonnene Doppelkampf-Arbeit an vier Voxel-Fußpunkten,
getrennten Sprite-Texturen und drei vermessenen Sevii-Bühnen ist nur in
den Entwicklungsquellbäumen. Sie ist nicht Teil des
dev26-Testpakets und schaltet dort keine Doppelkämpfe frei.

## Aktueller Entwicklungsstand dev26 (01.10.2026)

`package-dev26.zip` ergänzt 15 prüfbare Gen-3-/Gen-4-Entwicklungsitem-Funde
auf Sevii; jeder Erstfund schaltet bezahlbaren Nachschub bei dem Forscher
auf Eiland Sechs frei. Im NG+ ist sein vollständiges Sortiment sofort
verfügbar, und die Fähre fährt bereits beim ersten Besuch in Orania.
Das Sevii-Level-Scaling folgt im NG+ auch einem jungen Team nach unten.
Die 14 Inseltrainer und acht Turmgegner besitzen Erstkampf, Siegzustand,
einmaligen Erstpreis und KASC-kompatible Rückkämpfe mit Levelzuwachs und
Schrittpause.

Der native Gegenstandslauf fand und kaufte alle 15 Items auf ihren
Inselkarten und bestätigte die Freischaltung nach Speichern/Laden
(`evolution-matrix-native.log`, Exitcode 0). Der native NG+-Lauf prüfte
Frühfähre, niedrige Trainerlevel, direktes Shopsortiment, normalen
Erstfund, Rückkampf und Altspielstand-Migration
(`legacy-access-live9.log`, Exitcode 0). Ein eigener Echtkampf-Lauf
prüfte den Erstkampf und einen höheren Rückkampf (`rematch-live1.log`,
Exitcode 0). Alle 14 regulären Inseltrainer bestanden erneut ihren
Erstkampf (`trainers-evolution-native.log`, Exitcode 0). Alle 34
isolierten Sevii-Lua-Tests bestanden (`unit-dev26.log`). Die
Paketintegrität und der ZIP-CRC wurden nach dem Bau nochmals geprüft: 48.649 Dateien,
344.909.259 Byte Nutzdaten; ZIP-SHA-256:
`3431784b2fcd058831be3921f1769b377c2796a0fd46a04577043e93a1fc8dc7`.

Echte Doppelkämpfe gehören noch nicht zu dev26. Der notwendige
Vier-Battler-/Voxel-Umbau und seine Abnahme stehen in
[SEVII_DOPPELKAMPF_PLAN_DE.md](SEVII_DOPPELKAMPF_PLAN_DE.md).
Die allgemeine Itemvollständigkeit bleibt ebenfalls offen; deshalb trägt
das Paket weiterhin `releaseReady=false`.
Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev26.zip`.

## Vorheriger Entwicklungsstand dev24 (01.10.2026)

`package-dev24.zip` ergänzt das Ende der Expedition um den einmaligen
GS-Ball als Basis-Item. Im tatsächlichen Eich-Labor-Dialog behält der Spieler
den Ball; Eich fragt seine Freundin Professorin Ivy um Rat und bittet um
einen späteren Besuch. Der Spielstand merkt sich diesen Orange-Inseln-Hinweis,
ohne schon eine Reise oder einen weiteren Fang freizuschalten. Ein voller
Basis-Item-Beutel verschiebt die Übergabe: Selma verwahrt den Ball, bis wieder
Platz ist.

Die isolierte Paketkopie bestand den nativen GS-Ball-/Eich-Lauf in Englisch
und mit aktiver deutscher Übersetzung sowie den vollständigen Finalablauf
samt Steinrätsel, Siegel und Nachzustand. Ein mit
einer unveränderten älteren KASC-Basis erzeugter Blau-Spielstand bestand alle
sieben Kapitel bis zur Rückfahrt nach Orania. Rot, Grün und Blau bestanden
aktuelle natürliche Gesamtreisen im vorangehenden dev23, dessen
Finalbelohnung mit dev24 identisch ist. 35 isolierte Lua-Tests und sechs Paket-Integritätstests
bestehen. Das Paketmanifest bestätigt 48.648 Dateien und 344.891.991 Byte;
ZIP-CRC und SHA-256 wurden geprüft (ZIP-SHA-256:
`499bf0f262807835158a0c7905171030824a63a34ce5ec59b39c37dde6340880`).

Ein vollständiger nativer NG+-Menülauf bestand auch den ausdrücklich gewählten
letzten JA-Schritt, die normale Porträt- und Namensfolge und die erneute
Ankunft in Eichs Labor. Historischer Legendenbesitz blieb dabei getrennt vom
neuen Fangrecht. Die dev24-Balanceprobe gewann alle 22 vorgesehenen
Insel- und Turmkämpfe mit einem gewöhnlichen sechsköpfigen Kanto-Team,
voller Gegner-KP, nativer KI und ohne Kampfitems; Anreise und Heilung zwischen
den Kämpfen waren Testvorgaben (`balance-dev24-90232.log`, Exitcode 0).
Die finale Inhaltsfreigabe ist weiterhin offen: Noch nicht
alle vorgesehenen Gen-2-/Gen-3-Items haben eine sinnvolle Quelle und Wirkung.
Das Paket trägt deshalb korrekt `releaseReady=false`. Paket:
`/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev24.zip`.

## Vorheriger Entwicklungsstand dev22 (01.10.2026)

Die vertiefte Selbstprüfung dieses Pakets ist in `SEVII_SELF_AUDIT_DE.md`
festgehalten. Zusätzlich zu den unten genannten Prüfungen bestand ein
zusammenhängender Rot-Durchlauf mit 22 normalen Wildkämpfen und Rückfahrt,
die native Karten-/SELECT-/FLIEGEN-Probe sowie die durchlaufbezogenen
Neufänge aller drei Regis, der drei Wetterlegenden und Jirachis. Der
vollständige NG+-Menüpfad, aktuelle natürliche Gesamtreisen für Grün und
Blau, ein kompletter dev22-Altspielstand-Durchlauf, fehlende Itemwirkungen
und die finale Installations-/Balanceabnahme bleiben offen.

`package-dev22.zip` enthält den durchlaufbezogenen Legendären-Fang und die
eigenständige, abschaltbare KASC-Card **FANGSERIE / CATCH COMBO**. Alte
Legendäre bleiben in Legacy und Bank erhalten; ein neuer Durchlauf kann
nach seinen Voraussetzungen jede fangbare Art einmal erneut fangen.
Die Card zählt Fänge derselben wilden Art und gibt im ASCENDANT-Shiny-Modus
ab 11/21/31 Fängen zusätzliche Würfe nur für diese Art.

Das Paket umfasst 48.648 inventarisierte Dateien und 344.887.336 Byte.
Manifest und SHA-256-Dateiprüfung sowie ZIP-CRC sind bestanden;
ZIP-SHA-256:
`480ad15687bb09c94c5ca089cbddff50b4f05bd4130a1caf3f43e49eea62cb3a`.
Die isolierte Paket-Engine bestand den nativen Legacy-Übergang, die
Fangserien-Card samt Speicherprobe und erneut die Fähren-/Levelprüfung
(`package-dev22-ngplus-native.log`, `package-dev22-shiny-native.log`,
`package-dev22-scaling-native.log`; alle Exitcode 0). 35 isolierte Lua-Tests
und sechs Paket-Integritätstests bestehen. Ein vollständiger normaler
NG+-Menüdurchlauf und die finale Inhaltsfreigabe bleiben offen;
`releaseReady=false`.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev22.zip`

## Vorheriger Entwicklungsstand dev20 (01.10.2026)

`package-dev20.zip` bewahrt Zinks getrennten Spezial-Verteidigungswert auch
in der geprüften Teamkopie für Eichs Legacy-Finale. Der native Lauf aus der
Paketkopie bestätigt Kauf, Zink und Kalzium im Beutel, gezüchtete Pokémon,
Speichern/Laden und Eichs Teamkopie. Der Itemaudit bestätigt weiterhin
89 feste Sevii-Quellen und 34 registrierte Beutelwirkungen unter 190
Gen-2-/Gen-3-Identitäten.

Dateiinventar, SHA-256 und ZIP-CRC sind geprüft; sieben geänderte
Laufzeitmodule stimmen bytegenau mit der Paketkopie überein. Alle 33
isolierten Sevii-Lua-Tests und sechs Paket-Integritätstests bestehen. Das
Paket enthält 48.646 Dateien mit 344.872.905 Bytes Nutzdaten;
ZIP-SHA-256:
`402ab675d7f45521244e2afaf52e740fa31e92036e5c8dd2aa4a0ac251f8b6e3`.
Der vollständige Sieben-Kapitel-Lauf mit Rot aus dev19 sowie die drei
natürlichen Gesamtreisen mit Rot, Grün und Blau aus dev17 bestanden; dev20
änderte danach nur Eichs Legacy-Teamkopie. `releaseReady=false` bleibt
wegen weiterer offener Items und der finalen Balance-/Installationsprüfung.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev20.zip`

## Vorheriger Entwicklungsstand dev19 (01.10.2026)

`package-dev19.zip` ergänzt funktionierendes Zink im Trainingsladen auf
Eiland Sieben. Zink trainiert ab Gen 3 die Spezial-Verteidigung getrennt;
Kalzium erhöht danach weiterhin beide Spezialwerte. Der native Lauf aus
der materialisierten Paketkopie prüft Kauf, beide echten Beutelnutzungen,
Statuswerte, einen gültigen Zuchtbeleg und Speichern/Laden. Der Itemaudit
zählt 89 feste Sevii-Quellen und 34 registrierte Beutelwirkungen unter
190 Gen-2-/Gen-3-Identitäten.

Paketintegrität, ZIP-CRC, alle 33 isolierten Sevii-Lua-Tests und sechs
Paket-Integritätstests bestehen. Das Paket enthält 48.646 Dateien mit
344.872.476 Bytes Nutzdaten; ZIP-SHA-256:
`d704f64fe9b0a633c9f0bb68f10e24e763f10b58897a2b0c0a9b629972440d8f`.
Die sechs geänderten Laufzeitmodule stimmen bytegenau mit der Paketkopie
überein. `releaseReady=false` bleibt wegen der weiteren offenen Items und
der finalen Balance- und Installationsprüfung bestehen.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev19.zip`

## Vorheriger Entwicklungsstand dev17 (01.10.2026)

`package-dev17.zip` enthält den Kanto-Sevii-Dialogabgleich. Der Forscher auf
Zinnober verweist bei installiertem Sevii auf Tanoby statt auf Regirocks
geschlossenes altes Heiligtum; seine Vulkanrückfahrt bleibt nutzbar. Der
Entstehungsinsel-Kapitän beschreibt die tatsächlichen Vulkanmessungen und
drei Risspfade. Ohne Sevii bleibt der alte Kanto-Zweig erhalten. Die
Story- und Legendentabellen wurden für den aktuellen Vertrag berichtigt.

Das Paket enthält 48.645 Dateien mit 344.867.870 Bytes Nutzdaten.
Dateiinventar, SHA-256 und ZIP-CRC sind geprüft; ZIP-SHA-256:
`441a9f1ab71a26f17c7f0ce2ff448517f4594910389a3e4f75d14e98114d8d7d`.
Die beiden geänderten Kanto-Module stimmen bytegenau mit dem Paket überein.
Alle 32 Sevii-Lua-Tests, sechs Paket-Integritätstests und beide Kanto-/Sevii-
Dialogzweige bestehen. Die vollständigen nativen Sieben-Kapitel-Läufe in
Englisch und Deutsch stammen vom vorherigen dev16; die Spiellogik dieser
Kapitel wurde für dev17 nicht geändert. `releaseReady=false` bleibt bestehen.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev17.zip`

## Vorheriger Entwicklungsstand dev16 (30.09.2026)

`package-dev16.zip` enthält das vollständige Dialogreview für beide Spielsprachen und die einheitliche deutsche Schreibweise mit Umlauten. Die Hauptfiguren und Nebenfiguren sprechen kürzer und situationsbezogener; genaue Rätsel- und Wegangaben stehen weiterhin in Notizen und Menüs. `SEVII_DIALOGUE_REVIEW_DE.md` hält die redaktionellen Entscheidungen fest.

Das Paket enthält 48.645 Dateien mit 344.867.387 Bytes Nutzdaten. Dateiinventar, SHA-256 und ZIP-CRC sind geprüft; ZIP-SHA-256: `669329f37a212a22494262981bacf5683da4809cc44f82fb8baa361dc6dcb83a`. Alle 33 Sevii-Lua-Module stimmen bytegenau mit dem Arbeitsstand überein. Die 32 Sevii-Lua-Tests und sechs Paket-Integritätstests bestehen. Zusammenhängende native Sieben-Kapitel-Läufe in Englisch und mit aktivem deutschem Sprachmod erreichten Abschluss und Rückfahrt nach Orania (`dialogue-review/journey-red.json`, `dialogue-review-de16/journey-red.json`). `releaseReady=false` bleibt bestehen.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev16.zip`

## Vorheriger Entwicklungsstand dev14 (30.09.2026)

`package-dev14.zip` enthält die redigierten deutschen und englischen Sevii-Dialoge. Die sieben Hauptkapitel, die optionalen Inselgeschichten, Bewohner und Dienst-NPCs wurden auf Figurenstimme, Spielfluss und Kontinuität geprüft. Genaue Lösungswege bleiben in Notizen und Menüs; gesprochene Questabschluss-Titel entfallen. Einzelheiten: `SEVII_DIALOGUE_REVIEW_DE.md`.

Das Paket enthält 48.645 Dateien mit 344.867.388 Bytes Nutzdaten. Dateiinventar, SHA-256 und ZIP-CRC sind geprüft; ZIP-SHA-256: `df9b83336b20de83f572353c6829d7e1bd59aa0b58c8a6d403f5740ca075b44e`. Alle 32 Sevii-Lua-Tests und sechs Paket-Integritätstests bestehen. Ein nativer Rot-Durchlauf durch alle sieben Kapitel aus dem passenden Quellstand bestand mit Rückkehr nach Orania. Die geänderten 17 Dialogmodule wurden bytegenau mit der materialisierten Paketkopie abgeglichen. `releaseReady=false` bleibt bestehen.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev14.zip`

## Vorheriger Entwicklungsstand dev13 (30.09.2026)

`package-dev13.zip` ergänzt den Flug-Grenzfall: Vor dem reparierten
Funksignal kann man von Sevii aus auch nach einem Wechsel zur Kanto-Karte
nicht per FLIEGEN abreisen. Die jederzeitige Fähre bleibt nutzbar. Nach
Kapitel 5 sind Kanto und die bereits besuchten Inseln per FLIEGEN
erreichbar. Ein nativer Clientlauf prüfte die Sperre vor Kapitel 5 und
anschließend die tatsächliche Fluganimation samt sicherer Landung auf
Eiland Zwei. Die frühe Karte, START und SELECT wurden dabei erneut geprüft.

Das gemeinsame KASC-/Kartenpaket enthält 48.645 Dateien mit 344.873.930
Bytes Nutzdaten. Dateiinventar, SHA-256 und ZIP-CRC sind geprüft;
ZIP-SHA-256: `109c06da63e4589f8c5e04e7bd32237e678b5ddd6b93d830c462a9e5f8ce408f`.
Alle 32 Sevii-Lua-Tests und sechs Paket-Integritätstests bestehen.
Der vollständige Sieben-Kapitel-Lauf und das Altspielstand-Upgrade wurden
zuletzt mit dem materialisierten dev11-Paket durchgeführt und sind für
dev13 noch nicht erneut erfolgt. `releaseReady=false` bleibt bestehen.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev13.zip`

## Vorheriger Entwicklungsstand dev12 (30.09.2026)

`package-dev12.zip` enthält KASC und die neue Kanto-/Sevii-Widescreen-Karte
als zwei getrennte Mod-Ordner. Der originale Kanto-Karten-Mod muss beim
Testen deaktiviert sein. Die Sevii-Karte nutzt einen 1672 × 941 Pixel
großen, wortfreien Bild-Master. Bei der ersten Ankunft auf Eiland Eins
wird die Regionskarte freigeschaltet; START wechselt zwischen Kanto und
Sevii, SELECT zeigt pro Insel eigene Orts- und Storyhinweise. FLIEGEN zu
einem besuchten Eiland öffnet erst das reparierte Funksignal aus Kapitel 5.
Die Fähre nach Orania bleibt unabhängig davon jederzeit verfügbar.

Das Paket enthält 48.645 inventarisierte Dateien mit 344.873.156 Bytes
Nutzdaten. Die Datei-Hashes und das Paket wurden vom Builder geprüft;
ZIP-SHA-256: `6111c8426f35b2749b30c62d9e56777f7a5c4590db2c08a20329892e6d057621`.
Alle 32 Sevii-Lua-Tests und sechs Paket-Integritätstests bestehen.
Der native Quellstand-Test mit KASC 6.7.29-rc.3 und Voxel Ascendant
3.0.0-rc.2 bestätigt sieben Flugpunkte, die gesperrte Karte vor Ankunft,
die sofortige Karte bei Ankunft, SELECT-Infos, START-Wechsel und die
Freischaltung von zwei bereits besuchten Flugzielen nach Kapitel 5.
Bildbelege liegen unter `flight-map-qa/`. Der vollständige Sieben-Kapitel-
Lauf und der Altspielstand-Upgrade-Test wurden zuletzt mit dem
materialisierten dev11-Paket durchgeführt; dev12 wurde dafür noch nicht
erneut vollständig durchgespielt. `releaseReady=false` bleibt bestehen.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev12.zip`

## Vorheriger Entwicklungsstand dev11 (30.09.2026)

`package-dev11.zip` enthält vier zusätzliche einmalige Quellen für
kampffähige Typverstärker. Das unveränderte Jirachi-Türmodell aus dev10
bleibt enthalten. Das Paket umfasst 48.637 Dateien mit 339.919.335 Bytes
Nutzdaten; Inventarhashes und ZIP-CRC sind geprüft. ZIP-SHA-256:
`60b732a7fd100ee7f5a9c67fbadd04c4fbba7c47370ad4939db96ba959e486ea`.
Im passenden Quellstand bestanden alle 31 Sevii-Lua-Tests. Die
materialisierte Kopie bestand einen nativen Lauf über alle 14 einmaligen
Funde samt Anlegen, Laden und
Verkauf der vier neuen Items (`package-dev11-qa/finds/finds.log`) und drei
zusammenhängende Storyreisen mit normalen Zufallsbegegnungen:

| Figur | Wildkämpfe | Center-Besuche | Kapitel | Rückkehr nach Orania |
| --- | ---: | ---: | ---: | --- |
| Rot | 25 | 7 | 7 | ja |
| Grün | 32 | 7 | 7 | ja |
| Blau | 27 | 7 | 7 | ja |

Die 84 Kämpfe und 21 Center-Besuche sind in
`package-dev11-qa/natural/journeys-all-characters.json` mit erfolgreichen
Prozess-Exitcodes dokumentiert. Ein frischer blauer Basisspielstand aus
KASC-Commit `b30cfad48` wurde anschließend von der materialisierten dev11-
Kopie geladen und durch alle sieben Kapitel geführt. Team, Box,
ursprüngliche Items, Geld und Lavados-Beleg blieben erhalten; siehe
`upgrade-dev11/journey-upgrade-blue11.json`. Liga, Startteam und Ausgangsort
sind Test-Fixtures; sichtbare Wildpokémon und freiwillige Trainer sind
nicht Teil der drei Ressourcenreisen. Voxel Ascendant 3.0.0-rc.2 wird
separat benötigt. `releaseReady=false` bleibt bis zur abschließenden
Inhalts- und Balancefreigabe bestehen.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev11.zip`

## Vorheriger Entwicklungsstand dev10 (30.09.2026)

`package-dev10.zip` übernimmt den unten geprüften dev9-Stand und schließt
Jirachis alten Kapitänszugang, sobald die Sevii-Karten installiert sind.
Die Wunschkammer bleibt dann allein über die Konvergenztür der Siegesstraße
erreichbar; ohne Sevii-Import bleibt das alte Verhalten erhalten.
48.637 Dateien, 339.918.207 Bytes Nutzdaten, vollständige SHA-256-Inventur
und ZIP-CRC sind geprüft. ZIP-SHA-256:
`b3fdf7954cb5dcb767180610b7e5b003a9390c66f4a8e493524b6589fe75a4d8`.
Alle 31 Sevii-Lua-Tests bestehen, darunter 77 Hoenn-Kontinuitätsprüfungen.
Ein nativer Test aus der materialisierten Paketkopie bestätigt bei
vollständigem Hoenn-Nachweis die offene Jirachi-Tür und den geschlossenen
Kapitänszugang (`package-dev10-jirachi-native.log`). Ein frischer roter
Sieben-Kapitel-Durchlauf aus derselben Paketkopie bestand mit 2.642
Routenbewegungen und Rückkehr nach Orania
(`package-dev10-qa/journeys/journey-red.json`). Der dev9-Nachweis für alle
drei Charaktere und das Altspielstand-Upgrade bleibt für die unveränderten
Systeme gültig. Voxel Ascendant 3.0.0-rc.2 ist separat erforderlich.
`releaseReady=false`: Finale Balance-/Inhaltsfreigabe bleibt offen.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev10.zip`

## Vorheriger Entwicklungsstand dev9 (30.09.2026)

Das frühere dev1–dev8-Protokoll unten ist historisch. Nach der Verlegung
der drei Regis und der Wetterlegenden wurde `package-dev9.zip` gebaut:
48.637 echte Dateien, 339.917.819 Bytes Nutzdaten, vollständige SHA-256-
Inventur und fehlerfreie ZIP-CRC-Prüfung. ZIP-SHA-256:
`dbb82d063e2373c7180242b952336efb33d3f145a3f0c7da32d2a1d7cda0830b`.
Die Paketkopie von `sevii_expedition.lua` wurde mit dem Arbeitsstand
abgeglichen. `releaseReady=false` bleibt korrekt. Voxel Ascendant
3.0.0-rc.2 muss separat installiert sein; die Sevii-Fähre verlangt das
aktive Mod und schaltet auf Inselkarten Voxel ein. Alle 31 Sevii-Lua-Tests,
sechs Paket-Integritätstests und native UI-Fänge für Groudon, Kyogre und
Rayquaza mit dem normalen Voxel-Kampf-HUD sind bestanden. Die drei alten
Regi-Eingänge sind nativ geschlossen; alle drei Tanoby-Kämpfe und ein
vollständiger Regirock-Fang wurden nativ geprüft. Der Upgrade-Durchlauf
eines unveränderten blauen Basis-Spielstands auf den aktuellen QA-Quellstand
ist mit sieben Kapiteln, 2.642 Schritten und erhaltener Bestandsdaten
bestanden; Einzelheiten stehen in `SEVII_UPGRADE_QA_DE.md`. Zusätzlich
haben Rot, Grün und Blau je eine frische, native Sieben-Kapitel-Reise aus
der materialisierten dev9-Kopie mit aktivem Voxel Ascendant abgeschlossen
und sind nach Orania zurückgekehrt. Pro Charakter: 2.642 Routenbewegungen,
150 Kartenübergänge, 51 Türen und sieben Inselfähren. Nachweis:
`package-dev9-qa/journeys/journeys-all-characters.json` und drei
Prozesslogs, jeweils Exitcode 0. Die Läufe verwenden vorbereitete
Post-Liga-Teams und schalten Zufalls- und sichtbare Begegnungen aus;
Fangpfade und Naturbegegnungen wurden getrennt geprüft. Die abschließende
Inhalts-/Balancefreigabe bleibt offen.

Paket: `/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev9.zip`

Der Entwicklungsstand `package-dev1` ist als eigenständiger Mod-Ordner und
ZIP gebaut. Bestehende Spielerinstallationen, Speicherstände und Archive
wurden nicht verändert. Die komplette Erweiterung ist weiterhin in Arbeit.

## Paket und Integrität

Lokales ZIP:
`/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev1.zip`

- ZIP-Größe: 204.561.453 Bytes.
- ZIP-SHA-256: `5e803be9186808d5ef0559b4a0af932e82de69c7019281592091d28ab89d1871`.
- 48.633 inventarisierte Dateien mit 339.863.753 Bytes Nutzdaten, zuzüglich
  des Inventars `package-manifest.json` selbst.
- 655 aktuelle Lua-Module mit dem Arbeitszweig abgeglichen; 3.246 Artdateien
  gegen unabhängig erfasste SHA-256 geprüft.
- Alle Paketdateien wurden materialisiert: keine Symlinks zum Arbeitszweig,
  QA-Overlay oder Artcache. ROM-Dateien und Spielstände sind ausgeschlossen.
- ZIP-CRC, Entpacken in einen neuen Ordner und anschließende vollständige
  Hash-/Inventarprüfung bestanden (`package-dev1-unpacked-verify.json`).
- Sechs gezielte Integritätsprüfungen bestehen: gültiges Minimalpaket sowie
  Ablehnung geänderter, fehlender, zusätzlicher und verlinkter Dateien,
  ROM-/Save-Dateien und unsicherer Inventarpfade.

Der Builder `scripts/build_sevii_package.py` verlangt ein neues Ziel und
überschreibt keine vorhandene Installation. Er erzeugt bewusst
`status=development` und `releaseReady=false`. Das Basismanifest bleibt
KASC 6.7.29-rc.3; daraus darf keine offizielle Releasefreigabe abgeleitet werden.

## Native Prüfung der Paketkopie

Eine getrennte Testengine lädt ausschließlich den materialisierten Mod.
Der Host und die Prüftreiber sind externe Testwerkzeuge; das Mod-Paket selbst
benötigt seine früheren Entwicklungs-/Grafikpfade nicht.

`package-dev1-qa/journeys.log`, Exitcode 0, und
`package-dev1-qa/journeys-all-characters.json` belegen:

| Charakter | Kapitel | Routenbewegungen | Übergänge | Türen | Inselfähren |
| --- | --- | --- | --- | --- | --- |
| Rot | 7, abgeschlossen | 2.632 | 150 | 51 | 7 |
| Grün | 7, abgeschlossen | 2.632 | 150 | 51 | 7 |
| Blau | 7, abgeschlossen | 2.632 | 150 | 51 | 7 |

Alle Reisen speichern/laden nach jedem Kapitel und enden wieder in Orania.
Der Liga-Zugang wird vor der Abfahrt abgelehnt, bevor die vorbereitete
Post-Liga-Ausgangslage aktiviert wird. Team, Feldorden und Ausgangsposition
sind Fixtures. Nach der Abfahrt entstehen Fortschritt und Rückwege durch
echte Schritte, Türen, Fähren, Gespräche und Rätsel. Zufällige und sichtbare
Begegnungen sind ausgeschaltet; dies ist kein Balancenachweis.

`package-dev1-qa/legend-catalog-native12.log`, Exitcode 0, prüft im selben
Paket 23 kanonische Identitäten, 13 Gen-4-Pfade, drei alternative Regi-Orte
und die beiden erweiterten Eon-Wanderer. Vulkanfuß und zugangsbeschränkte
Himmelsplattform sind registriert; die benötigten Eon-Grafiken sind vorhanden.
Der gesonderte Lauf `eon-native5.log` belegt 47 native Außenkarten-Begegnungen,
die beiden Sevii-Fänge, konstante Werte und die tatsächliche Legacy-Übernahme.

## Noch keine fertige Erweiterung

Dieses Paket ist ein eingefrorener Prüfstand. Es liefert erstmals einen
nachvollziehbar lauffähigen Paketierungsweg, ersetzt aber nicht die offenen
Item-/Gebäudefunktionen, den restlichen Altlegenden-Abgleich, die abschließende
Upgrade- und Schwierigkeitsprüfung oder eine neue finale Paketprüfung nach
weiteren Änderungen. Der verbindliche Gesamtumfang bleibt in
`SEVII_DELIVERY_CHECKLIST_DE.md` erhalten. Nicht automatisch in ein laufendes
Spielerprofil installieren; das ZIP ist derzeit für isolierte Tests gedacht.

Der spätere Quellstand ergänzt die Besitz-/Forschungskontinuität der fünf
ursprünglichen Hoenn-Legenden und die schwarze/weiße Feldflöte. Diese separat
geprüften Änderungen sind **nicht** im eingefrorenen `package-dev1` enthalten.
Vor einem nächsten Paket muss der Builder die dann aktuellen Quelldateien
und Grafiken erneut materialisieren und prüfen; `dev1` wird nicht überschrieben.

## Neuer eingefrorener Stand dev2

`package-dev2.zip` enthält jetzt auch die Hoenn-Besitz-/Forschungsänderungen,
die Feldflöten, die Gluttherme und die gemeinsame Pension einschließlich
ihrer korrigierten Menüüberschrift. Der Build und die entpackte Kopie sind
vollständig geprüft:

- 48.634 inventarisierte Dateien, 339.882.320 Bytes Nutzdaten;
- 656 aktuelle Lua-Module und 3.246 unabhängig geprüfte Artdateien;
- ZIP-Größe 204.567.492 Bytes;
- SHA-256 `5ae8a91175309946c3339bc22956b1a213031eea407fc15880abdcec50c9b22d`;
- ZIP-CRC und alle Dateihashes nach Entpacken bestanden, keine externen
  Dateiverknüpfungen im Mod-Ordner.

Belege: `package-dev2-build.json` und `package-dev2-unpacked-verify.json`.
Die separate Engine `package-dev2-engine` lädt den entpackten Mod-Ordner.
Hostdateien sind weiterhin externe Testwerkzeuge; der Mod selbst ist
vollständig materialisiert.

Der Upgrade-Durchlauf gegen diese Kopie ist jetzt bestanden:
`upgrade-current/base-blue3.log` und `upgrade-current/journey-blue3.log`,
beide Exitcode 0. Die unveränderte Basis erzeugt einen neuen isolierten
blauen Spielstand; das entpackte Paket lädt ihn und spielt alle sieben
Kapitel bis Orania. 2.632 Routenbewegungen, 150 Kartenränder, 51 Türen und
sieben Inselfähren; Team, Box, alter Lavados-Beleg, Items und Geld bleiben
erhalten. Die Aussage ist auf den geprüften Basisstand und die dokumentierten
Start-Fixtures begrenzt; Zufalls-/sichtbare Begegnungen sind im Upgrade-Test
ausgeschaltet. Die drei gesonderten Ressourcenreisen prüfen normale
Zufallsbegegnungen im identischen Quellstand.

`package-dev2-qa/legend-catalog1.log`, Exitcode 0, prüft in dieser Kopie
23 kanonische Sonderidentitäten, Formen, Geschenkprofile, ursprüngliche
Quellen und alle sechs spät gebundenen Besitzhistorien. Das Paket behält
`releaseReady=false`, bis die offenen Inhaltsarbeiten und die vollständige
Anforderungsprüfung erledigt sind.

## Neuer eingefrorener Stand dev3

`package-dev3.zip` enthält zusätzlich den Tauchball und die Eneco-Rute samt
der korrigierten Herkunftskennung für tatsächlich geangelte Wildkämpfe.
Der Build hat 48.634 Dateien und 339.886.863 Bytes Nutzdaten materialisiert;
das ZIP hat SHA-256
`0be8dffa39f35652845410471b29d2c27056556926942749b20a5efa06ed24f7`.
ZIP-CRC, Entpacken in `package-dev3-unpacked` und erneute vollständige
Inventar-/SHA-256-Prüfung sind bestanden. Beleg: `package-dev3-build.json`;
die Entpackprüfung meldete `verified=true`, `standaloneMod=true` und
`releaseReady=false`. Eine getrennte QA-Engine hat die materialisierten
Dateien geladen; `package-dev3-qa/item-audit4.log`, Exitcode 0, bestätigt
live 190 geprüfte Gen-2-/Gen-3-Identitäten, davon 78 mit festen Inselquellen
und 32 mit registrierten Itemeffekten. Die Kampf- und Beutelproben für die
neuen Items liefen zuvor am identischen Quellstand (`SEVII_ITEM_PLAN_DE.md`).
Zusätzlich bestand `package-dev3-qa/journey-red/journey.log` mit Exitcode 0:
Rot spielte alle sieben Kapitel, 2.718 Routenbewegungen, 154 Kartenränder,
65 Türen und sieben Inselfähren bis zurück nach Orania. Die Ressourcenprobe
erfasste 30 natürliche Wildkämpfe und sieben echte Center-Besuche ohne
Blackout. Ausgangsteam, Ligastatus und Charakterwahl sind Fixtures;
sichtbare Pokémon waren ausgeschaltet. Damit ist dev3 für diese rote Reise
geprüft; die früheren grünen/blauen Paket- und Ressourcenreisen stehen im
jeweiligen älteren Quellstand. Nach dev3 begonnene Korrekturen der alten
Legenden sind noch nicht in diesem eingefrorenen ZIP enthalten.

## Neuer eingefrorener Stand dev4

`package-dev4.zip` enthält die Kanto-/Johto-Besitzhistorie, die korrigierte
Legacy-Archivbereinigung, die Originalobjekt-Sperre und den gefilterten
legendären NG+-Partnerkatalog. Es enthält weiterhin Tauchball und Eneco-Rute.
48.634 Dateien mit 339.889.749 Bytes Nutzdaten wurden materialisiert.
ZIP-SHA-256:
`0d0d3b7e0cc23332b16d010735d3644f0399547b117256b395ff889135abbfde`.
ZIP-CRC, Entpacken und erneute Inventar-/Dateihashprüfung bestanden;
`package-dev4-build.json` und `package-dev4-unpacked-verify.json` melden
`standaloneMod=true`, `releaseReady=false`.

Eine getrennte Engine lädt ausschließlich den entpackten Mod. Die native
Iteminventur (`package-dev4-qa/item-audit.log`) und der alte Legenden-/Legacy-
Test (`package-dev4-qa/old-legends.log`) enden mit Exitcode 0. Die blaue
Ressourcenreise aus derselben Paketkopie (`package-dev4-qa/journey-blue/journey.log`)
bestand sieben Kapitel, 2.718 Bewegungen, 154 Kartenränder, 65 Türen,
sieben Fähren, 39 natürliche Wildkämpfe und sieben Center-Besuche bis Orania
ohne Blackout. Post-Liga-Team, Charakter und Startlage sind Fixtures;
sichtbare Pokémon waren ausgeschaltet. Weitere Inhalts- und
Abschlussprüfungen bleiben nötig, bevor aus diesem Entwicklungspaket eine
Spielerfreigabe wird.

Der unabhängige Upgrade-Durchlauf besteht ebenfalls: Der unveränderte
Basisstand erzeugte unter `kasc-sevii-dev4-upgrade-blue` einen isolierten
blauen Spielstand (`package-dev4-qa/upgrade-blue/base.log`, Exitcode 0).
Danach lud die dev4-Paketkopie genau diesen Stand und spielte sieben Kapitel
bis Orania (`package-dev4-qa/upgrade-blue/journey.log`, Exitcode 0).
`journey-upgrade-blue4.json` meldet `complete=true`, `upgradedFromBase=true`
und `oldSavePreserved=true` bei 2.632 Bewegungen, 150 Kartenrändern,
51 Türen und sieben Fähren. Alte Pokémon, Inventar, Geld und Lavados-Beleg
blieben beim Laden und nach jedem Kapitel erhalten. Die dokumentierten
Start-Fixtures und die Grenzen eines einzelnen Basisstands gelten weiter.

## Neuer eingefrorener Stand dev5

`package-dev5.zip` enthält zusätzlich Luxusball und Sanftglocke mit
Inselquelle und Freundschaftswirkung. Der Stand wurde in einen neuen Ordner
materialisiert: 48.634 Dateien und 339.893.037 Bytes Nutzdaten. Der
ZIP-SHA-256 ist
`875a7c5db5cb55d845ffbb79fd59652ca52ada607f1a6269dfa7f9ccfdc46d41`.
ZIP-CRC, vollständiges Entpacken und erneute Größen-/SHA-256-Prüfung aller
48.634 Dateien bestanden; `releaseReady=false` bleibt gesetzt.

Eine getrennte Engine lud ausschließlich die entpackte dev5-Kopie. Ihr
nativer Itemaudit (`package-dev5-qa/item-access-audit.json`) bestätigt 190
geprüfte Gen-2-/Gen-3-Identitäten, davon 80 mit festen Sevii-Quellen und 33
mit Beutel-Itemeffekten. Die Sanftglocke besitzt stattdessen eine passive
Tragewirkung. Die blaue natürliche Ressourcenreise aus derselben Paketkopie
(`package-dev5-qa/journey-blue.json`) bestand sieben Kapitel, 2.718
Bewegungen, 154 Kartenränder, 65 Türen, sieben Fähren, 34 natürliche
Wildkämpfe und sieben tatsächliche Center-Besuche bis zurück nach Orania.
Post-Liga-Team, Charakter und Startlage sind wie zuvor kontrollierte
Test-Fixtures; sichtbare Pokémon waren ausgeschaltet.

Auch das Basisspielstand-Upgrade wurde für dev5 wiederholt. Die unveränderte
KASC-Basis `b30cfad48` erzeugte unter einer neuen isolierten QA-Identität
einen blauen Spielstand (`package-dev5-qa/upgrade-blue/base.log`, Exitcode 0).
Die entpackte dev5-Kopie lud ihn und spielte sieben Kapitel bis Orania
(`package-dev5-qa/upgrade-blue/journey.log`, Exitcode 0). Der Bericht
`journey-upgrade-blue5.json` meldet `complete=true`, `upgradedFromBase=true`
und `oldSavePreserved=true`: 2.632 Bewegungen, 150 Kartenränder, 51 Türen,
sieben Fähren. Die ursprünglichen Pokémon, Items, Geld- und Lavados-Belege
blieben beim Laden und nach jedem Kapitel erhalten. Weitere Iteminhalte und
die endgültige Freigabeprüfung bleiben offen.

## Neuer eingefrorener Stand dev6

`package-dev6.zip` enthält auch Ewigstein, Glücks-Ei und Münzamulett mit
ihren Inselquellen und Tragewirkungen. Der Builder materialisierte 48.636
Dateien mit 339.901.974 Bytes Nutzdaten. ZIP-SHA-256:
`edaa9be831c713fe221ae913e756fc34ae9b30ac61bf160f718af7a3afb98206`.
ZIP-CRC, vollständiges Entpacken und erneute Größen-/SHA-256-Prüfung
bestanden. Die sechs Integritätstests bestanden ebenfalls; der Zustand
bleibt `releaseReady=false`.

Eine getrennte Testengine lud nur die entpackte dev6-Modkopie. Ihr nativer
Itemaudit zählt 190 Gen-2-/Gen-3-Identitäten, darunter **83 feste
Sevii-Quellen** und 33 registrierte Beutel-Itemeffekte. Der native Fundlauf
bestand zehn volle-Beutel-/Abhol-/Verkaufsketten einschließlich des
Münzamuletts und dessen tatsächlicher Preisgeldwirkung. Belege:
`package-dev6-qa/item-audit.log`, `package-dev6-qa/item-access-audit.json`
und `package-dev6-qa/finds.log`, jeweils Exitcode 0.

Die blaue Ressourcenreise aus dieser entpackten Kopie bestand alle sieben
Kapitel und kehrte nach Orania zurück: 2.724 Bewegungen, 154 Kartenränder,
65 Türen, sieben Fähren, 35 natürliche Kämpfe, sieben Center-Besuche und
kein Blackout. `package-dev6-qa/journey-blue.log` endete mit Exitcode 0;
`journey-blue.json` meldet `complete=true`. Ligastatus, Startteam und
Orania-Position waren vorbereitete Fixtures; sichtbare Pokémon waren aus.
Auch der Upgrade-Durchlauf bestand: Die unveränderte KASC-Basis erzeugte
einen neuen isolierten blauen Spielstand. Die entpackte dev6-Kopie lud
genau diesen Stand und spielte sieben Kapitel bis Orania. Die Berichte
`package-dev6-qa/upgrade-blue/base.log` und `journey.log` endeten mit
Exitcode 0; `journey-upgrade-blue6.json` meldet `complete=true`,
`upgradedFromBase=true` und `oldSavePreserved=true`. 2.638 Bewegungen,
150 Kartenränder, 51 Türen und sieben Fähren wurden durchlaufen. Altes
Team, PC, Geld, Inventar und Lavados-Beleg blieben erhalten. Zufalls- und
sichtbare Begegnungen waren bei dieser Upgrade-Probe deaktiviert; die
separate Ressourcenreise prüft normale Zufallsbegegnungen.

Die Legendenkontinuität wurde ebenfalls in der entpackten dev6-Kopie
geprüft. `catalog.log` meldet 23 kanonische Sonderidentitäten mit ihren
Besitzern und Quellen; `old-legends.log` prüft alte Kanto-/Johto-Besitzbelege
einschließlich Geschenk, Laden und Legacy-Übernahme. `regi.log` bestand die
schwere Tanoby-Alternative erst nach den drei ursprünglichen Rätseln,
danach die einmaligen Fänge und Rückwege. `eon.log` prüft Latias/Latios als
dieselben Wanderer auf Kanto und Sevii samt Fang, Laden und Legacy-Übernahme.
Alle vier nativen Läufe endeten mit Exitcode 0. Die dort eingesetzten
Freischalt-, Team- und Fangmittel-Fixtures sind in den jeweiligen
Prüfberichten ausgewiesen; ein vollständiger normaler NG+-Menüdurchlauf
wird dadurch nicht behauptet.

Zusätzlich bestand `package-dev6-qa/giratina.log` mit Exitcode 0:
sechs Geschenkprofile wurden direkt und über Code-Vorprüfung abgewiesen,
beide Giratina-Formen samt Meisterball-Fangschutz geprüft. Eine bereits
historisch vorhandene Ausgabe blieb nach Speichern/Laden bestehen, ohne
neu ausgeliefert zu werden. Gewöhnliche Fänge und Geschenke blieben möglich.

`package-dev6-qa/walking-all.log`, Exitcode 0, löste anschließend **alle
84 Begegnungstabellen** durch tatsächliche Schritte auf ihren jeweiligen
Land- oder Wasserkarten aus. Das Ergebnis `walking-all-dev6.json` meldet
84/84 und `passed=true`. Kartenlage und Kampfstart liefen durch die native
Engine; nur der Zufallswurf wurde gezielt gesteuert. Der erneute
Fang-/Box-/Speicherlauf aus dieser Paketkopie bestand **218/218** Ziele
einschließlich mehrfacher Ladeprüfungen. `package-dev6-qa/captures.log`
endete mit `SEVII_NATIVE_ALL_CAPTURE_STORAGE_RELOAD_PASS 218` und Exitcode
0; `captures-dev6.json` meldet `passed=true`. Die Artwahl und Fänge nutzten
native Begegnungs- und Kampfpfade mit kontrolliertem Testzufall; die
Anreise zu jedem Lebensraum war in diesem Lauf eine Teleport-Fixture.

## Entwicklungsstand dev21: Fähre und Sevii-Level

Das neue Paket `package-dev21` ist materialisiert und erneut verifiziert:
48.647 Dateien, 344.876.741 Byte, eigenständiger Hauptmod und Begleitkarte.
Das ZIP hat SHA-256
`2190f661cf4ae823118da126225330b1fc87e6df340230d4e6c1366d75c92eba`;
die ZIP-CRC-Prüfung fand keinen fehlerhaften Eintrag. Das Manifest meldet
weiterhin `releaseReady=false`.

Die isolierte Paket-Engine bestand
`package-dev21-scaling-native.log`: 13 tatsächliche Fährfahrten vor dem
ersten Storykapitel (Rückkehr von allen sieben Häfen), Sevii-Wildtabelle
mit Level 80 bei Level-90-Team, Trainerkader Level 90 und realer
Regirock-Kampf Level 92. `package-dev21-trainer-scaling-native.log` prüft
zusätzlich den konstruierten nativen Trainerkampf samt Ass auf Level 92.
Beide Läufe endeten mit Exitcode 0; die Legendenvoraussetzung wurde für
den isolierten Leveltest als Fixture freigegeben, nicht erspielt.
