# Sevii: zusätzliche Items und Erwerbswege

## Aktueller Stand (01.10.2026)

Der Entwicklungsforscher auf Eiland Sechs nimmt jetzt 15 funktionsgeprüfte
Hoenn-/Sinnoh-Entwicklungsitems in seinen Nachschub auf. Pro Item liegt
ein einmaliger Fund auf Sevii; erst danach wird es dort käuflich. Im NG+
steht der Nachschub beim ersten Inselbesuch direkt bereit. Die bereits
freigeschalteten HEVO-Pakete und Charakterpfade bleiben Voraussetzung;
ein Gen-4-Item lässt sich unter einem frühen Generationsprofil zwar im NG+
aufbewahren, aber erst unter passenden Regeln für eine Entwicklung nutzen.
Ältere Sevii-Spielstände behalten ihren bisherigen Zugang zu Schönschuppe,
Abysszahn und Abyssplatte auch dann, wenn diese Exemplare verbraucht wurden.

Zu den neuen Fundstücken zählen `PROTECTOR`, `ELECTIRIZER`, `MAGMARIZER`,
`RAZOR_FANG`, `RAZOR_CLAW`, `DUBIOUS_DISC`, `SHINY_STONE`, `DUSK_STONE`,
`DAWN_STONE`, `REAPER_CLOTH`, `OVAL_STONE` und KASCs `MAGNETIC_CORE`.
Die drei Meeresitems `PRISM_SCALE`, `DEEP_SEA_TOOTH` und `DEEP_SEA_SCALE`
sind ebenfalls vertreten. Magnezone entsteht weiterhin am Magnetfeld,
nicht durch einen Stein: Auf Sevii gibt es dafür ein Feld im reparierten
Raketenlager auf Eiland Fünf. Die bekannten Moos- und Eisfelder erhalten
ebenfalls Inselstandorte; ihre HEVO-Freischaltungen gelten weiter.

Der native Test `legacy-access-live6.log` bestätigte frühe NG+-Fähre,
direkten Itemkauf, den Erstfund-/Nachkaufpfad, Preisabbuchung und
Fundbelege nach Speichern und Laden. Der Level-12-NG+-Trainer wurde mit
Level 14/16 konstruiert; die Folgeprobe bestätigte die Revachenpause und
den Levelzuwachs. Die vollständige Balancierung aller 22 Begegnungen im
frühen NG+ ist noch nicht abgenommen.

Zink ergänzt den Trainingsladen auf Eiland Sieben als 89. feste
Gen-2-/Gen-3-Itemquelle und 34. registrierten Beutel-Itemeffekt. Seine
getrennte Spezial-Verteidigung und die Kalzium-Fortschreibung sind im
Abschnitt „Zink“ beschrieben. Die ältere 88er-Zählung unten dokumentiert
den Stand vor dieser Ergänzung.

## Aktueller Quellenzuwachs (30.09.2026)

Vier schon kampfbereite Typverstärker besitzen jetzt je einen einmaligen
Sevii-Fund: `BLACKBELT_I` im Haus des Sammlers auf Eiland Drei,
`NEVER_MELT_ICE` im Haus der Inschriftenhüterin auf Eiland Vier,
`BLACK_GLASSES` im Haus des Ferienparadieses auf Eiland Fünf und
`TWISTED_SPOON` im Schülerhaus auf Eiland Sieben. Die Fundorte verwenden
die vorhandene Tragewirkung und werden nur bei passendem Generationsprofil
freigegeben. Volle Taschen lassen das Item liegen; nach erfolgreicher
Aufnahme, Verkauf oder Neuladen entsteht keine zweite Kopie.

`package-dev11-qa/finds/finds.log` bestätigt mit der Paketkopie alle
14 einmaligen Fundstellen, darunter die vier neuen: aufnehmen, anlegen,
speichern/laden, ablegen, verkaufen und Wiederholungssperre. Der aktuelle
Live-Audit `item-audit-souvenirs2/item-access-audit.json` zählt damit
**88 registrierte Gen-2-/Gen-3-Identitäten mit festen Sevii-Quellen**.
Die Inventur erfasst nun auch die bestehende Kapitelbelohnung `CLEANSE_TAG`,
die vorher in der Zählung fehlte.
Er prüft die vorhandene Effektbereitschaft der vier Items, ersetzt aber
keinen neuen Schadenstest jeder einzelnen Typkombination. Die später im
Dokument genannten älteren Zählungen sind historische Zwischenstände.


## Verbindlicher Umfang

Die Erweiterung berücksichtigt zusätzlich die bisher nicht erhältlichen
Gen-2- und Gen-3-Items. Bereits vorhandene Gegenstände bleiben interessant,
wenn Sevii eine feste, nachvollziehbare Quelle statt seltener Zufallsbeute
bietet. Neue Wirkungen benötigen einen eigenen Funktionsnachweis; ein
Katalogeintrag allein genügt nicht. Diese Anforderung ist **noch offen** und
wird nicht durch die ersten beiden Beerenläden als erledigt gewertet.

## Bereits umgesetzt und gespielt

- **Eiland Drei, Haus 3:** zehn Johto-Beeren, einschließlich Wunderbeere
  und Rätselbeere. Ein fester Händlerzugang ergänzt bestehende Zufallsbeute.
- **Eiland Sechs, zweites Haus am Wasserweg:** fünfzehn Hoenn-Beeren.
  Enthalten sind Lydzi-, Lingan-, Salka-, Tahay- und Apikobeere
  (`LIECHI`, `GANLON`, `SALAC`, `PETAYA`, `APICOT`). Diese fünf fehlen im
  gemeinsamen gewöhnlichen Ausrüstungs-Belohnungspool; damit ist noch
  nicht behauptet, dass sie in sämtlichen alten Sonderpfaden fehlen.
- Händler verwenden den nativen Kaufablauf, vorhandene Preise und
  tatsächlich registrierte Beerenwirkungen. Explizite Gen-1-/Gen-2-Profile
  erhalten keine für sie ungeeigneten Hoenn-Beeren.
- Sieben Versorgungsläden führen Bälle, Medizin, Schutz und Fluchtseile.
  Der Quartiermeister auf Eiland Eins bewahrt vier Kapitelbelohnungen auf;
  ein voller Beutel verliert die Belohnung nicht.

`population-native3.log` belegt Käufe, fehlendes Geld, die sieben PCs,
Journalstellen, 40 Bewohnergespräche und gespeicherte Belohnungsbelege.
Zusätzlich wurde eine **gekaufte Lydzibeere** über das Ausrüstungsmenü
getragen, neu geladen, in einer echten Kampfrunde ausgelöst und verbraucht.
Angriff +1 und dauerhafter Verbrauch nach erneutem Laden sind geprüft.
Die Kampfrunde benutzt niedrige KP und einen harmlosen Gegner als Fixture.
Sie ersetzt weder eine komplette Inselreise noch Einzeltests aller 25 Beeren.

## Trainerbelohnungen

14 freiwillige Inseltrainer vergeben nach dem ersten Sieg jeweils ein Item.
Dazu gehören acht weitere Trageitem-Identitäten sowie sechs Beeren, die auch
in den neuen Läden vorkommen. Damit haben **33 unterschiedliche Gen-2-/Gen-3-
Item-Identitäten** eine feste Quelle in diesen beiden Sevii-Systemen.

| Trainer | Gebiet | Level | Belohnung |
| --- | --- | --- | --- |
| MIRA | `OneIsland_TreasureBeach` | 60–62 | `MYSTIC_WATER` |
| ARNO | `OneIsland_KindleRoad` | 62–64 | `CHARCOAL` |
| ALVA | `TwoIsland_CapeBrink` | 62–64 | `SHARP_BEAK` |
| JONTE | `TwoIsland` | 63–65 | `POLKADOT_BOW` |
| TAMMO | `ThreeIsland_BondBridge` | 64–66 | `MIRACLE_SEED` |
| NELA | `ThreeIsland` | 64–66 | `LIECHI_BERRY` |
| FENJA | `FourIsland` | 65–67 | `LUM_BERRY` |
| SILKE | `FourIsland` | 66–68 | `GANLON_BERRY` |
| LEV | `FiveIsland_ResortGorgeous` | 66–68 | `SALAC_BERRY` |
| RUNA | `FiveIsland_MemorialPillar` | 67–69 | `SPELL_TAG` |
| BORIS | `SixIsland_GreenPath` | 67–69 | `SILVERPOWDER` |
| TILDA | `SixIsland_RuinValley` | 68–70 | `PETAYA_BERRY` |
| KIAN | `SevenIsland_SevaultCanyon` | 69–71 | `APICOT_BERRY` |
| ELIN | `SevenIsland_TrainerTower` | 70–72 | `CHOICE_BAND` |

Ein voller Beutel oder ein ungeeignetes Generationsprofil lässt die Belohnung
beim Trainer reserviert. Erneutes Ansprechen liefert sie nach, ohne einen
neuen Kampf zu verlangen. Siege und Auslieferung bleiben beim Laden erhalten.
`trainers-native2.log` prüft alle 14 tatsächlichen Auslieferungen.
Der native Profiltest prüft zusätzlich die Abholung nach einem Profilwechsel.
`POLKADOT_BOW` hat nun ebenfalls eine feste Inselquelle; es bleibt eine eigene
vorhandene Identität mit Normal-Tragebonus, keine neue Itemwirkung.

## Aprikokobälle und Naturfunde

Ein Händler in `ThreeIsland_House1` verkauft alle sieben vorhandenen
Aprikokobälle für je 1.000. Die bestehenden Fangformeln bleiben zuständig;
der Laden verlangt Gen 2 oder später und vollständig registrierte Wirkungen.
Die Bälle waren schon über bedingte Wandertrainerbelohnungen verfügbar.
Sevii ergänzt hier bewusst eine feste, erneuerbare Quelle.

Sechs einmalige Fundstellen ergänzen die Erkundung:

| Fund | Ort | Verwendung |
| --- | --- | --- |
| Perle | Schatzgestade, Eiland Eins | Verkauf im normalen Laden |
| Sternenstaub | Kap Kante, Eiland Zwei | Verkauf im normalen Laden |
| Minipilz | Bundbrücke, Eiland Drei | Verkauf im normalen Laden |
| Riesenpilz | Eiland Drei | Verkauf im normalen Laden |
| Riesenperle | Ferienparadies, Eiland Fünf | Verkauf im normalen Laden |
| Sternenstück | Canyon, Eiland Sieben | Verkauf im normalen Laden |

Volle Taschen lassen den Fund liegen. Erst erfolgreiche Aufnahme setzt
`population.finds[id]`; Verkaufen, Laden oder Zurückkehren erzeugt keine
neue Kopie. Native Käufe, alle sechs Aufnahmen/Verkäufe und diese
Wiederholungsfälle sind in `finds-native3.log` bestanden. Alle sieben Bälle
wurden außerdem mit ihrer nativen Fangberechnung geprüft. Ein tatsächlich
gekaufter Freundesball wurde über den Beutel geworfen, verbraucht und ein
Karpador tatsächlich gefangen. Freundschaftsmarkierung und Bindung von
mindestens 200 blieben nach dem Laden in Team/PC erhalten. Der Test verwendet
gezielte Fang-Zufallswerte und Ortswechsel; er ist kein Balancetest.

Der Trainerturm ergänzt acht weitere feste Itemquellen (siehe unten).
Damit haben **54 unterschiedliche registrierte Gen-2-/Gen-3-Identitäten**
feste Sevii-Quellen in Läden, Trainerbelohnungen und Naturfunden. Der gesamte
Itemumfang ist weiterhin offen.

## Acht Turmpreise

Jede Etage des Trainerturms auf Eiland Sieben vergibt nach ihrem ersten
Sieg genau einen Preis. Höhere Etagen verlangen den Sieg der vorherigen.

| Etage | Trainer | Level | Preis |
| --- | --- | --- | --- |
| 1 | Nora | 68–70 | Schwarzglas |
| 2 | Ole | 70–72 | Pudersand |
| 3 | Jara | 72–74 | Magnet |
| 4 | Sven | 74–76 | Ewiges Eis |
| 5 | Ida | 76–78 | Fokus-Band |
| 6 | Malte | 78–80 | Scope-Linse |
| 7 | Rieke | 80–82 | Überreste |
| 8 | Enno | 82–84 | Kugelblitz |

Alle acht Preise verwenden vorhandene Tragewirkungen. Die Ausgabe verlangt
deren Bereitschaft im gewählten Generationsprofil; ein unpassendes Profil
oder voller Beutel lässt den Preis beim Trainer. `tower-native2.log` prüft
alle acht tatsächlichen Ausgaben und die spätere Abholung auf Etage 4.
Die Wirkungsbereitschaft wurde abgefragt, nicht jede Tragewirkung erneut
in einem Kampf ausgelöst. Der Titel auf dem Dach ist ein dauerhafter
Journaleintrag und kein zusätzlicher legendärer Fang oder wiederholbarer Preis.

## Milch, Kräuter und Lavakekse

Drei weitere Inselgeschäfte führen sieben zuvor im Katalog wirkungslose
Medizin-Identitäten mit einer tatsächlichen Beutelwirkung:

| Ort | Angebot | Wirkung |
| --- | --- | --- |
| Eiland Vier, Haus 1 | Kuhmuh-Milch / Beerensaft | 100 / 20 KP |
| Eiland Drei, Haus 4 | Energiepulver / Kraftwurzel | 50 / 200 KP, bitter |
| Eiland Drei, Haus 4 | Heilpuder | Statusprobleme heilen, bitter |
| Eiland Drei, Haus 4 | Vitalkraut | Wiederbelebung mit vollen KP, bitter |
| Eiland Zwei, Haus am Kap Kante | Lavakeks | Statusprobleme heilen |

Diese Mengen bleiben in KASC auch in späteren Profilen bei den klassischen
Gen-2-/Gen-3-Werten. Die vier Kräuter senken bei erfolgreicher Anwendung
bestehende Freundschaftswerte; wirkungslose Anwendungen und Eier bleiben
unverändert. Pulver/Puder senken um 5 beziehungsweise 10 ab Freundschaft
200, Wurzeln um 10/15, Vitalkraut um 15/20. Beerensaft wird hier aus dem
Beutel angewendet; eine zusätzliche automatische Tragewirkung wird nicht
behauptet. Die alten Katalogpreise bleiben erhalten.

`medicine-native6.log` (Exitcode 0) prüft alle sieben Käufe sowie jeweils
**eine echte Anwendung im Feld und eine echte Kampfrunde** pro Item.
Verbrauch, KP, Status und Freundschaft werden geprüft und nach Laden erneut
kontrolliert. Vitalkraut belebt im Kampf ein besiegtes Teammitglied wieder;
Statusheilung entfernt auch die aktiven Gift-/Schlaf-/Verwirrungszähler.
83 ergänzende Funktionsprüfungen decken Profile, Eier, fremde Ziele,
wirkungslose Anwendungen, KP-Grenzen und Freundschaftsstufen ab.
Die Kampfsituation und KP/Status-Ausgangswerte sind gezielte Test-Fixtures.

Damit bestehen nun feste Sevii-Quellen für **61 unterschiedliche registrierte
Gen-2-/Gen-3-Item-Identitäten**. Der übrige Itemumfang bleibt offen.

## Abgleich und Grenzen

`SEVII_ITEM_REQUIREMENTS.json` enthält 190 derzeit registrierte Identitäten
mit Gen-2-/Gen-3-Provenienz. Darunter sind technische Namensvarianten und
ältere KASC-Anpassungen. Das ist **kein vollständiges Verzeichnis sämtlicher
Original-Items** der beiden Generationen. Beispielsweise wird die bereits
vorhandene Schönschuppe als KASC-Entwicklungshilfe für Barschwa geführt;
sie ist dadurch kein ursprünglich in Gen 3 eingeführtes Item.

Der native Audit `item-audit-native8.log` prüft das normale Sevii-Profil
nach Maras Bericht (Gen 4) sowie die Bereitschaftstabellen für Gen 2–7:

- 25 Identitäten in den Beerenläden, sieben Aprikokobälle beim neuen Händler
  und sechs Naturfunde.
- 56 TMs im vorhandenen erneuerbaren TM-Archiv.
- 65 Identitäten mit bestätigter Tragewirkungs-Bereitschaft in mindestens
  einem Profil; davon 62 schon in Gen 3.
- 53 Identitäten in mindestens einem gewöhnlichen Ausrüstungs-Beutepool;
  51 davon in Gen 3.
- Sieben Aprikokobälle mit registrierter Fangwirkung. Ihr alter
  Wandertrainerzugang verlangt zusätzliche Fortschrittsbedingungen.
- 22 registrierte Item-Effekte insgesamt. Das sagt allein noch nichts
  über ihren erfolgreichen Einsatz auf einem konkreten Pokémon aus.

Die Kategorien überlappen. Fehlende Tragewirkung bedeutet nicht, dass ein
Gegenstand keine Feld-, Fang-, Entwicklungs- oder Verkaufsfunktion hat.
Die früheren negativen Barschwa-/Perlu-Proben verwendeten einen noch
versiegelten Kanto-Spielstand. Nach Freigabe von „Jenseits von Kanto“
funktionieren die bestehenden Entwicklungswege. Sevii respektiert diese
bestehende Freigabe jetzt auch bei Begegnungen; das Fangortbuch erklärt
gegebenenfalls die Sperre. Ein reiner Kanto-Spielstand wird nicht ungefragt
umgestellt.

## Meeresforschung und drei Entwicklungsitems

Der Meeresforscher im ersten Haus am Wasserweg auf Eiland Sechs verkauft
Schönschuppe, Abysszahn und Abyssplatte für je 2.100. Er verwendet die
vorhandenen KASC-Entwicklungen und deren kanonischen Effektadapter.
Das Angebot verlangt „Jenseits von Kanto“ und Gen 3 oder später.

`evolution-native8.log` und `evolution-native9.log`, jeweils Exitcode 0,
belegen mit **tatsächlich auf Sevii gefangenen** Barschwa und Perlu:

- Schönschuppe kaufen und im echten Beutel anwenden: Milotic.
- Abysszahn kaufen und im echten Beutel anwenden: Aalabyss.
- Abyssplatte kaufen und im echten Beutel anwenden: Saganabyss.
- Entwicklungsanimation, einmaligen Verbrauch und erhaltene Identität nach
  Speichern/Laden prüfen; es werden keine Geschenkbelege erzeugt.

Für die beiden Perlu-Zweige wurden getrennte frische QA-Spielstände und
wirkliche Fänge verwendet. Die Fang-Zufallswerte, Reisen zum Lebensraum/
Händler und das Verschieben der gefangenen Originaldatensätze vom PC ins
Team sind Test-Fixtures; dies ist kein PC-Menütest. Schönschuppe bleibt die
bestehende KASC-Anpassung für Barschwa, kein ursprünglich in Gen 3
veröffentlichtes Item.

Nun besitzen **64 registrierte Gen-2-/Gen-3-Item-Identitäten einschließlich
der ausdrücklich genannten KASC-Anpassung** feste Sevii-Quellen.

## Vier Hoenn-Forschungsbälle

Im zweiten Haus auf Eiland Fünf verkauft ein Fischer Netz-, Nest-, Wieder-
und Timerball für je 1.000. Die Bälle verwenden ab Gen 3 die klassischen
Hoenn-Boni, auch in späteren Profilen: Netzball x3 bei Wasser/Käfer,
Nestball mindestens x1 beziehungsweise `(40 - Level) / 10`, Wiederball x3
bei bereits besessenen Arten und Timerball x1 bis x4 nach 30 abgeschlossenen
Runden. Gesehene Arten allein zählen beim Wiederball nicht.

Die Fangrechnung verwendet Gen-3-KP-, Status- und Wackelproben. Der native
Kanto-Client bleibt für Beutel, Verbrauch, Wurfanimation und Speicherung
zuständig; die Darstellung nutzt seine vorhandene Ballanimation. Es werden
keine eigenen Ballgrafiken behauptet. Trainer-, Geister- und gesperrte
Storykämpfe sowie Gen-1-/Gen-2-/OFF-Profile lehnen die neuen Bälle ab.

Der Timerzähler liegt in den bestehenden datenbasierten Kampf-Tokens. Auch
fehlgeschlagene Würfe und Heilmittelrunden zählen. 106 Funktionsprüfungen
decken Formeln, Grenzen, Zufallsproben, Profilregeln und Tokenvalidierung
ab; dies ersetzt keinen nativen Kampf-Checkpoint-Rundlauf.

`balls-native3.log` (Exitcode 0) und `research-balls.json` belegen vier
tatsächliche Käufe mit anschließendem Beutelwurf, Fang, Verbrauch und
erhaltenen Pokémon im Team/PC nach Laden. Ein fehlgeschlagener Netzballwurf
und eine Milch-Anwendung erhöhen im echten Kampf den Timerbonus auf x1,2.
Die Post-Liga-Ausgangslage, Kartenwechsel, Gegner, KP und Zufallswerte sind
kontrollierte Test-Fixtures. Der Bevölkerungstest umfasst jetzt 84 Prüfungen,
die Expeditionsintegration 78.301.

Der aktuelle Quellenabgleich enthält damit **68 registrierte
Item-Identitäten mit festen Sevii-Quellen** einschließlich der genannten
KASC-Anpassungen. Weitere Items bleiben offen.

## Nächste Item-Inhalte

| Gruppe | Geplanter Sevii-Bezug | Noch erforderlich |
| --- | --- | --- |
| Fehlende Spezialbälle | Küstenforschung und Fangaufträge | Netz-, Nest-, Wieder-, Timer-, Premier-, Tauch- und Luxusball sind umgesetzt und nativ geprüft. |
| Entwicklungsitems | Meeresforschung, Inselgärten und Ruinenfunde | Alte Belohnungswege abgleichen; echte gefangene Pokémon entwickeln; fehlende feste Quellen ergänzen. |
| Trageitems | Traineraufgaben und Forschungsbelohnungen | Namensvarianten zusammenführen, Wirkungen je Profil prüfen, Belohnungen abstimmen. |
| Weitere Medizin | Bewohner und örtliche Versorgung | Sieben Milch-/Saft-/Kräuter-/Keks-Items vollständig geprüft; AP-Top und Zauberasche sind ebenfalls umgesetzt; Zink besitzt jetzt eine getrennte Spezial-Verteidigungswirkung und eine feste Ladenquelle (siehe unten). |
| Perlen, Sternenstücke und weitere Fundstücke | Strandfunde, Höhlen und Nebenaufträge | Verkauf beziehungsweise konkrete Verwendung sowie einmalige Fundbelege implementieren. |
| Wettbewerbsschals, Sonderbeeren | Passende optionale Inselaktivitäten | Tatsächlichen Nutzen bestimmen und implementieren; keine wirkungslosen Füllbelohnungen. Alle fünf Glasflöten haben inzwischen eine geprüfte Wirkung und Händlerquelle. |

Aprikokobälle, Sonnenstein, König-Stein, Metallmantel, Drachenhaut und
Up-Grade sind im Quellcode bereits in bedingten Belohnungswegen enthalten.
Sie dürfen daher nicht allein aufgrund eines leeren Händlerangebots als
„bisher unerhältlich“ eingestuft werden. Die Quelldateien stehen pro Item im
maschinenlesbaren Abgleich. Legendenbezogene oder alte Story-Schlüsselitems
brauchen einen passenden Inselzweck; es entstehen dadurch keine doppelten
legendären Pokémon und kein fangbares Giratina.

## Noch ohne nachgewiesenen Erwerbsweg in diesem Abgleich

Die folgende Liste ist eine **Prüfliste**, keine Behauptung globaler
Unerhältlichkeit. Sie berücksichtigt nur die oben geprüften Quellen.

- `AGUAV_BERRY`
- `BERSERK_GENE`
- `BLACKBELT_I`
- `BLACK_GLASSES`
- `BLUE_SCARF`
- `BRIGHTPOWDER`
- `BRIGHT_POWDER`
- `CLEANSE_TAG`
- `ENIGMA_BERRY`
- `FIGY_BERRY`
- `GREEN_SCARF`
- `IAPAPA_BERRY`
- `LANSAT_BERRY`
- `LAX_INCENSE`
- `MACHO_BRACE`
- `MAGO_BERRY`
- `MENTAL_HERB`
- `NEVER_MELT_ICE`
- `PINK_SCARF`
- `QUICK_CLAW`
- `RED_SCARF`
- `SEA_INCENSE`
- `SHELL_BELL`
- `SILVER_POWDER`
- `STARF_BERRY`
- `TWISTED_SPOON`
- `WIKI_BERRY`
- `YELLOW_SCARF`
- `ZINC`


## AP-Top, Zauberasche und drei Glasflöten

`sevii_recovery.lua` ergänzt fünf tatsächliche Itemwirkungen. Die vorhandenen
Katalogpreise bleiben erhalten. Die beiden Läden sind nach der Liga mit
Gen-3-Regeln oder später verfügbar; Zauberasche ist als Gen-2-Item ab
Gen-2-Regeln verwendbar. Die Feld-/Kampf-Grenzen gelten auch für direkte
Effektaufrufe. Im Kampf bleibt das beim Beginn eingefrorene Profil zuständig.

| Item | Feste Inselquelle | Wirkung |
| --- | --- | --- |
| AP-Top | Wohnhaus mit Tanoby-Archiv auf Eiland Sieben | Beutelauswahl von Pokémon und Attacke; setzt deren AP-Plus-Stufe auf drei. |
| Zauberasche | Einmaliger Vorratsfund in der Eingangshöhle des Glutberg-Rubinpfads | Nur im Feld: alle besiegten Teammitglieder mit vollen KP wiederbeleben. |
| Blaue Flöte | Zweites Wohnhaus auf Eiland Eins, beim Quartiermeister | Wiederverwendbar; heilt Schlaf eines gewählten Pokémon im Feld oder Kampf. |
| Gelbe Flöte | Derselbe Glasflötenhändler | Wiederverwendbar im Kampf; heilt Verwirrung des aktiven Pokémon. |
| Rote Flöte | Derselbe Glasflötenhändler | Wiederverwendbar im Kampf; heilt Verliebtheit des aktiven Pokémon. |

AP-Top ergänzt die fehlenden AP-Plus-Stufen und die dazugehörigen aktuellen
AP, füllt vorher verbrauchte AP aber nicht vollständig auf. Schon maximierte
Attacken, Nachahmer/Sketch, ungültige Auswahl und Eier verbrauchen nichts.
Die Auswahl lässt sich abbrechen. Der native Beutel bleibt Eigentümer des
Verbrauchs; der neue `item.use`-Hook ergänzt nur die Attackenauswahl.
Die Wirkung folgt der PP-Max-Logik in
[pokeemerald/pokemon.c](https://github.com/pret/pokeemerald/blob/master/src/pokemon.c)
(`ITEM5_PP_MAX`) und KASCs bereits verwendeter AP-Berechnung.

Zauberasche verwendet in allen unterstützten Profilen die vorhandene
Gen-3-Host-Semantik (`src/core/game3/item_use.lua:reviveAll`): lebende
Teammitglieder, Eier und AP bleiben unverändert. Dies ist keine zusätzliche
Behauptung einer vollständigen Gen-2-spezifischen Heilroutine. Ein voller
Beutel lässt den Fund liegen; nach Aufnahme und Verbrauch erscheint er
nicht erneut. Zauberasche ist kein unbegrenzt verkaufter Wiederbeleber.

Flöten werden bei erfolgreicher Wirkung behalten. Im Kampf spielt der
Host trotzdem eine echte Itemrunde. Blau entfernt auch den aktiven
Schlafzähler. Gelb entfernt nur Verwirrung; Rot benutzt die vorhandene
Verliebtheitsverwaltung und heilt nur die gewählte Seite. Andere Zustände
und der Gegner werden durch die jeweilige Flöte nicht pauschal zurückgesetzt.
Die Beutelbeschreibungen erklären Verwendung und Wiederverwendbarkeit.

Die Funktionsprüfungen umfassen 54 Effekttests und 93 Bevölkerungstests.
Die aktuelle Kartenintegration besteht mit 78.429 Prüfungen.

`recovery-native3.log`, Exitcode 0, und `recovery-items.json` belegen
vier echte Ladenkäufe samt Geldmangel, Zauberasche-Fund mit vollem Beutel
und Wiederholung, AP-Top mit Pokémon-/Attackenauswahl, Abbruch und
Nichtverbrauch bei bereits maximierten AP. Zauberasche belebt zwei
Teammitglieder wieder; ein lebendes verbranntes Pokémon und seine AP
bleiben erhalten. Die blaue Flöte funktioniert im Feld. Alle drei Flöten
wurden in echten Kampfrunden verwendet und bleiben nach Laden im Beutel.
Verliebtheit entsteht dabei durch eine echte gegenseitige Anziehungsrunde;
die rote Flöte heilt nur die eigene Seite. Die Attackenauswahl wurde visuell
geprüft. Reise, Liga/Profil, Team/Attacken/KP/Status/DVs und Zufallswerte
sind Fixtures; kein vollständiger Insel- oder Balancenachweis.

`item-audit-native9.log`, Exitcode 0, weist jetzt **73 unterschiedliche
Gen-2-/Gen-3-Item-Identitäten mit festen Sevii-Quellen** und 27 registrierte
Itemeffekte unter den 190 geprüften Identitäten aus. Das ersetzt weder die
offenen Erwerbswege noch Einzelwirkungsprüfungen aller übrigen Items.

## Premierball und aktueller Quellenstand

`sevii_balls.lua` ergänzt den Premierball als fünften Ball beim Fischer im
zweiten Haus auf Eiland Fünf. Er verwendet den gewöhnlichen Hoenn-Fangbonus
**x1** mit KP-, Status- und Wackelberechnung. Wasser/Käfer, niedriges Level,
früherer Besitz und vergangene Runden geben ihm keinen zusätzlichen Bonus.
Die Formel ist durch die native Gen-3-Referenz
`engine/src/core/game3/battle/catching.lua`, `BALL_BONUS[12] = 10`, belegt.
KASC behält diese klassische Formel auch in späteren Profilen. Gen 1/2,
OFF-, Trainer-, Geist- und nicht fangbare Storykämpfe bleiben gesperrt.

Der bestehende Katalogpreis **20** bleibt erhalten; der neue Inselhändler
verkauft direkt. Ein Kaufbonus für zehn Pokébälle ist nicht implementiert.
Die gemeinsame bestehende Wurfanimation wird verwendet; es gibt keine
zusätzlich behauptete weiße Ballgrafik. Beschreibung und Händler erklären
seinen gewöhnlichen Fangbonus. Der Preis ist ein übernommener Katalogwert,
kein durch diesen Funktionslauf belegter Balancetest.

118 Ball-, 96 Bevölkerungs- und 78.430 Kartenintegrationsprüfungen bestehen.
`balls-native5.log`, Exitcode 0, prüft alle fünf Ballkäufe, tatsächliche
Würfe/Fänge und Laden. Netz- und Premierball werden auch erfolglos geworfen:
Verbrauch genau einmal; der Timerzähler steigt. Der Premierball bleibt x1,
auch bei bereits besessenem Karpador. Sein erfolgreicher Fang wird bei
vollem Team in den PC übertragen und nach Laden wiedergefunden.

Der vorherige Lauf v4 hatte eine falsche Testannahme: KASC hatte auch die
früheren Fänge direkt in den PC geschickt, sodass das Team noch nicht voll
war. Der korrigierte Test füllt es vor dem Premierball mit den vier bereits
wirklich gefangenen Pokémon. Diese direkte Entnahme ist eine Fixture und
kein Test des PC-Menüs. Weitere Fixtures: Post-Liga-Profil, Reise,
Team/Level, Gegner, KP und Zufallswerte. `research-balls.json` nennt die
Grenzen. Kein Produktfehler beim Speichern wurde festgestellt.

`item-audit-native10.log`, Exitcode 0: **74 unterschiedliche registrierte
Gen-2-/Gen-3-Identitäten mit festen Sevii-Quellen**, 28 registrierte
Itemeffekte unter weiterhin 190 geprüften Identitäten. Die übrigen
Kandidaten bleiben offen; die älteren Zählungen oben sind Zwischenstände.

## Zink: eigene Spezial-Verteidigung ab Gen 3

Zink ist im Trainingsladen auf Eiland Sieben für 10.000 erhältlich und über
den Beutel nutzbar. Es erhöht ab Gen-3-Regeln nur den separaten
`statExp.specialDefense`-Trainingswert. Beim ersten Einsatz übernimmt dieser
den bisherigen gemeinsamen Spezialwert als Ausgangspunkt. Kalzium erhöht
danach weiterhin beide Spezialwerte; die alte `statExp.special`-Speicherung
bleibt für Gen 1/2 und alte Spielstände erhalten. Die getrennte Berechnung
gilt auch für gezüchtete Pokémon. Bei OFF und Gen 2 verweigert Zink die
Anwendung. Der native Clientlauf prüft Kauf, beide Beutelnutzungen,
Statusprojektion, Eichs Legacy-Teamkopie sowie Speichern und Laden. Die
Iteminventur zählt damit
**89 feste Sevii-Quellen und 34 registrierte Beutel-Itemeffekte** unter 190
geprüften Gen-2-/Gen-3-Identitäten. Weitere fehlende Items und Wirkungen
bleiben offen.

## Schwarze und weiße Flöte

Der Glasflötenhändler im zweiten Wohnhaus von Eiland Eins bietet jetzt alle
fünf Farben an. Schwarz halbiert die Rate normaler Zufallsbegegnungen, Weiß
erhöht sie um 50 Prozent. Die beiden Flöten sind wiederverwendbar und nur
im Feld ab Gen-3-Regeln einsetzbar. Der übernommene Katalogpreis ist jeweils
20; das ist noch keine geprüfte Preisbalance.

Die Wirkung gilt für das aktuelle Gebiet. Erneutes Spielen derselben Flöte
beendet sie, die andere ersetzt sie. Ein Wechsel in ein anderes Gebiet
beendet sie dauerhaft; bloßes Zurückkehren reaktiviert nichts. Geteilte
Sevii-Karten derselben Feuerrot-Quelle zählen als ein Gebiet. Speichern und
Laden am selben Ort bewahren die Wirkung. Ein Profilwechsel auf Gen 1/2
oder ausgeschaltete Erweiterungen lässt sie nicht weiterwirken.

`sevii_field_flutes.lua` verändert nur die Rate direkt vor dem gewöhnlichen
nativen Schrittwurf. Begegnungstabellen und Artenauswahl bleiben unverändert;
es gibt keinen Zusatzwurf. Die +50/-50-Prozent-Faktoren folgen dem lokalen
Gen-3-Ratenmodell in `engine/src/core/game3/encounters.lua`; KASC nutzt weiter
seinen vorhandenen Gen-1-Schrittvertrag ohne erfundenen Gen-3-Cooldown.
Erneutes Spielen als Ausschalter und die Gruppierung der Kartenfragmente
sind ausdrückliche KASC-Anpassungen.

Die Flöten verändern weder sichtbare Pokémon noch die eigene Wandererprobe.
Der Aufenthaltsort bleibt gespeichert; nur im richtigen Gebiet wird einmal
mit 5 Prozent geprüft. Ein zugelassener Wanderer erreicht den normalen
Flöten-Ratenadapter überhaupt nicht. Normale Schutz- und Schrittregeln
bleiben bei der Engine.

`field-flutes-native1.log`, Exitcode 0, prüft zwei echte Käufe, Benutzung im
Beutel, Unverbrauchtbleiben, Speichern/Laden, Ausschalten, Profilgrenzen und
Gebietswechsel einschließlich zweier zusammengehöriger Kartenfragmente.
Ein physischer Grasschritt bleibt unter Schwarz ohne Begegnung; derselbe
kontrollierte Ratenwert startet unter Weiß einen echten gewöhnlichen Kampf
mit anschließender Flucht. Die laufende Wanderer-Hookkette liefert mit jeder
Flöte genau einen Treffer über alle 20 möglichen Ergebnisse, jeweils mit
genau einer Wahrscheinlichkeitsprobe. Liga, Team, Storyprofil, Reise,
Zufallswerte und Wandererorte sind Fixtures; kein Balancenachweis.

989 Flötenprüfungen enthalten den vollständigen Vergleich der 256 möglichen
nativen Ratenwerte: bei Ausgangsrate 64 entstehen 64/32/96 Treffer für
ohne/Schwarz/Weiß, mit genau dem einen Ratenwurf und nur bei Treffer einem
Artenwurf. 60 Recovery-, 96 Bevölkerungs- und 78.497 Integrationsprüfungen
bestehen. `item-audit-native11.log`, Exitcode 0, zählt nun **76 feste
Gen-2-/Gen-3-Itemquellen und 30 registrierte Itemeffekte** unter weiterhin
190 geprüften Identitäten. Die übrigen Kandidaten bleiben offen.

## Tauchball und Eneco-Rute

Der Forschungsballhändler auf Eiland Fünf führt zusätzlich den Tauchball.
KASC übernimmt den bereits vorhandenen Gen-3-Wasserbonus x3,5 und wendet
ihn auf echte Wasserbegegnungen sowie auf tatsächlich mit der Angel
gehakte Pokémon an. An Land bleibt der Bonus x1; der Wassertyp des Ziels
allein zählt nicht. Die Umgebung wird bei Kampfbeginn in einem geprüften,
rein datenförmigen Kampfbeleg festgehalten. Eine Änderung der aktuellen
Karte nach Kampfbeginn und das Laden eines Kampf-Checkpoints ändern den
Bonus nicht. Ungültige oder fremde Belege liefern keinen Wasserbonus.

`dive-native7.log`, Exitcode 0, belegt Kauf, einen echten Wasserschritt,
Kampf-Checkpoint und Wiederladen, einen Fehlwurf mit genau einem
verbrauchten Ball und einer vergangenen Runde, Fang im Wasser, Angeln vom
Ufer, Fang und erneutes Laden. Der Test belegt außerdem: Der bestehende
Köderball erkennt das geangelte Pokémon mit x3, hält aber eine bloße
Surfbegegnung bei x1. Der Host übergab die Angelkennung bislang nur an
einen ungenutzten Hook; KASC übernimmt nun die vorhandene native
`hooked`-Kennung beim Erzeugen des Kampfes. Fangart, Reise, Surfstatus und
Fangzufallswerte sind im Test teilweise vorbereitete Ausgangsdaten.

Die Eneco-Rute ist beim Händler für Attackentraining auf Eiland Sieben
erhältlich. Im normalen Wildkampf verwendet sie die native einmalige
Beutel-Flucht samt Verbrauch. Sie ist im Feld und in Trainerkämpfen nicht
einsetzbar; Raids, Echos, Geister- und ausdrücklich geskriptete
Sonderkämpfe bleiben gesperrt. `fluffy-native2.log` belegt zwei echte
Käufe, Ablehnung im Feld, Ablehnung mit Raid-/Echo-Sperre, zwei Fluchten
ohne zusätzlichen Gegnerschlag und dauerhaften Verbrauch nach Laden.
Die Gegner und Sperrkennungen sind QA-Fixtures, keine vollständig
gespielten Raid-Quests.

`item-audit-native12.log`, Exitcode 0, zählt jetzt **78** registrierte
Gen-2-/Gen-3-Identitäten mit festen Sevii-Quellen und **32** registrierte
Itemeffekte unter 190 geprüften Identitäten. 155 Ball-, 76 Recovery-, 104
Bevölkerungs- und 78.501 Kartenintegrationsprüfungen bestehen. Der
verbleibende Katalog wird weiter nach tatsächlicher Wirkung und bisherigem
Erwerbsweg bewertet; die reine Katalogzahl ist keine Anforderung, jeden
Gegenstand als Inselpreis zu verteilen.

## Luxusball – aktueller Quellstand nach dev4

Der Forschungsballhändler auf Eiland Fünf verkauft jetzt auch den Luxusball.
Sein Fangbonus bleibt x1. Ein tatsächlich damit gefangenes Pokémon erhält
einen gespeicherten Herkunftsbeleg; positive Freundschaftsgewinne der
bestehenden KASC-Forschungs-, Reise- und Begleiterwege werden bei aktivem
Gen-3-Profil verdoppelt, maximal bis 255. Negative Effekte bitterer Medizin
bleiben unverändert. Ohne aktive Erweiterung oder unter Gen 3 bleibt der
gewöhnliche Gewinn erhalten.

172 Ball- und 104 Bevölkerungsprüfungen sowie 78.501
Kartenintegrationsprüfungen bestehen. Der native Forschungsballlauf kaufte
alle sieben Bälle, prüfte echte Würfe und Fänge sowie Speichern/Laden; beim
Luxusball blieb der Herkunftsbeleg nach dem Laden erhalten.
`luxury-ball-qa/research-balls.json` dokumentiert diesen Lauf.
Die neue native Inventur `luxury-ball-qa/item-access-audit.json` zählt unter
190 geprüften Gen-2-/Gen-3-Identitäten **79 feste Sevii-Quellen und 33
registrierte Itemeffekte**. Dieses Item ist noch nicht im eingefrorenen
Paket dev4 enthalten; die übrigen Kandidaten und der endgültige Paketlauf
bleiben offen.

## Sanftglocke an der Pension auf Eiland Vier

In der gemeinsam mit Route 5 betriebenen Pension liegt jetzt einmalig eine
Sanftglocke. Ein voller Beutel lässt sie liegen; ein späterer Versuch kann sie
aufnehmen. Der Fundbeleg übersteht Speichern und Laden und verhindert
Duplikate. Ein Partner, der die Glocke tatsächlich trägt, erhält bei den
bestehenden KASC-Freundschaftsgewinnen 50 % mehr Punkte, aufgerundet. Mit
einem Luxusball gefangen und zusätzlich mit der Glocke ausgestattet, wirken
beide Boni zusammen. Gen-1-/Gen-2-Profile und abgeschaltete Erweiterungen
behalten den bisherigen Gewinn; bittere Medizin senkt Freundschaft weiterhin
unverändert. Die Ausrüstungsansicht erkennt die Wirkung ab Gen 3.

Der native Fund-/Aprikokoballlauf bestand acht volle-Beutel-Proben,
einmalige Abholung, Verkauf und gespeicherte Fundbelege. Für die Glocke
wurden zusätzlich echtes Anlegen über das Ausrüstungsmenü,
Freundschaftsgewinn, Laden und Ablegen geprüft. 178 Ball-, 109
Bevölkerungs- und 78.503 Integrationsprüfungen bestehen. Die neue native
Inventur zählt **80 feste Sevii-Quellen und 33 registrierte Itemeffekte**
unter 190 Gen-2-/Gen-3-Identitäten. Die Sanftglocke ist ein passiver
Trageeffekt und erhöht deshalb die Zahl der registrierten Beutel-Itemeffekte
nicht. Dieser Quellstand liegt nach dem unveränderten Paket dev4.

## Ewigstein in der Eiskaskadenhöhle

Ein einmaliger Ewigstein liegt im unteren Bereich des ersten Höhlenraums.
Der Fund ist erst nach der Liga erreichbar, bleibt bei vollem Beutel liegen
und kann nach Speichern/Laden nicht verdoppelt werden. Ab Gen-2-Regeln
verhindert ein tatsächlich getragener Stein die Evolution im gemeinsamen
KASC-Evolutionsprüfpunkt. Nach dem Ablegen ist die Entwicklung wieder möglich;
eine bloße Vorschau auf ein Entwicklungsitem bleibt lesbar. Dieses Verhalten
folgt dem Everstone-Check in
[pokefirered `GetEvolutionTargetSpecies`](https://github.com/pret/pokefirered/blob/master/src/pokemon.c#L4816-L4835),
angepasst an KASCs Evolutions-Hook und Generationsprofile.

Der native Fundlauf bestand neun volle-Beutel-Proben, Abholung, Verkauf und
gespeicherte Fundbelege. Zusätzlich wurde ein Level-20-Karpador über das
Ausrüstungsmenü mit dem gefundenen Stein ausgestattet: Der tatsächliche
Nachkampf-Evolutionsprüfpunkt blieb gesperrt, nach Laden weiterhin gesperrt
und nach Ablegen wieder offen. `everstone-qa5/finds.log` endete mit Exitcode
0; 15 eigene Funktions-, 114 Bevölkerungs- und 78.505 Integrationsprüfungen
bestehen. Die neue native Inventur zählt **81 feste Sevii-Quellen und 33
registrierte Beutel-Itemeffekte** unter 190 geprüften Identitäten. Der
Ewigstein hat einen passiven Trageeffekt und liegt noch nicht im eingefrorenen
Paket dev5.

## Glücks-Ei als Turmabschluss

Nach acht in Reihenfolge gewonnenen Turmetagen übergibt die Protokollantin
auf dem Dach genau ein Glücks-Ei. Bei vollem Beutel bleiben Preis und Titel
offen, sodass der Spieler nach dem Freimachen zurückkehren kann. Trägt ein
tatsächlich am Kampf beteiligtes Pokémon das Ei, werden seine erhaltenen
Erfahrungspunkte ab Gen-2-Regeln um 50 % erhöht. Die Berechnung nutzt den
zentralen Erfahrungshook; ein Beuteleintrag ohne ausgerüstetes Pokémon löst
keinen Bonus aus. Der Faktor entspricht dem
[Gen-3-Quellcode](https://github.com/pret/pokefirered/blob/master/src/battle_script_commands.c).

`lucky-egg-qa4/tower.log` bestand den vollständigen nativen Turmlauf mit
acht Siegen, verzögerter Dachübergabe, Rückweg, tatsächlichem Anlegen,
Erfahrungsbonus und erneutem Laden (Exitcode 0). Der getrennte Wiederholungslauf
`lucky-egg-qa3/lucky-egg.log` bestätigte den Gewinn von 14 auf 21
Erfahrungspunkte gegen ein wildes Karpador. Elf Funktionsprüfungen bestanden. Die
aktuelle Iteminventur `lucky-egg-audit/item-access-audit.json` zählt **82
feste Sevii-Quellen und 33 registrierte Beutel-Itemeffekte** unter 190
Identitäten. Glücks-Ei ist ein passiver Trageeffekt. Das eingefrorene Paket
dev5 enthält es noch nicht.

## Münzamulett in der verlassenen Station

Nach Abschluss des vierten Inselkapitels liegt in der verlassenen Station
auf Eiland Fünf ein einmaliges Münzamulett. Ein voller Beutel lässt es
liegen; ein gespeicherter Fundbeleg verhindert erneute Ausgaben, auch nach
Verkauf. Nimmt ein tatsächlich damit ausgerüstetes Pokémon an einem
Trainerkampf teil, verdoppelt der native Siegabschluss das Preisgeld und
zeigt den erhöhten Betrag im Siegtext. Niederlagen und Wildkämpfe zahlen
keinen Bonus. Der Eingriff ist mit KASCs vorhandenem „Happy Hour“-Bonus
schachtelbar; beide verdoppeln denselben Trainerpreis, wenn beide
Voraussetzungen erfüllt sind.

`amulet-qa1/finds.log` bestand den nativen Fund- und Auszahlungslauf mit
Exitcode 0: zehn einmalige Funde einschließlich voller Beutel, Anlegen des
gefundenen Münzamuletts, doppeltes Preisgeld aus einem echten Trainerkampf,
Speichern/Laden, Ablegen und Verkauf ohne Wiederauftauchen. 22 eigene
Funktionsprüfungen und 120 Bevölkerungsprüfungen bestanden. Die native
Inventur zählt **83 feste Sevii-Quellen und 33 registrierte
Beutel-Itemeffekte** unter 190 geprüften Identitäten; das Münzamulett ist
ein passiver Trageeffekt. Das eingefrorene Paket dev5 enthält es noch nicht.
