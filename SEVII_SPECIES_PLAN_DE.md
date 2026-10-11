# Bestehende Pokémon sinnvoll auf Sevii verteilen

Stand 28.09.2026, KASC-Basis `b30cfad48` (6.7.29-rc.3).
Die Verlagerungstabelle beschreibt Vorschläge; bestehende Kanto-Fangorte
sind weiterhin aktiv. Der umgesetzte Sevii-Katalog ergänzt dagegen bereits
218 gewöhnliche Arten. Exklusive Umzüge sind noch nicht umgesetzt.

## Aktueller Stand (30.09.2026)

Die alten Regi-Heiligtümer sind geschlossen; die drei Regis antworten nach
Tanoby-Waage und Hoenn-Forschung nur in Liptoo, Weepth und Scufib. Groudon,
Kyogre und Rayquaza bleiben charaktergebunden, erscheinen aber am Glutberg,
in der Eisfallhöhle und auf dem Trainerturmdach, nachdem die eigene schwarze
Schreintür besucht, die 130 gewöhnlichen Hoenn-Arten erfasst und das Insel-
Finale abgeschlossen wurden. Jirachi bleibt an der Konvergenztür und verlangt
weiterhin alle 134 anderen Hoenn-Arten. Ein Fang sperrt weitere Begegnungen
im selben Durchlauf; NG+ erlaubt nach erneuten Quests wieder einen Fang.
Ältere Pokémon bleiben in Bank und Archiv. Die folgende alte
Kontinuitätsnotiz ist überholt.

Seltene Zielarten haben wechselnde Gewichte: Rotom, Spiritomb, Driftlon,
Zobiris und Lunastein werden nachts häufiger; Sonnfel, Riolu und Kindwurm
tagsüber; Barschwa und Formeo bei Regen. Auch außerhalb des günstigen
Fensters bleiben sie fangbar. Das Fangortbuch nennt die Bedingung. Das
Feldwetter kommt von Voxel Ascendant, das für die Überfahrt nötig ist.

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

## Geprüfte Ausgangslage

Die unten genannten Fundorte stammen aus den ausdrücklich zugeordneten
Hoenn-Familien in [hoenn_acquisition_67_data.lua](hoenn_acquisition_67_data.lua).
Sie beschreiben diesen Fangpfad, nicht jeden möglichen Randomizer-, Tausch-,
Zucht- oder Legacy-Zugang. Eine Familie kann Entwicklungen einschließen;
das bedeutet nicht, dass jede Entwicklungsstufe dort unmittelbar wild steht.

| Bestehende Familie | Derzeitiger zugeordneter KASC-Fangort | Vorgeschlagener Sevii-Ort | Entscheidung und Begründung |
| --- | --- | --- | --- |
| Camaub / Camerupt, Qurtel | Pokémon-Haus UG1, Level 35 | Eiland Eins, Glühweg und später Glutberg | Vorrangige Umzugskandidaten: ein natürlicher vulkanischer Lebensraum. Im ersten Kapitel bereits zusätzliche Begegnungen mit Camaub und Qurtel. |
| Spoink / Groink | Route 10, Level 24 | Eiland Zwei, bewachsene Höhen am Kap | Eigenständige Inselpopulation. Spoink ist im aktuellen Sevii-Katalog dem Kap zugeordnet. |
| Wingull / Pelipper | Route 21, Level 28 | Mehrere Sevii-Küsten | Kanto-Population behalten: Seevögel verbinden beide Regionen. Keine seltene Portalart daraus machen. |
| Wailmer / Wailord | Seeschauminseln UG2, Level 30 | Offene Gewässer vor Eiland Eins und Fünf | Umzugskandidat: offene See statt Höhlenbecken. Wailmer ist im ersten Kapitel zusätzlich vorhanden. |
| Kanivanha / Tohaido | Seeschauminseln UG4, Level 34 | Warme Strömungsrinnen bei Eiland Eins und Fünf | Umzugskandidat. Kanivanha ist bereits Teil des ersten Küstenabschnitts. |
| Roselia | Route 15, Level 27 | Eiland Drei, Beerenforst | Umzugskandidat mit Zugang zur bereits vorhandenen Gen-4-Entwicklung Roserade. |
| Trasla / Kirlia / Guardevoir | Route 24, Level 16 | Eiland Drei, ruhige Waldabschnitte | Bestehenden frühen Kanto-Zugang behalten; spätere Inselpopulation ergänzen. Galagladi nutzt den vorhandenen Entwicklungspfad. |
| Frizelbliz / Voltenso | Kraftwerk, Level 32 | Eiland Fünf, Stationsumgebung | Umzug nur nach Prüfung der Kraftwerk-Forschung. Im aktuellen Inselkatalog auf Eiland Fünf. |
| Seemops / Seejong / Walraisa | Seeschauminseln UG2, Level 30 | Eiland Vier, Eiskaskadenhöhle | Passender dauerhafter Insellebensraum. |
| Schneppke / Firnontor | Seeschauminseln UG4, Level 34 | Eiland Vier, Eiskaskadenhöhle | Gemeinsam mit Seemops verlagern; Frosdedje als bestehende Gen-4-Entwicklung einbinden. |
| Perlu, Relicanth | Seeschauminseln UG4, Level 34 | Eiland Fünf, Riffe und tiefe Buchten | Umzugskandidaten; keine neue Tauchen-Pflicht, solange dieses Feldsystem nicht verfügbar ist. |
| Zwirrlicht / Zwirrklop, Shuppet / Banette | Pokémon-Turm 7F, Level 28 | Eiland Sechs, Ruinen bei Nacht | Kleine Kanto-Population behalten; zusätzliche Inselpopulationen zeigen die Störung. Der ursprüngliche Vorschlag sah Zwirrfinst nur als Entwicklung vor. Das erweiterte Lieferziel macht jetzt auch Endstufen nach der Liga direkt fangbar. |
| Nasgnet | Felstunnel UG1, Level 24 | Eiland Sechs, magnetisch gestörte Felskammer | Passender Umzugskandidat; Voluminas über den vorhandenen Gen-4-Pfad. |
| Puppance / Lepumentas | Mondberg UG2, Level 12 | Eiland Sieben, Tanoby-Umfeld | Starker Ruinenbezug; Verlagerung macht diese Familie allerdings erst nach der Liga verfügbar. Frühe Forschungsaufträge deshalb vorher anpassen. |
| Knacklion / Vibrava / Libelldra | Digda-Höhle, Level 20 | Eiland Sieben, trockene Canyonböden | Deutlich passenderes Habitat; denselben Verlust des frühen Zugangs ausdrücklich berücksichtigen. |
| Kindwurm / Draschel / Brutalanda | Siegesstraße 3F, Level 45 | Eiland Sieben, entlegene Canyonklippen | Seltene spätere Expedition, kein häufiges Strand-Pokémon. |

## Was in Kanto bleibt

Frühe Begleiter wie Fiffyen, Zigzachs und die Waldarten sollen den Beginn
eines neuen Spielstands weiter tragen. Die Hoenn-Starter und ihre bestehenden
Legacy-Freischaltungen bleiben erhalten. Zigzachs darf zusätzlich auf Inseln
leben; gewöhnliche Populationen sind keine legendären Einzelwesen.

Die Inseln sind nach der Liga erreichbar. Jede vollständige Verlagerung
nimmt einer neuen Partie daher den bisherigen frühen Fang. Das ist eine
bewusste Änderung des Spielverlaufs und muss zusammen mit Forschungsaufträgen,
Pokédex-Fundortanzeigen und Belohnungen umgesetzt werden. Bei Arten, die den
frühen Spielverlauf prägen, ist eine zusätzliche Population sinnvoller.

## Legenden und Galar

Lavados bleibt beim bereits vorhandenen Zinnober-Vulkanpfad
([hoenn_moltres_volcano_67.lua](hoenn_moltres_volcano_67.lua)); auf dem
Glutberg entsteht kein zweiter Fangort. Die drei Regis sind nach der
Tanoby-Forschung ausschließlich an ihren Insel-Inschriften anzutreffen;
ihre alten Heiligtümer sind geschlossen. Ein Fangbeleg sperrt die Art
im aktuellen Durchlauf, ältere Exemplare bleiben im NG+ erhalten.
Deoxys bleibt auf der Entstehungsinsel. Giratina
ist ausschließlich der wiederkehrende, nicht fangbare Verursacher der Risse.

Galar wurde vom Nutzer als Beispiel für die regionalen Formen der drei
Vögel präzisiert. Meikro, Klopptopus und Galar-Corasonn sind daher keine
Anforderung an diese Erweiterung. Die Vogelformen bleiben eine optionale
Storyidee innerhalb der bestehenden Legendenkontinuität, ohne zusätzliche
Fangexemplare. Vor einer Umsetzung sind ihre Identitäten, Grafiken und
gemeinsamen dauerhaften Fangzustände zu prüfen.

## Umsetzung der Verlagerung

1. Zielgebiet, Hin- und Rückweg sowie passende Begegnungen fertigstellen.
2. Alle bisherigen Autoren des Fangpfads und abhängige Forschungen prüfen;
   die obige Tabelle allein ist keine vollständige Migrationsanweisung.
3. Alten Hauptfundort ersetzen und Fundortanzeigen auf denselben neuen
   Datensatz umstellen. Bestehende Forschungs- und Besitzdaten behalten.
4. Neue Partie, vorhandenen Spielstand und Legacy-Partie jeweils mit
   aktiver und inaktiver Generation prüfen. Fehlende optionale Grafikpakete
   dürfen im neuen Fangpfad keine Platzhalter-Pokémon erzeugen.
5. Legendäre mit dauerhafter Historie und einem Fangbeleg pro Durchlauf
   umziehen. Ein Storyauftritt darf im selben Durchlauf keinen zweiten
   garantierten Fang erzeugen.

Die Inselbegegnungen umgehen nach der Liga gezielt die charakterabhängige
Familienbeschränkung und benötigen keinen Hoenn-Honig. Inhaltsschalter,
Generationsprofil und vorhandene optionale Artdateien werden weiterhin
berücksichtigt. Bestehende Kanto-Fundorte wurden noch nicht entfernt.

Die quellengestützte Prüfliste steht in `SEVII_SPECIES_REQUIREMENTS.json`.
Rot fehlen über seinen Wandertrainer-Pfad 41 Familien mit 75 Arten, Grün
41 Familien mit 77 Arten und Blau 42 Familien mit 78 Arten. Der kompilierte
Katalog deckt alle diese Lücken ab. Alle 218 Ziele einschließlich der
93 gewöhnlichen Gen-4-Arten sind aus den nativen Begegnungstabellen
würfelbar. Der vollständige Fang-/Box-/Speichertest ist mit 218/218 Arten bestanden.
Ein zusätzlicher nativer Test löst in allen 84 Begegnungsgebieten durch
echte Schritte Kämpfe aus. Dabei wurde die Erkennung aller importierten
Grasbilder ergänzt; eine korrekte Tabelle allein hätte diese Fangorte
noch nicht tatsächlich beim Gehen verfügbar gemacht.

## Umgesetzte Inselverteilung

Die 23 Lebensräume verteilen sich auf 84 Begegnungstabellen. Jede der
218 Zielarten hat genau einen verfassten Fangort und mindestens einen
nativen Zufallsslot. Zehn Slots pro Tabelle werden nie durch Abschneiden
erzwungen. Der Musterbusch wurde in sechs räumliche Bereiche aufgeteilt.

| Insel | Gewöhnliche Gen-3-Arten | Gewöhnliche Gen-4-Arten | Lebensräume |
| --- | ---: | ---: | --- |
| 1 | 21 | 12 | Erzadern, Gipfelstille, Glutpfade, Schatzgestade, Warme Stroemung |
| 2 | 12 | 4 | Teich am Kap, Wiesen am Kap |
| 3 | 31 | 21 | Alter Beerenforst, Lichtungen im Beerenforst, Teich am Kap, Waldtuempel, Wiesen an der Bruecke |
| 4 | 5 | 9 | Eiskaltes Wasser, Frostkammern |
| 5 | 22 | 16 | Alte Riffe, Forschungsweide, Gedenkwiese, Verlassene Station, Verlorene Hallen |
| 6 | 26 | 18 | Musterbusch, Schlammufer, Sternkammern, Wandelhoehle |
| 7 | 8 | 13 | Sevae Canyon |

Das Fangortbuch an jedem Hafen verwendet genau diese Daten, einschließlich
Gebietsname, Himmelsrichtung, Geländeart, Level und etwaiger Profil- oder
Grafiksperren. Giratina und legendäre Sonderbegegnungen stehen nicht darin.
