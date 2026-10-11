# Sevii: Legendenprüfung und verbleibende Arbeiten

## Aktueller Legendenvertrag (01.10.2026)

Die früheren Regi-Heiligtümer und Wetterkammern sind geschlossen. Regis
gehören ausschließlich zu Tanoby nach der Waage und Hoenn-Forschung.
Groudon (Rot), Kyogre (Blau) und Rayquaza (Grün) erhalten jeweils ein
Sevii-Siegel; das Insel-Finale, die eigene schwarze Schreintür und die 130
gewöhnlichen Hoenn-Arten wecken die persönliche Begegnung. Jirachi bleibt
an der Konvergenztür nach allen 134 anderen Hoenn-Arten sowie den
bisherigen Pfad- und Forschungsbedingungen. Besitzhistorie bleibt
artübergreifend über Saves und NG+ erhalten. Fangbare Legenden haben
zusätzlich einen Durchlaufbeleg: ein Fang pro Art und Durchlauf, erneute
Quest und Begegnung im NG+. Geschenk- und Partnerausgaben behalten ihre
eigene Anspruchsprüfung. Native UI-Fänge der drei
Wetterlegenden mit Voxel-HUD sowie Regirocks Tanoby-Fang sind bestanden;
Regice und Registeel wurden dort nativ im Kampf gestartet. Das neue Paket
dev10 ist auf Dateien, Hashes und ZIP-CRC geprüft. Der frühere
Kapitänszugang zur Wunschkammer ist bei installiertem Sevii gesperrt;
der native dev10-Test bestätigt die alleinige Konvergenztür. Die alten Protokolle
belegen diesen Vertrag nicht.

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


## Implementierte Giratina-Sperre

`sevii_legend_policy.lua` löst kanonische Identitäten über den bestehenden
Nationalkatalog auf. Der Katalog wird erst nach Sevii initialisiert und
deshalb über einen Provider gelesen. Beide Formen (`dex:487`, `form:10007`)
sind gesperrt, einschließlich Ei- und Schillerndes-Ei-Geschenkprofile.

`event_archive.lua` prüft neue Auslieferungen vor dem Anlegen eines Pokémon.
`gift_codes.lua` prüft vor einer neuen gemeinsamen Code-Reservierung.
Vorhandene offene Reservierungen wandern in `giftCodes.suspended`; der Beleg
bleibt erhalten. Schlägt das Speichern fehl, bleibt die ursprüngliche
Reservierung aktiv. Andere Geschenke können anschließend normal abgeholt
werden. Bereits vorhandene Pokémon und ihre Herkunft bleiben gültig.

Die Item-Vorprüfung verweigert Fangbälle vor dem Verbrauch; `catch.rate`
sperrt zusätzlich den eigentlichen Fang einschließlich Meisterball.
Auf Sevii bleiben Gen-1–4-Legenden/Spezialidentitäten aus gewöhnlichen
Begegnungen ausgeschlossen. Die neue Ausnahme erfordert die genaue,
gerade laufende Kampfinstanz eines eigenen Inselmysteriums. Ein gespeichertes
Flag, die passende Art oder der passende Ort allein genügt nicht.

Nativer Nachweis: `legend-policy-native4.log`, Exitcode 0, und
`sevii-legend-policy-audit.json`. Geprüft sind sechs aktive Geschenkprofile,
beide Formen, gesperrte direkte Auslieferungen, Code-Vorprüfung ohne neue
Reservierung, fehlgeschlagenes Speichern, zurückgestellte Belege nach Laden,
ein anderes tatsächlich ins PC geliefertes Geschenk, Wiedererkennung eines
früheren Giratina ohne Kopie sowie Erhalt nach Laden. Normale Wingull-
Fangberechnung und der externe Lavados-Pfad bleiben erlaubt.
Die Tests verwenden ausschließlich isolierte QA-Spielstände und künstliche
Testcodes mit eigener Hashfunktion, keine Spielerarchive oder echten Codes.

## Dauerhafte Gen-4-Besitzhistorie

`sevii_legend_history.lua` führt für die 13 geplanten Gen-4-Sonderarten einen
monotonen Besitzbeleg unter `hevo_persistent.seviiLegendOwned`. Alle Formen
teilen die kanonische Nationalidentität. Giratina ist nicht Bestandteil dieser Besitzmigration. Lavados ist im
nachfolgend dokumentierten Prüfschritt hinzugekommen; die anderen alten
Kanto-/Johto-Legenden wurden im jüngsten Abgleich ergänzt (siehe Schluss).

Als vorhandener Besitz zählen Team, PC, Eier, PC-Reserve, bereits besessene
Pokédex-Arten, ausgelieferte Geschenke, frühere Rocket-Fangbelege für
Darkrai/Regigigas sowie Legacy-Bank, gemeinsame Bank
und deren Quarantäne. Nur gesehen zu haben oder einen noch nicht
ausgelieferten Geschenkbeleg zu besitzen reicht nicht. Ein unlesbares Archiv
oder eine unlesbare Bank wird nicht als leer behandelt: neue Ausgaben warten.
Auf älteren Hosts ohne gemeinsame Speicherschnittstelle ist die ausdrücklich
als zuständig ausgewiesene Legacy-Bank maßgeblich; eine bereits migrierte
gemeinsame Bank darf diesen Rückfall nicht verwenden.

Ein tatsächlicher Fang oder eine erfolgreiche Geschenk-Auslieferung setzt
den Beleg. Er bleibt nach Freilassen, Verschieben und Laden erhalten und
wird beim normalen Legacy-Übergang in den neuen Spielstand übernommen.
Pokémon werden dafür weder entfernt noch zusammengeführt. Ein fehlgeschlagener
Speichervorgang erzeugt keinen alleinstehenden externen Beleg, der nach dem
Laden das verlorene, ungespeicherte Geschenk dauerhaft sperren würde.

`legend-history-native4.log` (Exitcode 0) bestand mit echter Geschenk-Ei-Auslieferung,
Entfernen und Laden, Speicherausfall und Wiederholung, einem nativen Heatran-
Fang außerhalb Sevii, gesperrtem zweiten Meisterball und tatsächlichem
`beginJourney`/`seedNewSave`. Das Entfernen der Pokémon ist eine gezielte
Fixture; es ist kein Nachweis der Freilassen-Oberfläche. Der Legacy-Nachweis
prüft Archivtransaktion und frischen gespeicherten Datenaufbau, nicht den
vollständigen NG+-Menüdurchlauf. 49 Funktionsprüfungen decken zusätzlich
Formen, Bankfehler, Quarantäne und beschädigte lokale Historie ab.

## Bereits identifizierte offene Kontinuitätsfragen

- `hoenn_moltres_volcano_67.lua` besitzt den Zinnober-Vulkan-Pfad.
  `postgame.lua` überlässt diesem Modul die Sichtbarkeit von Lavados;
  Sevii fügt kein zweites Lavados auf dem Glutberg hinzu.
- `hoenn_endgame_run_events_67.lua` speichert Lavados, die drei Regis und
  Deoxys ausdrücklich pro Durchlauf und setzt diese Ereignisse bei einem
  neuen Spiel zurück. Für Lavados ist die getrennte dauerhafte Besitzhistorie
  samt Abschluss ohne Fang inzwischen umgesetzt (siehe unten). Die drei Regis erhalten nun ebenfalls eine gemeinsame Besitzhistorie und
  Tanoby-Begegnungen; der aktuelle Nachweis steht unten. Deoxys ist inzwischen
  ebenfalls getrennt abgesichert, siehe „Ursprüngliche Hoenn-Legenden“.
- Bestehende historische Geschenkprofile enthalten auch die drei Vögel
  und Mewtu. Ihr eigener Besitzabgleich ist im jüngsten Prüfschritt ergänzt;
  diese Zeile dokumentiert die zuvor gefundene Lücke.
- Die 23 Hoenn-/Gen-4-Spezialidentitäten außerhalb des gewöhnlichen
  Sevii-Katalogs benötigen weiter einen Abgleich mit ihren vorhandenen
  Fang-, Geschenk-, Bank- und Legacy-Pfaden. Boxbelegung allein genügt nicht
  als Fanghistorie; Verkauf/Freilassen/Tausch darf keine zweite garantierte
  Begegnung erzeugen.

## Lebender Katalogabgleich der 23 Sonderarten

`legend-catalog-native8.log` (Exitcode 0) und `SEVII_LEGEND_SOURCES.json`
prüfen alle 23 kanonischen Identitäten, ihre Formen, die tatsächlich
registrierten Geschenkprofile und die bekannten Hoenn-, Sevii- und Rocket-Fangbesitzer im
laufenden Client. Keine dieser Arten wird vom gewöhnlichen Sevii-Fangpfad
zugelassen. Die Geschenkprofile sind keine Zusage eines öffentlich
verfügbaren Codes und ersetzen keinen Fangort.
Die folgende Fundorttabelle beschreibt den aktuellen Vertrag; der genannte
v8-Log ist ein älterer Katalogbeleg und prüft die späteren Umzüge noch nicht.
Für jede fangbare Art gilt zusätzlich: höchstens ein Fang pro Durchlauf;
historische Besitzbelege bleiben für Legacy und Bank erhalten, sperren aber
den erneuten Questfang nach NG+ nicht.

| Arten | Bestehender Fangbesitzer | Dauerhaftigkeit |
| --- | --- | --- |
| Regirock, Regice, Registeel | Ausschließlich Tanoby-Inschriften nach „Der schlafende Riese“ und Hoenn-Forschung; die alten Heiligtümer sind geschlossen | Gemeinsame dauerhafte Besitzhistorie; getrennte Durchlaufbelege für den Forschungsfortschritt |
| Latias, Latios | Bestehende Wanderidentitäten; Kanto-Routen bleiben erhalten, nach dem versiegelten Sevii-Finale zusätzliche Insel-Außenbereiche und Wasser | Gemeinsame Besitzhistorie einschließlich alter Fangbelege; Unit-Abgleich bestanden, nativer Erweiterungstest separat dokumentiert |
| Groudon, Kyogre, Rayquaza | Charaktergebundene Wettersiegel auf Sevii nach eigener schwarzer Schreintür, 130 Hoenn-Arten und Insel-Finale | Dauerhafte Legacy- und Besitzsiegel |
| Jirachi | Wunschkammer ausschließlich über die Konvergenztür nach vollständiger Hoenn-Forschung | Dauerhaftes Legacy- und Besitzsiegel |
| Deoxys | Bestehende Entstehungsinsel nach Vulkan- und Regirock-Nachweis dieses Durchlaufs | Durchlaufbeleg für die Expedition und dauerhafte Besitzhistorie; kein Zweitfang im selben Durchlauf |
| Heatran | Neu: Druckleitungen im Glutberg, nach Abschluss der Expedition | Gemeinsame Gen-4-Besitzhistorie; nativer Inselpfad bestanden |
| Selfe, Vesprit, Tobutz | Neu: Nebenquest „Drei Stimmen“ auf Eiland Zwei, Fünf und Sieben | Gemeinsame Gen-4-Besitzhistorie; drei native Fänge bestanden |
| Cresselia, Darkrai | Neu: Nebenquest „Eine Nacht im Mondlicht“ im Wasserirrgarten und der Verlorenen Höhle | Gemeinsame Gen-4-Besitzhistorie; zwei native Fänge bestanden |
| Regigigas | „Der schlafende Riese“ in den Tanoby-Ruinen; ersetzt Rocket-Lead `regigigas_power` | Dauerhafte Gen-4-Historie, alte Rocket-Belege und neuer Inselpfad nativ geprüft |
| Phione, Manaphy | „Heimweg der Strömung“ auf Eiland Sechs | Dauerhafte Gen-4-Historie; beide Insel-Fänge nativ geprüft |
| Shaymin | „Was wieder wächst“ im Beerenforst | Dauerhafte Gen-4-Historie; Inselquest und Fang nativ geprüft |
| Dialga, Palkia | „Takt und Grenze“ im Punktloch und der Wandelhöhle | Dauerhafte Gen-4-Historie; beide Insel-Fänge nativ geprüft |
| Arceus | „Sieben Zeugnisse“ und Stein in der Monean-Kammer | Dauerhafte Gen-4-Historie; sieben Berichte, Buch und Fang nativ geprüft |

Der Test weist den Reset von Lavados auf einer losgelösten Datenkopie
nach. Er setzt keinen tatsächlichen Spielerfortschritt zurück. Eine bloße
globale Fangsperre auf Basis des Pokédex wäre unvollständig: So können
vorhandene Geschenke den Besitz erfüllen, ohne die von anderen Quests
verlangten Fangort-Siegel zu besitzen. Vor einer gemeinsamen Sperre müssen
diese Besitzer ihre Fortschrittsbelege ohne einen zweiten Fang auflösen
können. Der vollständige Legendenumfang ist deshalb weiterhin offen;
218 gewöhnliche Fangarten allein sind kein Abschluss dieses Audits.

## Heatran: Druckleitungen im Glutberg

`sevii_mysteries.lua` eröffnet den ersten eigenen Gen-4-Legendenpfad nach
`expeditionComplete` und `seviiRiftSealed`. Die Forscherin Ina wartet im
östlichen Höhleneingang des Glutbergs. Drei Manometer in Eingangshöhle,
drittem Untergeschoss und tiefster Kammer erklären die Ventilfolge:
**Mitte, oben, unten**. Ein Fehler schließt die Ventile gefahrlos; Messungen
und Teilfortschritt bleiben gespeichert. Nach dem Ausgleich kann der Spieler
Heatran auf Level 70 freiwillig begegnen. Flucht oder K. o. erlauben einen
neuen Versuch; ein Fang, vorhandener Altbesitz oder ausgeliefertes Geschenk
schließt ein zweites Exemplar aus. Ina und das Ventilfeld erklären Altbesitz.

Die Begegnung verlangt einen passenden Generationsmodus, die bestehende
Freigabe „Jenseits von Kanto“, vollständige Grafiken, ein gesundes Team und
einen erfolgreichen Speichervorgang vor Kampfbeginn. Die Fangberechtigung
gilt nur für genau diese laufende Kampfinstanz, denselben Spielstand, Ort
und dieselbe kanonische Art. Laden oder Beenden verwirft sie. Der native
Checkpoint-Schutz verhindert einen Kampf-Zwischenspeicher, dessen eigener
Abschluss nicht sicher wiederherstellbar wäre.

`mystery-native4.log` (Exitcode 0) und `heatran-mystery.json` prüfen:
654 tatsächliche Bewegungen ab Hafen Eins und zurück, vier Kartenränder,
16 Türen, alle drei Messstellen, falsche Ventilfolge, Laden mitten im Rätsel,
Speicherfehler vor Begegnung, freiwilligen Kampfbeginn, native Flucht,
Laden während eines abgebrochenen Versuchs, Meisterball-Fang, exakt ein
gespeichertes Heatran und Rückfahrt nach Orania. 51 zusätzliche
Funktionsprüfungen decken unter anderem K.-o.-Wiederholung, Generationswechsel,
fremde Kampfinstanzen und verspätete Abschluss-Callbacks ab.

Die Liga-/Finale-Ausgangslage, Team, Orden, Hafenposition, deaktivierte
gewöhnliche Begegnungen, Meisterball und Flucht-Zufallswerte sind Fixtures.
Dies ist ein durchgängiger Nebenquestnachweis, kein Balancenachweis. Acht
vorhandene Heatran-Grafiken wurden gegen das bestehende Paketmanifest geprüft
und im isolierten QA-Paket ergänzt (`heatran-asset-hashes.json`); das endgültige
Installationspaket muss sie materialisieren. Weitere Gen-4-Sonderpfade
und die älteren Legendeneigentümer bleiben offen.

## Drei Stimmen: Selfe, Vesprit und Tobutz

`sevii_lake_guardians.lua` ergänzt eine gemeinsame Nachspielgeschichte.
Archivarin Nele in Loreleis Haus auf Eiland Vier erklärt die drei Spuren:

- **Selfe:** Am westlichen oberen Ufer von Kap Kante erinnert sich der Spieler
  an Gegenströmung, Giratinas Eingriff und den örtlichen Abschluss. Falsche
  Antworten setzen nur diese Erinnerungsfolge zurück; Teilantworten werden
  gespeichert. Der Text behauptet weder Giratinas Fang noch seine Niederlage.
- **Vesprit:** Mila an der Gedenksäule erzählt vom verlorenen Brief ihrer
  Tochter. Eine Schleife am Südstrand des Ferienparadieses wird als einzigartige
  Questnotiz geborgen und zurückgebracht. Die Übergabe eröffnet die Begegnung
  am Stein östlich der Gedenksäule. Beutelkapazität kann die Schleife nicht
  vernichten; sie wird weder als Verkaufsitem noch wiederholt ausgegeben.
- **Tobutz:** Acht verzeichnete Turmsiege **und** die eigentliche Dachzeremonie
  werden anerkannt. Der Stein östlich der Protokollantin bestätigt die Aufgabe.
  Bereits vor Beginn dieser Nebenquest erbrachte Leistungen bleiben gültig.

Alle drei Begegnungen sind freiwillig, auf Level 65 und jeweils einmal pro
Gen-4-Besitzhistorie. Der Forschungsabschluss bei Nele benötigt nur die drei
Aufgaben, keinen Fang und keinen aktuellen Teambesitz. Auch Spieler mit einem
früheren Geschenk oder Bankbesitz können daher die Forschung abschließen.
`sevii_special_encounters.lua` besitzt ausschließlich die konkret laufenden
Kampfinstanzen. Es prüft Story, Generation, Grafiken, alte Besitzbelege,
Aufgabe, gesundes Team und Speichern vor Beginn. Giratina kann bei diesem
Besitzer nicht registriert werden. Heatran behält seinen bereits geprüften
eigenen Kampfbesitzer.

`guardians-native1.log` (Exitcode 0) und `lake-guardians.json` belegen die
zusammenhängende Nebenquest: **1.420 echte Bewegungen, 76 Kartenränder,
27 Türen und fünf Fährfahrten**. Falsche Antwort, gespeicherte Teilantwort,
geborgene Schleife mit Laden, tatsächliche Rückgabe, echte Dachzeremonie,
alle drei nativen Fänge mit exakt einem gespeicherten Exemplar, Duplikatsperre,
Forschungsbericht und Rückfahrt nach Orania sind bestanden. Die Kampfgrafiken
aller drei Arten wurden betrachtet; lange Quizbeschriftungen anschließend
gekürzt. 61 Funktionsprüfungen prüfen zusätzlich Flucht/K.-o.-Wiederholung,
Speicherfehler, Altbesitz, Profil-/Bankfehler, fremde Kampfinstanzen und
verspätete Abschluss-Callbacks. Die Expeditionsintegration zählt jetzt 78.323
bestandene Prüfungen.

Die acht bereits erarbeiteten Turmsiege sind in diesem Nebenquesttest eine
Fixture; die Kämpfe selbst sind durch `tower-native2.log` separat belegt.
Liga-/Finale-Ausgangslage, Team/Orden, erste Hafenposition, ausgeschaltete
gewöhnliche Begegnungen und Meisterbälle sind ebenfalls Testbedingungen.
Das ist kein Balancenachweis. 24 vorhandene Grafiken wurden gegen ihre
Paketmanifeste geprüft und im QA-Paket ergänzt. `SEVII_SPECIAL_ASSETS.json`
hält jetzt 32 nötige Spezialgrafiken einschließlich Heatran mit Prüfsummen
fest. **Vier von 13** vorgesehenen Gen-4-Sonderarten haben nun geprüfte
Insel-Fangpfade; neun sowie die ältere Legendenkontinuität bleiben offen.

## Eine Nacht im Mondlicht: Cresselia und Darkrai

Pflegerin Ilse im Haus des Ferienparadieses bittet nach dem Hauptfinale um
Hilfe für Jori. Eine helle Feder auf dem westlichen Eiland im Wasserirrgarten
weckt ihn; die erste freiwillige Cresselia-Begegnung auf Level 68 wird dadurch
möglich. Die Feder bleibt ein einzigartiger Questgegenstand in den Notizen,
kein verkäufliches Beutelitem und kein mehrfaches Geschenk.

Joris Erinnerung beschreibt eine Lichtspur durch die Verlorene Höhle:
**Osten, Norden, Süden, Süden, Osten, Westen, Süden, Osten, Norden.** Die
Laterne im ersten Raum startet diese Spur. `sevii_expedition.lua` meldet dem
Questbesitzer nur tatsächlich akzeptierte Türwechsel. Ein falscher Abzweig,
auch eine Schleife in denselben Raum, verliert die Spur und erlaubt einen
Neustart. Ein vom Host abgelehnter Kartenwechsel verbraucht dagegen keinen
Schritt. Der Zwischenstand bleibt beim Speichern erhalten.

In der zehnten Kammer hinterlässt der Spieler die Feder und trennt das
Albtraumecho vom Haus. Erst der Bericht bei Ilse beendet die Geschichte und
öffnet die freiwillige Darkrai-Begegnung auf Level 70. Jori bleibt gesund,
auch wenn kein Pokémon gefangen wird. Frühere Cresselia-/Darkrai-Besitzer
können alle Aufgaben abschließen; die allgemeine Besitzhistorie verhindert
eine weitere Ausgabe. Die lokale Versiegelung von Giratinas Riss bleibt
unverändert.

`dreams-native2.log` (Exitcode 0) und `moonlit-night.json` belegen **859 echte
Bewegungen, 50 Kartenränder, 40 Türen und die Rückfahrt nach Orania**:
geborgene Feder mit Laden, erwachter Bewohner, native falsche Türschleife,
neun richtige Türwechsel, Laden nach der vierten Tür, ruhiger Rückzugsort,
Hausbericht und beide Fänge. Cresselia und Darkrai bleiben danach jeweils
genau einmal im Team/PC; ihre erneute Begegnung ist gesperrt. Beide
Kampfgrafiken wurden betrachtet. 41 Funktionsprüfungen prüfen Questzustände
und Wiederholungen; vier zusätzliche Integrationsprüfungen decken erfolgreiche
und fehlgeschlagene Host-Kartenwechsel ab. Integration jetzt **78.339**.

Liga-/Finale-Ausgangslage, Team/Orden, erste Hafenposition, deaktivierte
gewöhnliche Begegnungen und Meisterbälle sind Testbedingungen. Es ist kein
Balancenachweis. Der erste Lauf scheiterte korrekt an fehlenden Darkrai-
Grafiken seines bestehenden `late_species_67.lua`-Besitzers. Dessen Dateien,
beide klassischen Grafikvarianten und der Ruf wurden gegen Paketmanifeste
beziehungsweise die vorhandene Basisdatei geprüft. Das zusätzliche Backend-
Grafikpaket allein war für diese wiederverwendete Identität nicht ausreichend.
`SEVII_SPECIAL_ASSETS.json` enthält nun **57 erforderliche oder unterstützte
Grafik-/Rufdateien für sechs Sonderarten**.

Der aktualisierte lebende Katalogtest erkennt alle sechs neuen Fangbesitzer,
prüft weiterhin den konkreten Ausschlussgrund des gewöhnlichen Inselpfads
und verzeichnet die aktuellen Grafikpfade samt fehlenden Dateien der noch
offenen Arten. Damit waren in diesem Prüfschritt **sechs von 13** Gen-4-Sonderarten nativ
geprüft. Der aktuelle Stand nach Regigigas steht unten.

## Rücknahmehinweis

Die erweiterte Geschenkbeleg-Normalisierung muss bei einer Rücknahme
erhalten bleiben, solange `suspended`-Belege existieren. Ein blindes Ersetzen
durch die alte `gift_codes.lua` würde dieses neue Feld verwerfen. Ohne
Sevii-Sperre kann der aktualisierte Code zurückgestellte Reservierungen
wieder aufnehmen. Das endgültige Installations-/Rollback-Paket ist noch
nicht erstellt.


## Rocket-Übergang und Korrektur des Quellenabgleichs

Der ursprüngliche Quellenabgleich berücksichtigte die Hoenn- und Sevii-Module,
übersah aber die Rocket-Rettungen. `rocket_recovery_raids_67_data.lua`
definiert bereits Darkrai (`darkrai_dream`) und Regigigas (`regigigas_power`).
Der Live-Audit erfasst jetzt auch diese Fangbesitzer sowie bei Darkrai den
abgelösten Ursprung. Geschenkprofile allein waren hierfür kein ausreichender
Quellennachweis.

Darkrai wird bei vorhandener Sevii-Quest nicht mehr als Rocket-Begegnung
angeboten. Neue Bossabschlüsse fahren mit den bestehenden Belohnungen fort.
Bereits offene Rettungsdialoge prüfen ihren Besitzer vor dem Kampfbeginn
nochmals. Ist die Begegnung verlegt oder das Pokémon bereits besessen,
wird die Kampagne fortgesetzt, ohne einen Fangbeleg zu erfinden. Bei mehreren
offenen Rettungen bleiben andere verfügbare Begegnungen erhalten.
Der zunächst erhaltene Regigigas-Zugang wurde im nachfolgenden Prüfschritt
durch „Der schlafende Riese“ ersetzt (siehe unten). Genesect und Zygarde
werden nicht umgesiedelt.

Zwei alte Ladeprobleme wurden dabei korrigiert: Der Vergleich verwendete
die numerische Etage statt der textuellen Instanzkennung; außerdem wurde
die Rettungsprüfung nach dem tatsächlichen Laden des gewählten Spielstands
nicht erneut aufgerufen. Die Prüfung läuft nun auf dem übernommenen
Spielstand, nicht auf einem anderen Slot. Gespeicherte Rocket-Fangbelege
werden in die dauerhafte Gen-4-Historie aufgenommen; Versuche, offene
Rettungen und bloß besiegte Bosse gelten nicht als Fang.

`rocket-transition-native2.log`, Exitcode 0, und
`rocket-sevii-transition.json`: echter Rocket-Dialog mit auslaufender
Darkrai-Begegnung, Rückkehr auf die originale Turmkarte, fortgesetzte
Kampagne, Speichern/Laden einer weiterhin offenen unbesessenen
Regigigas-Begegnung, Übernahme alter Fangbelege und einmalige Rückgabe
eines tatsächlich aus der Test-Box verwahrten Taubsi. Nach Löschen der
alten Raid-Belege bleiben beide Besitzstände nach Laden sowie über eine
echte Legacy-Archivtransaktion mit frischem Save-Seeding erhalten.
Liga, Orden, Team und historische Boss-/Fangbelege sind Fixtures; der Test
spielt keine Rocket-Trainerkämpfe nach und fängt kein neues Regigigas.
Der erste native Lauf deckte den fehlenden Ladeaufruf auf; erst der zweite
bestand. Zusätzlich bestehen 24 gezielte Rocket-Prüfungen und 49
Historienprüfungen. Die Inselintegration bleibt bei 78.339 bestandenen
Prüfungen; die bestehenden Traum- und Hütertests bestehen ebenfalls.


## Der schlafende Riese: Regigigas

`sevii_sleeping_giant.lua` ergänzt Rhea im Canyon-Haus, drei Inschriften
in Liptoo/Weepth/Scufib sowie Gegengewichte und Begegnungsstein in Rixy.
Alle sechs Standorte werden gegen Böden, vorhandene NPCs und Türen geprüft.
Die gemeinsame Begegnungsinstanz löst Regigigas über den bestehenden
kanonischen Besitzer `REGIGIGAS` auf; keine neue Pokémon-Identität wird
angelegt. Nach Liga, Finale, Jenseits von Kanto, drei gelesenen Inschriften,
Gleichgewicht und Bericht öffnet sich der freiwillige Level-75-Fang.

Die Gewichte bleiben ganzzahlig, nichtnegativ und in Summe zehn. Leere
Schalen können nichts abgeben; Fehlprüfungen erhalten den Zwischenstand.
Eine beschädigte Anordnung lässt sich am Mechanismus zurücksetzen.
Nach korrektem Ausbalancieren bleibt die Lösung bestehen. Ältere Besitzer
können die Forschung abschließen, aber keinen zweiten Riesen erhalten.
Die Regis bleiben an ihren bestehenden Fundorten; weder Besitz noch Fang
dieser drei Pokémon ist eine Voraussetzung für diese Quest.

`giant-native3.log` und `sleeping-giant.json`, Exitcode 0: **1.115 echte
Schritte, 62 Kartenübergänge, 18 Türen und eine Rückfähre**. Geprüft sind
Briefing nach Abschluss der Expedition, alle drei Inschriften, falsche
Prüfung, ausdrückliches Zurücksetzen, Teilanordnung nach echtem Laden,
Lösung 6 / 3 / 1, Hausbericht ohne Legendeneigentum, nativer Fang von
Regigigas auf Level 75, genau ein gespeichertes Exemplar, Wiederholungssperre
und Rückweg nach Orania. Anfangsposition, Team, Liga-/Finalebelege, Orden,
eine historische offene Rocket-Begegnung und Meisterball sind Fixtures.
Gewöhnliche Zufallsbegegnungen sind abgeschaltet; dies ist kein Balancetest.

Die ersten beiden nativen Läufe bestanden bis einschließlich Fang/Laden,
hingen aber beim automatischen Surfer-Versuch an einem ungeeigneten
Canyon-Ufer im Teammenü. Der Testhelfer schließt nun das native
Ablehnungsmenü; die Navigation verwirft diesen Weg und sucht einen anderen.
Spielergeometrie oder Surfer-Regeln wurden dafür nicht gelockert. Außerdem
wurden nicht lesbare Pfeilzeichen durch „TO“/„ZU“ ersetzt. Menü und
klassische Regigigas-Kampfgrafik wurden visuell geprüft.

41 neue Questprüfungen und 78.351 Inselintegrationsprüfungen bestehen.
`rocket-transition-native3.log`, Exitcode 0, prüft mit dem fertigen
Regigigas-Umzug erneut die echten Lade-/Archiv-/Verwahrungswege. Eine
unbesessene Genesect-Rettung bleibt erhalten; Darkrai und Regigigas sind
auf Sevii verlegt. Frühere Regigigas-/Darkrai-Fangbelege werden übernommen
und bleiben nach Löschen der alten Raid-Belege sowie über Legacy erhalten.
`legend-catalog-native4.log`, Exitcode 0, erfasst die neuen und abgelösten
Besitzer aller 23 Sonderarten.

Für Regigigas wurden **17 vorhandene Grafik-/Rufdateien** geprüft und im
isolierten QA-Paket verknüpft: Late-Species-Front/Back, Icons, Follower und
Ruf sowie beide klassischen Pixelvarianten. Die Grafik-Hashes stimmen
mit den bestehenden Sprite-Manifesten überein, der Ruf mit der Basisdatei.
`SEVII_SPECIAL_ASSETS.json` umfasst jetzt **74 Dateien für sieben Arten**;
alle Hashes wurden gegen das aktuelle QA-Paket verifiziert.

**Stand nach Regigigas: sieben von 13 Gen-4-Sonderpfaden nativ geprüft.**
Dialga, Palkia, Phione, Manaphy, Shaymin und Arceus bleiben offen,
ebenfalls die ältere Legendenkontinuität, weitere Items/Gebäudefunktionen
und das fertige Installationspaket. Giratina bleibt bewusst ausgenommen.


## Heimweg der Strömung: Phione und Manaphy

`sevii_tidal_return.lua` ergänzt neun feste Standorte für Tamo, Neris
Anlegeplatz und Rückkehr, Reparaturplanke, drei Küstensignale und zwei
Begegnungssteine. Die Quest setzt Liga, örtliches Finale und Jenseits von
Kanto voraus. Der Abschlussbericht nach Neris tatsächlicher Rückkehr
schaltet Phione auf Level 55 und Manaphy auf Level 65 über denselben
geschützten Begegnungsbesitzer frei. Generationsprofil, vollständige
Grafiken, lesbare Besitzhistorie, gesundes Team und erfolgreiches Speichern
bleiben Voraussetzung für den Kampfbeginn.

Die einmalige Planke ist ein Questbeleg, kein verkäufliches Beutel-Item.
Beim Reparieren wird sie verbraucht. Die Signale zählen nur am jeweils
richtigen Standort in der Reihenfolge Norden/Mitte/Süden. Fehlversuche
setzen bereits bestätigte Passagen nicht zurück. Neri verschwindet nach
der ersten Passage vom Inselstandort und erscheint nach der dritten im
Haus. `S.install` stellt diese Sichtbarkeit auch nach Laden und
Kartenwechseln wieder her; der Spieler erhält keinen zusätzlichen Begleiter
und seine Pokémon-Follower-Einstellung bleibt unverändert.

`tidal-native1.log` und `tidal-return.json`, Exitcode 0: **1.358 echte
Schritte, 76 Kartenübergänge, 18 Türen und eine Rückfähre**. Der Prüflauf
besucht alle Questorte, verweigert Signale vor der Reparatur, birgt und
verbraucht die Planke, lädt nach den Teilabschnitten, verweigert ein
vorgezogenes Süd-Signal, prüft die physische Abwesenheit Neris am alten
Ort sowie ihre sichtbare Rückkehr und spricht mit ihr im Haus. Erst danach
folgen Bericht und beide echten Fänge. Nach erneutem Laden befindet sich
jeweils genau ein Exemplar im Spielstand; die Inselquellen verweigern eine
Wiederholung. Anschließend führt der echte Weg zurück nach Orania.
Liga, Finale, Team, Orden, Anfangshafen und Meisterbälle sind Fixtures;
gewöhnliche Wildbegegnungen sind deaktiviert. Die Bootsfahrt wird erzählt,
nicht als fahrendes Boot gerendert. Der Lauf ist kein Balancenachweis.
Rückkehrszene und beide klassischen Kampfgrafiken wurden visuell geprüft.

46 neue Questprüfungen und 78.369 Inselintegrationsprüfungen bestehen.
Der bestehende Regigigas-Questtest besteht ebenfalls. Für beide neuen Arten
wurden je acht Backend-Grafiken aus dem vorhandenen Cache gegen die
Sprite-Manifeste geprüft und im isolierten QA-Paket verknüpft. Das
Spezialmanifest umfasst jetzt **90 Dateien für neun Arten**; alle aktuellen
Hashes sind geprüft. `legend-catalog-native5.log`, Exitcode 0, erfasst
alle neun Sonderbegegnungsbesitzer und alle 23 besonderen Zielidentitäten.

**Aktueller Inselstand: neun von 13 Gen-4-Sonderpfaden nativ geprüft.**
Dialga, Palkia, Shaymin und Arceus fehlen weiterhin. Eine vollständige
Einzigartigkeitszusage über alle Erwerbswege bleibt vom globalen Audit
abhängig; Fang- und Geschenkprüfung allein decken nicht automatisch
Pension, ältere Sonderquellen und alle Legacy-Zustände ab.


## Pension: neue Sonder-Eier und vorhandener Besitz

Der native Audit `legend-breeding-native2.log` zeigte eine echte Lücke:
Alle 13 Gen-4-Sonderarten waren durch KASCs Typgruppen mit Ditto kompatibel.
Die Sevii-Regel verhindert jetzt neue Nachkommen dieser 13 Arten sowie
Giratinas in Kompatibilität, Artbestimmung und neuen Ei-Reservierungen.
Dies ist eine bewusst gesetzte Einzigartigkeitsregel der Erweiterung,
keine Aussage über das kanonische Zuchtverhalten von Manaphy/Phione.

`legend-breeding-native3.log`, Exitcode 0, prüft 24 kanonische Sonderarten
(zehn Hoenn-Arten, 13 Gen-4-Arten und Giratina): keine möglichen neuen
Nachkommen; Karpador mit Ditto bleibt kompatibel. Der getrennte Lauf
`nursery-native2.log`, Exitcode 0, prüft tatsächliche Welt-Schritte,
Elterntraining, verweigerte neue Reservierung, Abholen und Ausbrüten eines
bereits vorhandenen Phione-Eis sowie Speicherung/Laden. Ein gewöhnliches
Karpador-Ei entsteht weiterhin durch einen Welt-Schritt und wird abgeholt.
Eltern, das historische Ei, das Profil und der erfolgreiche Zufallswurf
sind Fixtures; kein vollständiger Pensions-Menüdurchlauf.

Abgegebene Eltern und bereits produzierte, wartende Pensions-Eier zählen
jetzt als vorhandener Besitz. Ihre Historie bleibt nach Abholen erhalten.
Nicht ausgegebene Geschenkcode-Reservierungen zählen weiterhin nicht.
Bestehende Pokémon und Eier werden nicht gelöscht; Abholen, Ausbrüten und
Training bleiben verfügbar. 54 Historien-Funktionsprüfungen bestehen.


## Was wieder wächst: Shaymin

`sevii_garden.lua` ergänzt Oda im Beerenladen von Eiland Drei und Rika im
Beerenforst, Beetmarkierung, Geröll, Schleusenmarkierung und Shaymins Stein.
Alle sechs Standorte sind auf begehbaren Zellen, ohne NPC-/Türüberlagerung.
Liga, Expedition, örtliche Versiegelung und Jenseits von Kanto sind nötig.
Die Arbeit umfasst untersuchtes Beet, freigeräumten Zulauf, langsame
Bewässerung und Pflanzung. Samen sind einmaliges Expeditionsgepäck, werden
nicht durch einen Fehlversuch verbraucht und beim Pflanzen genau einmal
entfernt. Das Geröll verschwindet physisch und bleibt nach Laden entfernt.

Alle drei Dankesantworten sind gültig. Die gewählte Widmung wird gespeichert
und im Journal angezeigt. Oda nimmt erst nach der Bepflanzung und dem
Dankesschild den Abschlussbericht an. Die Quest ist ohne Fang abgeschlossen;
auch frühere Besitzer können sie beenden. Shaymin auf Level 65 verwendet
den gemeinsamen, durch Besitzhistorie und konkrete Kampfberechtigung
geschützten Begegnungsbesitzer. Giratina bleibt nicht fangbar.

`garden-native1.log` und `forest-garden.json`, Exitcode 0: **1.764 echte
Schritte, 110 Kartenränder, 14 Türen und eine Rückfähre**. Geprüft wurden
Verweigerung vor dem Finale, trockene Aussaat ohne Samenverlust, physisches
Entfernen des Gerölls, falsche/richtige Schleusenwahl, gespeicherte
Zwischenstände, einmaliger Samenverbrauch, Bericht vor Dank abgewiesen,
Dankeswahl für die Pokémon (nicht nur die Alles-Option), abgeschlossene
Quest ohne Fang, tatsächlicher Shaymin-Fang, genau ein gespeichertes
Exemplar nach Laden, verweigerte Wiederholung und Rückkehr nach Orania.
Die aktuelle Fassung ergänzt danach die gespeicherte Widmung im Journal;
deren drei Varianten werden durch Funktionsprüfungen abgedeckt.

Liga/Finale, Team, Orden, Ausgangshafen und Meisterbälle sind Fixtures;
gewöhnliche Begegnungen sind deaktiviert. Kein Balancenachweis. Wasserfluss
und Wachstum werden erzählt; lediglich das Geröll erhält eine tatsächliche
Sichtbarkeitsänderung. Lichtung und klassische Shaymin-Kampfgrafik wurden
visuell geprüft. 43 Questprüfungen und 78.381 Integrationsprüfungen bestehen.
Acht Grafikdateien stammen aus dem vorhandenen Cache und stimmen mit den
Sprite-Manifesten überein. Das Spezialmanifest enthält **98 geprüfte Dateien
für zehn Arten**. `legend-catalog-native6.log`, Exitcode 0, bestätigt den
neuen Fangbesitzer und weiterhin alle 23 besonderen Zielidentitäten.

**Aktuell zehn von 13 Gen-4-Sonderpfaden nativ geprüft.** Dialga, Palkia
und Arceus fehlen. Das globale Audit älterer Legenden, zusätzliche Items,
Gebäudefunktionen, aktueller Gesamt-/Upgrade-Test und Paket bleiben offen.


## Takt und Grenze: Dialga und Palkia

`sevii_time_space.lua` ergänzt zwölf Orte: Levin, eine Uhr, drei
Messgeräte, vier Richtungsmarkierungen, ein mittleres Instrument und
zwei Begegnungssteine. Im Punktloch werden die tatsächlichen Geräte
gelesen; die Uhr verlangt den ersten positiven gemeinsamen Schlag
der Abstände 3/4/6, also 12. In der Wandelhöhle wird am Instrument
begonnen, Westen/Norden/Osten/Süden bestätigt und zur Mitte zurückgekehrt.
Eine falsche Markierung setzt die aktuelle Reihenfolge zurück. Verlassen
der Höhle beendet nur einen unfertigen Messweg. Ein geladenes Spiel
innerhalb der Höhle behält seinen Zwischenstand; interne Kartenfragmente
werden anhand derselben Originalhöhle erkannt.

Erst beide Messungen und Levins Bericht schließen den Bogen ab. Die
Fanggelegenheiten für Dialga und Palkia auf Level 75 sind danach optional.
Die Forschung öffnet den örtlichen Übergang nicht erneut, besiegt oder
fängt Giratina nicht und verlangt keine früheren legendären Fänge.

`time-space-native1.log` und `time-space.json`, Exitcode 0: **1.892 Schritte,
92 Kartenränder, 39 Türen, eine Rückfähre**. Echte Wege durch Punktloch und
Wandelhöhle, Messgeräte, verweigerte Antwort ohne Messwerte, verweigerter
späterer gemeinsamer Takt 24, richtige Kalibrierung, falsche Markierung,
Teilweg/Laden, tatsächlicher Ausgang und Wiedereintritt, bewahrte Uhrenarbeit,
richtiger Rundweg, Bericht, beide echten Fänge, jeweils genau ein Exemplar
nach Laden, Wiederholungssperre und Orania-Rückkehr bestanden.

54 Questprüfungen bestehen. Die Integration nach diesem Bogen betrug
78.405 Prüfungen. Liga/Finale, Team, Orden, Ausgangshafen und Meisterbälle
sind Fixtures, gewöhnliche Begegnungen deaktiviert. Kein Balancenachweis
oder neu animierter Raum-Zeit-Effekt. Uhrmenü sowie Dialga-/Palkia-Grafiken
wurden visuell geprüft. Je acht vorhandene Backend-Dateien wurden gegen
die Sprite-Manifeste validiert.


## Sieben Zeugnisse: Arceus und fangunabhängiger Abschluss

`sevii_seven_testimonies.lua` ergänzt Sora, sieben Berichte in den
Obergeschossen der Insel-Pokémon-Center und den Stein in der Monean-Kammer.
Jeder Bericht prüft den tatsächlichen Abschluss seiner Forschung: Heatran-
Druckausgleich (`open`), Drei Stimmen, Waldgärtnerei, friedliche Nacht,
Bootsrettung, Takt und Grenze sowie der schlafende Riese. Besitz allein
ersetzt keinen Forschungsabschluss. Weder Fänge noch Eier/Geschenke sind
Voraussetzung. Die sieben Kopien überdauern Speichern; erst alle zusammen
erlauben Soras Buchabschluss. Die Begegnung mit Arceus auf Level 80 setzt
zusätzlich das abgeschlossene Vorlesen am Tanoby-Stein voraus.

Dabei wurde eine ältere Blockade im Heatran-Mysterium korrigiert:
Forschungsbeginn, Messwerte und Ventile prüfen nun Liga, Finale und Jenseits
von Kanto getrennt von der Fangverfügbarkeit. Ein früherer Heatran-Besitzer
kann die Druckleitungen vollständig reparieren. Artgrafiken, Profil,
Besitzhistorie, gesundes Team und erfolgreiches Speichern bleiben für den
optionalen Fang erforderlich. 58 Heatran-Funktionsprüfungen bestehen,
einschließlich Forschung mit bestehendem Besitz/fehlender Fangverfügbarkeit.

`testimonies-native1.log` und `seven-testimonies.json`, Exitcode 0:
**1.764 Schritte, 64 Kartenränder, 72 Türen, acht Fähren**. Der Test beginnt
mit einem vorhandenen Heatran, verweigert dessen Bericht vor der Forschung,
spielt alle drei Messgeräte und die Ventilfolge tatsächlich, lädt einen
Zwischenstand, verweigert einen neuen Heatran-Kampf und behält genau das
vorhandene Exemplar. Danach werden alle sieben Berichte über echte Reisen
und Treppen kopiert und nach Laden geprüft. Sora bindet das Buch; das
Vorlesen, tatsächlicher Arceus-Fang, genau ein Exemplar nach Laden,
Wiederholungssperre und Rückreise nach Orania bestehen.

Die sechs anderen Forschungsabschlüsse, Liga/Finale, Team/Orden, alter
Heatran, Anfangshafen und Meisterbälle sind Fixtures; Zufallsbegegnungen
sind aus. Deren einzelne Questabläufe haben eigene native Nachweise.
Dieser Lauf ist kein erneuter Gesamtdurchlauf aller Voraussetzungen und
kein Balancenachweis. Die Begegnung am Stein wird erzählt, ohne zusätzliche
Arceus-Zwischensequenzgrafik. Die klassische Kampfgrafik wurde angesehen.
58 neue Zeugnisprüfungen und aktuell 78.423 Integrationsprüfungen bestehen.

**Alle 13 vorgesehenen Gen-4-Sonderpfade sind einzeln nativ geprüft.**
Das Grafikmanifest umfasst 122 Dateien für diese 13 Arten. Giratina
bleibt ausgenommen und wird nicht neu ausgegeben. Ältere Legenden,
zusätzliche Item-/Gebäudefunktionen, aktuelle Gesamt-/Upgrade-Prüfung
und das installierbare Erweiterungspaket bleiben ausdrücklich offen.

Aktueller Katalog: `legend-catalog-native8.log`, Exitcode 0, verlangt nun
ausdrücklich 13 Gen-4-Sevii-Fangbesitzer mit vollständigen Grafikdateien.
Alle 122 Dateien wurden gegen ihre aktuellen SHA-256/Größen geprüft.

## Lavados: dauerhafter Besitz und Vulkanabschluss ohne zweiten Fang

Lavados und seine Galar-Form teilen jetzt den kanonischen Besitzbeleg
`146` in `hevo_persistent.seviiLegendOwned`. Neben den bereits geprüften
Team-/Box-/Bank-/Geschenk-/Pensionsquellen werden die alten Vulkanbelege
`hoenn_moltres_volcano_67.caught` und
`kaHoennEndgameRunEvents67.completed.MOLTRES` übernommen, **nur wenn
`captured == true`**. Ein alter Sieg ohne Fang zählt ausdrücklich nicht als
Besitz. Die Legacy-Normalisierung erhält den zusätzlichen Schlüssel.
Ein späterer Durchlauf setzt weiterhin das Rätsel zurück, nicht den Besitz.
Neue Geschenke, Eier und Fänge können daher keine zweite garantierte
Lavados-Identität erzeugen; vorhandene Exemplare werden nicht verändert.

Der Vulkan bleibt sein bestehender Fangort. Für einen früheren Besitzer
zeigt der Gipfel einen Fundmarker für eine erinnernde Feder statt eines
zweiten Vogels. Das vollständige Vulkanrätsel bleibt erforderlich. Erst
anschließend bestätigt ein freiwilliger Dialog den Abschluss mit
`battleResult = witnessed`, `captured = false`. Dies erfüllt den bestehenden
Vulkan-Fortschritt zur Entstehungsinsel ohne erfundenen Fang. Ein
fehlgeschlagenes Speichern nimmt diesen neuen Abschluss zurück; die
Bestätigung bleibt wiederholbar. Ein nicht lesbares Besitzarchiv erklärt
am Fundmarker die Sperre und eröffnet keinen Kampf. Unbesessene Lavados
behalten ihre bisherige Begegnung. Eine Prüfung nach dem Einleitungstext
verhindert, dass ein inzwischen veränderter Spielstand oder Besitzstand
ungeprüft den Kampf eröffnet.

`moltres-continuity-native1.log`, Exitcode 0, und
`moltres-continuity.json`: echtes historisches Geschenk, beide kanonischen
Formen, vollständiger Vulkanweg mit zwei Sätzen Bohrsteinen, vier Blockaden,
Magmar-Kampf/Fang und drei Schloteinstellungen, sichtbarer Fundmarker,
Speicherfehler/Wiederholung, tatsächlicher Abschlussdialog, Rückweg nach
Zinnober und genau ein Lavados nach Laden. Direkter Meisterballgebrauch
und die endgültige Fangberechnung verweigern ein zweites Exemplar. Nach
gezieltem Entfernen des QA-Pokémon bleiben erneute Geschenke gesperrt;
`beginJourney`/`seedNewSave` übernehmen den Beleg trotz zurückgesetztem
Vulkanereignis. 61 Historien- und 20 Vulkan-Kontinuitätsprüfungen bestehen;
die Sevii-Kartenintegration besteht weiterhin mit 78.429 Prüfungen.

Liga, Team/Orden, erste Position, Expeditions-Einstiegs-API, Meisterball und
Entfernen des alten Lavados sind Testvorbereitungen. Das ist kein Nachweis
der PC-Freilassen- oder vollständigen NG+-Menüoberfläche und kein
Balancenachweis. Der sichtbare Marker verwendet die vorhandene Fundgrafik,
keine neu gezeichnete Feder. Die restlichen älteren Legenden und insbesondere
die charaktergebundenen Hoenn-Zugänge bleiben offene Arbeiten.

Der Kontrolllauf `legend-policy-native5.log`, Exitcode 0, bestätigt nach der
Lavados-Erweiterung weiterhin Giratinas sechs Geschenkprofile, beide Formen,
Belegübernahme/Zurückstellung, andere tatsächliche PC-Geschenke und die
Meisterball-Sperre. Ein noch unbesessenes Lavados außerhalb Sevii wird von
der allgemeinen Fangrichtlinie weiterhin zugelassen.

`legend-history-native5.log`, Exitcode 0, prüft zusätzlich den ersten echten
nativen Fang eines zuvor unbesessenen Lavados außerhalb Sevii und danach
die zweite Meisterball-Sperre, Laden und Legacy-Übernahme. Derselbe Lauf
wiederholt Heatran-Fang, Geschenk-Ei, entferntes Geschenk, misslungenes
Speichern und Wiederholung. Das bestätigt den allgemeinen Besitzübergang;
der Vulkanweg für frühere Besitzer ist separat durch den obigen Lauf belegt.

## Drei Tanoby-Hüter: Regirock, Regice und Registeel

Nach dem vollständigen Rätsel und Bericht von „Der schlafende Riese“
**und** dem jeweiligen Originalrätsel samt Hoenn-Zugang im aktuellen Durchlauf
antworten alternativ dieselben drei kleineren Hüter an ihren bereits untersuchten
Inschriften: Regirock in Liptoo, Regice in Weepth, Registeel in Scufib.
Jede Begegnung ist freiwillig, Level 65 und ab Gen-3-Regeln möglich.
Regigigas bleibt Level 75 und benötigt Gen 4. Rhea und das gemeinsame
Journal nennen alle vier Orte. Der Forschungsabschluss und Arceus'
Zeugnis erfordern weiterhin **keinen Fang**.

Die drei neuen Begegnungen verwenden denselben streng an die laufende
Kampfinstanz gebundenen Besitzer wie die übrigen Inselmysterien. Giratina
bleibt davon ausgeschlossen. Die Historie übernimmt alte wirklich gefangene
Regis aus den Heiligtums-/Durchlaufbelegen und dem vorhandenen lokalen oder
archivierten `hoennDexOwned`. K.-o.-Abschlüsse allein zählen nicht als Besitz.
Die zusätzlichen kanonischen Schlüssel 377–379 bleiben bei Legacy erhalten.

Die früheren Heiligtümer bleiben mit ihren physischen Rätseln erhalten.
Frühere Besitzer sehen am Ziel einen Erinnerungsmarker statt eines zweiten
Pokémon. Erst nach dem eigenen Heiligtumsrätsel lässt sich dessen Abschluss
freiwillig mit `witnessed` und `captured = false` bestätigen. Die getrennte
Regirock-Voraussetzung für die Entstehungsinsel bleibt damit erfüllbar.
Fehlgeschlagenes Speichern lässt die Bestätigung offen. Noch unbesessene
Regis können weiterhin zuerst am alten Ort gefangen werden; danach sperrt
dieselbe Historie das zweite Exemplar auf Sevii und weitere Geschenke/Eier.

Historischer Stand vor der Kontinuitätskorrektur: 61 Quest-/Profilprüfungen, 85 Historienprüfungen und 51 Heiligtumsprüfungen
bestehen. Die Kartenintegration bleibt bei 78.429. Für die drei Arten wurden
39 benötigte Grafikdateien anhand ihrer vorhandenen Paketmanifeste geprüft
und im isolierten QA-Paket bereitgestellt. Das zusätzliche Manifest umfasst
jetzt 161 Dateien für 16 Sonderarten. Die drei klassischen Kampfgrafiken
wurden im Spiel betrachtet.

Der erste kombinierte Lauf deckte einen bestehenden Eintrittsfehler auf:
`onEnter` aktualisierte die Objektsichtbarkeit erst nach dem Kartenaufbau.
Wenn der Hoenn-Dex erst nach dem letzten Laden verfügbar wurde, fehlte der
Technikstein physisch, obwohl die vier Regirock-Schritte korrekt registriert
waren. `S.enter` setzt die aktuellen Sichtbarkeiten jetzt **vor** dem Warp.
Ein gezielter Unit-Nachweis prüft die Technik-/Siegel-/Erinnerungsobjekte zum
Zeitpunkt des Kartenwechsels. Der zusätzliche native `core.update`-Aufruf im
Prüftreiber entspricht dem bestehenden Prüfaufbau für Regices Zeiträtsel;
er allein behob den fehlenden Regirock-Stein nicht.

`regi-return-native4.log`, Exitcode 0, besteht mit **1.319 echten Sevii-
Schritten, 68 Kartenrändern, 24 Türen und einer Fähre**: komplette Forschung,
falsche Waage/Reset/Teilstand/Laden, alle vier Tanoby-Fänge samt Einzelbesitz,
Generationsprofile 2/3/4 und Rückfahrt nach Orania. Anschließend werden alle
drei ursprünglichen Heiligtumsrätsel mit echten Eingaben gelöst – auch die
zwei Minuten Regice-Stillstand über die Spielzeit. Die freiwilligen
Erinnerungsdialoge, Speicherfehler/Wiederholung, Rückwege und eine echte
Legacy-Archivtransaktion sind bestanden. Die beiden pauschalen alten
Test-Rückkehrkoordinaten in Seeschaum/Siegesstraße wurden vom Host beim
Laden korrigiert; ein strengerer Lauf mit begehbaren Ausgangspunkten wird
separat verzeichnet.

Liga/Finale, Team/Orden, erster Sevii-Hafen, deaktivierte gewöhnliche
Begegnungen, Meisterbälle und Hoenn-Dex sind Fixtures. Die alten Kanto-
Ausgangsorte werden per Test-Teleport erreicht und ihre Heiligtümer per
bestehender Eintritts-API betreten. Die Wegzahlen zählen nur die Sevii-
Reise; es ist kein Durchspielen sämtlicher alten Kanto-Zuwege, kein
Balancenachweis und kein vollständiger NG+-Menütest.

`legend-catalog-native9.log`, Exitcode 0, erkennt die drei neuen Inselbesitzer
zusätzlich zu allen 13 Gen-4-Besitzern und führt die weiter vorhandenen
Hoenn-Heiligtümer getrennt als alternative Fangwege auf. Alle 23 Sonderarten
bleiben aus gewöhnlichen Sevii-Begegnungen ausgeschlossen. Der aktuelle
Pensionsabgleich `legend-breeding-native4.log`, Exitcode 0, weist weiter
keine erzeugbare Sonder-Nachzucht unter den 24 geprüften Identitäten nach;
gewöhnliches Karpador bleibt kompatibel. Dies ist ein Registry-/API-Abgleich,
kein erneuter vollständiger Pensionslauf.

Der damalige strengere Lauf **`regi-return-native5.log`, Exitcode 0**,
und `regi-return.json` wiederholen den ganzen kombinierten Nachweis mit
begehbaren Kanto-Testausgangspunkten. Physische Rückkehr und geladene
Koordinaten stimmen jetzt überein; der Host meldet keine Positionsreparatur.
Die bestehende Vulkan-Sicherungsregel versetzt einen auf dem externen
Aufstieg gespeicherten Spielstand weiterhin planmäßig nach Zinnober.
Alle vier Pokémon bleiben nach Laden genau einmal vorhanden; alle drei
Heiligtumsabschlüsse werden ohne Fang erteilt und die vier Besitzbelege
377, 378, 379 und 486 über eine echte Legacy-Transaktion übernommen.
Die übrigen oben genannten Fixtures und Nachweisgrenzen gelten unverändert.

Aktueller Lauf `legend-catalog-native10.log`, Exitcode 0: 23 Identitäten,
13 Gen-4-Inselbesitzer, drei Regi-Alternativen mit Originalvoraussetzungen.
Der Lauf prüft ausdrücklich, dass die verworfenen Wetterlegenden-Zugänge
nicht registriert sind; ihre ursprünglichen Charakterkammern bleiben im
lebenden Quellenkatalog enthalten. `SEVII_LEGEND_SOURCES.json` ist damit
aktualisiert; individuelle native Nachweise bleiben getrennt aufgeführt.

## Wandergebiet von Latias und Latios – präzisierte Spielregel

Die bestätigte Regel lautet: Jeder freigeschaltete, noch ungefangene Wanderer
besitzt einen gespeicherten Aufenthaltsort im gemeinsamen Wandergebiet aus
Kanto und Sevii. Der Spieler muss diesen Ort zufällig treffen. Erst dort gibt
es pro geeignetem Begegnungsschritt einen gemeinsamen 1-aus-20-Wurf (5 %).
Die Chance gilt **nicht weltweit pro Schritt** und **nicht beim Kartenwechsel
für ein Erscheinen am Spieler**. Sind ausnahmsweise beide am selben Ort,
bleibt es ein einzelner 5-%-Wurf mit anschließender Auswahl einer Identität.
Ein erfolgloser Wurf setzt den Aufenthaltsort nicht neu.

Sevii kommt nach dem örtlich versiegelten Finale hinzu. Küstenfragmente
zählen zusammen als ein ursprüngliches Gebiet; Höhlen, Tunnel, Häuser,
Center und Tempelinnenräume sind ausgeschlossen. Die bisherigen 21
Kanto-Routen bleiben im Zielpool. Hinzu kommen alle weiteren Außenkarten
des Kanto-Grundspiels: insgesamt 45 einschließlich Städten, Seerouten,
Wäldern, Safari-Flächen, Dachterrassen und Schiffsbug/Hafenkai.
Die gesondert geprüften KASC-Außenkarten Vulkanfuß und Himmelsplattform
sind ebenfalls enthalten; die Himmelsplattform setzt ihre ursprüngliche
GREEN-/Hoenn-Portalberechtigung voraus.
Hoenn-Zugang, Abschalten der Wanderer, Schutz und bestehende KO-Erholung
bleiben wirksam. Ein bereits gefangenes oder anderweitig erhaltenes Exemplar
sperrt weitere Exemplare auch über die gemeinsame Besitzhistorie.

Aktuelle automatisierte Belege: 53 Wanderer-Kontinuitätsprüfungen,
16 Oberflächen-/Wiederherstellungsprüfungen, 99 Historienprüfungen und
78.497 Sevii-Integrationsprüfungen bestanden.
Enthalten sind falscher Aufenthaltsort ohne Würfelaufruf, genau einer von
20 Ergebnissen am richtigen Ort, beide Identitäten am selben Ort,
Kartenfragmente, fehlende Historie, originale Freigaben, alter Spielstand
im Kampf und Schutz vor erfundenen Fangbelegen. Native Spieltests werden
unten mit ihrem jeweiligen tatsächlichen Ergebnis ergänzt.

### Nativer Nachweis der Eon-Ortsbindung

`eon-native2.log`, Exitcode 0, und `eon-roaming.json` belegen zwei echte
Schrittbegegnungen: Latias an Land auf Eiland Eins und Latios surfend am
Resort auf Eiland Fünf. Am falschen gespeicherten Aufenthaltsort wurde kein
5-%-Wurf ausgeführt; Ergebnis 20 am richtigen Ort erzeugte keinen Kampf.
Schutz blockierte beide unterlevelten Wanderer und wurde dabei regulär um
einen Schritt verbraucht. Ergebnis 1 führte jeweils über die native
Schrittpipeline in den gebundenen Wandererkampf. Beide tatsächlichen Fänge
und das anschließende Speichern/Laden behielten die Besitzsperre bei.

Freischaltungen, aktueller Aufenthaltsort, Team und Zufallszahlen sind
kontrollierte QA-Fixtures. Unbeteiligte gewöhnliche Begegnungen wurden im
Treiber ausgefiltert. Dies ist kein Balancenachweis, kein vollständiger
Weltkarten-Durchlauf und kein nativer Legacy- oder Flucht/Wiedersehen-Test.
Lauf v1 endete an einer unpassierbaren Testkoordinate; der Treiber wählt
in v2 eine echte begehbare Schrittfolge. Der Fehler betraf die Fixture,
nicht die Spielkarte, und v1 liefert keinen Erfolgsnachweis.

### Aktueller vollständiger Kanto-Durchlauf und Legacy

`eon-native4.log`, Exitcode 0, prüft echte Schrittbegegnungen auf allen
45 klassifizierten Kanto-Außenkarten, jeweils mit anschließendem nativen
Fliehen. 41 Flächen verwenden den neuen Außenboden-Aufruf, drei benutzen
die schon vorhandene Bodenabfrage (das Label `indoor` ist hier nur der
Engine-Aufruf, kein Höhlenfundort), eine ist eine Surf-Begegnung.
Alle vier Safari-Außenkarten behalten ihre Safari-Kampfform.

Der Wanderer behält über die Wiederbegegnungen identische DVs und
abgeleitete Statuswerte. Korrigiert wurde dafür die Übernahme frisch
gewürfelter Konstruktor-Statuswerte trotz wiederhergestellter alter DVs.
Nach den 45 Fluchten folgen erneut die beiden echten Sevii-Fänge samt
Schutz-/Falschort-/Fehlwurfprüfung und Laden. Anschließend führt der Test
eine tatsächliche Legacy-Archivierung und Neuspiel-Saat ohne mitgeführte
Legenden aus: Die Besitzhistorie für 380 und 381 bleibt erhalten.

Der Host-Schritt bleibt für Story, Warp, Gift, Schutzablauf und Kampf-Gnaden-
schritte zuständig. Nur während eines synchronen zugelassenen Außenschritts
wird dessen Bodenprüfung erweitert. Neue Außenböden bekommen ausschließlich
ein gültiges Wanderer-Angebot, niemals den gewöhnlichen Gras-Pool. Originale
Konfiguration und Methode werden auch bei Fehlern und vorzeitigen Rückgaben
wiederhergestellt; hierfür bestehen 16 gezielte Prüfungen. Keine Änderung
an den installierten Engine-Dateien ist erforderlich.

Die Ausgänge und Aufenthaltsorte sind für diesen Flächenbeleg kontrollierte
Fixtures; Trainerblick und gewöhnliche Zufallsbegegnungen sind im Treiber
unterdrückt. Der Lauf ersetzt keinen vollständigen Weltkarten-Spieldurchlauf,
keinen Balancetest und keinen NG+-Menütest. Er belegt die tatsächlichen
Schritt-/Kampf-/Speicher- und Archivschnittstellen. `eon-native3.log` bestand
bereits die 45 Flächen; v4 ergänzt die explizite Werte- und Legacy-Prüfung.


### KASC-Außenkarten und gesperrte Aufenthaltsorte

`eon-native5.log`, Exitcode 0, erweitert den vorherigen Durchlauf auf 47
Außenkarten (45 Grundspiel + Vulkanfuß + Himmelsplattform), einschließlich
identischer Werte, beider Sevii-Fänge, Laden und tatsächlicher Legacy-Übernahme.
Die Himmelsplattform ist keine neue Freigabe: `mapAccessible` delegiert an
den bestehenden Hoenn-Portalbesitzer. Der native Geometrietest ersetzt dessen
Zugangsantwort ausdrücklich durch eine positive Fixture; die 24 gezielten
Oberflächenprüfungen belegen die Delegation und Ablehnung bei geschlossenem
Zugang. Eine vollständige neue Portalquest wird damit nicht behauptet.

Wird ein früherer Aufenthaltsort durch eine geschlossene Freigabe unzulässig,
zieht derselbe Wanderer in ein noch zugelassenes Gebiet. DVs, KP und Status
bleiben erhalten. 55 Kontinuitätsprüfungen decken diesen Fall zusätzlich ab.
Der Quellenkatalog `package-dev1-qa/legend-catalog-native12.log`, Exitcode 0,
prüft bereits die materialisierte Paketkopie mit beiden Zusatzkarten.

## Ursprüngliche Hoenn-Legenden: Besitz und Forschung getrennt

Kyogre, Groudon, Rayquaza, Jirachi und Deoxys sind jetzt Teil der gemeinsamen
kanonischen Besitzhistorie. Es gibt dafür **keinen neuen Insel-Fangort**.
Die drei Wetterlegenden verlangen weiterhin den jeweiligen Charakterpfad,
das aktuelle HEVO-Siegel und die Hoenn-Grundforschung. Alte echte Fangbelege,
ausgelieferte Geschenke, Bank und Legacy zählen auch nach einem Freilassen.
Andere Formen schaffen kein zweites Exemplar.

Wer eine dieser Legenden schon erhalten hat, kann am ursprünglichen Ort
einen getrennten Forschungsabschluss bestätigen. Die drei Wetter-Siegel und
Jirachis Zertifikat verwenden `KA_LEGEND_WITNESS_*`; die vorhandenen
`KA_LEGEND_CAPTURE_*` werden dadurch niemals gesetzt. Der Dex-Bericht
unterscheidet echte Fänge, Forschungsbestätigungen und deren Vereinigung.
Beide Abschlussarten können die Forschung weiterführen; sämtliche bisherigen
Charakter- und Besitzanforderungen bleiben bestehen.

Die Entstehungsinsel verlangt zusätzlich weiterhin die Lavados- und
Regirock-Abschlüsse **dieses Durchlaufs** und das vollständige Dreieckrätsel.
Ihr Forschungsbeleg ist ausdrücklich `captured=false, battleResult=witnessed`.
Neue echte Deoxys-Fänge schreiben dagegen `captured=true, battleResult=caught`.
Die Migration erkennt auch die alte Fangform mit Karte und Level, deren
früherer Normalisierer `captured` auf false setzte. Ein heutiger Forschungs-
oder Siegbeleg zählt dadurch nicht versehentlich als Besitz.

`hoenn-continuity-capture3.log` und `hoenn-continuity-witness2.log` enden
jeweils mit Exitcode 0. Der erste Lauf fängt alle fünf am alten Ort im
nativen Spiel. Der zweite liefert zuerst alle fünf über den echten
Geschenkbesitzer aus, entfernt gezielt diese Objekte als Freilassen-Fixture
und spielt danach die fünf Forschungsabschlüsse ohne neue Pokémon.
Beide spielen das Dreieckrätsel, speichern/laden, verweigern zweite
Meisterbälle vor Verbrauch und prüfen die echte Legacy-Archivierung plus
Neuspiel-Saat. Das Zertifikat wurde als native Ansicht visuell geprüft.
Vorbereitete Liga, Team, 130 Grundarten, Hoenn-Honig/Dex, historische Pfade,
Charaktersiegel und Zuwege ersetzen keinen vollständigen HEVO-/NG+-Menülauf.
Auch die aktuellen Lavados-/Regirock-Ereignisse sind hier Fixtures; ihre
eigenen Rätseltests bleiben die gesonderten Nachweise.

53 Hoenn-Kontinuitäts- und 132 Historienprüfungen bestehen. Die vorhandenen
51 Regi-, 20 Lavados-, 55 Eon- und 78.497 Integrationsprüfungen bestehen
weiterhin. `legend-catalog-native13.log`, Exitcode 0, bestätigt den aktuellen
23-Arten-Katalog und die gemeinsame Anbindung aller sechs alten Fangmodule.
Die Anbindung erfolgt erst nach erfolgreichem Inselimport: Ohne optionales
Kartenpaket bleiben die bisherigen Kanto-Module benutzbar; ein tatsächlich
angebundenes, aber unlesbares Archiv wird weiterhin nicht als leer behandelt.

Dieser Quellstand ist neuer als das unveränderte Entwicklungs-ZIP `dev1`.
Die vollständige Erweiterung bleibt in Arbeit. Der anschließende Abgleich der
alten Kanto-/Johto-Wege steht im nächsten Abschnitt.

## Alte Kanto-/Johto-Legenden und Legacy-Partner

Die gemeinsame Besitzhistorie umfasst jetzt zusätzlich Arktos, Zapdos,
Mewtu, Mew, Raikou, Entei, Suicune, Lugia, Ho-Oh und Celebi; Lavados war
bereits enthalten. KASC übernimmt erfolgreiche alte `postgame.catches`,
wirklich ausgelieferte Geschenke, Pokédex-Besitz, Team/PC, Banken und
Legacy-Belege. Ein Sieg ohne Fang ist kein Besitz. Die kanonischen
Nationalnummern 144–146, 150–151, 243–245 und 249–251 überstehen die
Legacy-Archivbereinigung und den Start eines neuen Durchlaufs.

`postgame.lua` fragt im aktuellen Stand die Fangbelege dieses Durchlaufs
auch für die alten Kartenobjekte ab, einschließlich des Vanilla-Modus.
Ein Exemplar erscheint im selben Durchlauf nicht erneut. Die dauerhafte
Historie bewahrt ältere Fänge, blockiert aber nach NG+ keinen neuen
Questfang. Geschenk- und Partnerausgaben behalten ihre eigene
Anspruchsprüfung; Giratina bleibt grundsätzlich nicht fangbar.
Oaks legendärer Legacy-Katalog zeigt nur noch Arten ohne Besitzbeleg.
Die direkte Auswahl prüft den Besitz erneut und lehnt einen inzwischen
besessenen Partner ab. Der alte Abschluss aller drei Charakterpfade bleibt
Voraussetzung für einen noch nicht erhaltenen legendären Partner.

`old-legends8.log`, Exitcode 0, prüft eine echte Arktos-Geschenkauslieferung,
gezieltes Entfernen des QA-Pokémon, Speichern/Laden, gesperrten Zweitfang und
zweites Geschenk sowie das versteckte Originalobjekt. Acht alte
Postgame-Fangbelege werden als Fixtures übernommen; danach sind Fang,
Mewtu-Geschenk, Katalogeintrag und direkte Arktos-Partnerwahl gesperrt.
Ein noch nicht besessenes Lavados bleibt im testweise freigeschalteten
Katalog. Die echte Legacy-Archivtransaktion und Neuspiel-Saat bewahren alle
neun geprüften Identitäten. Ein simulierter Speicherausfall nach der
temporären Lavados-Partnerausgabe lässt keinen falschen Besitzbeleg zurück.
Der Test spielt weder alle alten Fangquests
noch das NG+-Menü vollständig durch. 174 Historien- und 78.501
Integrationsprüfungen bestehen zusätzlich.

Ein bereits vor dieser Erweiterung in einem früheren NG+-Durchlauf
freigelassenes Pokémon ohne erhaltenen Fang-, Geschenk-, Pokédex- oder
Bankbeleg lässt sich rückwirkend nicht sicher nachweisen. Neue erfolgreiche
Erwerbe erhalten ab jetzt einen monotonen Besitzbeleg. Dieser Quellstand
ist neuer als das eingefrorene `package-dev3.zip`.
