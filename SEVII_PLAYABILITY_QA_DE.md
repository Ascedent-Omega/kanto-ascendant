# Sevii: Trainerstärke und zusätzliche Gebäudefunktionen

## Neuer Ressourcenlauf aus Paket dev17 (01.10.2026)

Rot, Grün und Blau schlossen erneut je sieben Kapitel aus der
materialisierten dev17-Kopie mit normalen Zufallsbegegnungen, nativen
Kämpfen und je sieben tatsächlichen Center-Besuchen ab. Alle kehrten nach
Orania zurück. Je Reise wurden 2.728 Routenbewegungen, 154 Kartenränder,
65 Türen und sieben Fähren protokolliert. Die Startwerte 90230–90232
ergaben 22, 34 und 22 Wildkämpfe, zusammen 78. Die Belege liegen in
`package-dev17-qa/natural/journeys-all-characters.json`. Wie zuvor sind
Post-Liga-Team und Startort vorbereitet; sichtbare Wildpokémon und
freiwillige Trainer gehören nicht zu dieser Ressourcenroute.

## Vorheriger Ressourcenlauf aus Paket dev11 (30.09.2026)

Rot, Grün und Blau absolvierten aus der materialisierten dev11-Kopie
je sieben Kapitel mit normalen Zufallsbegegnungen und nativen Kämpfen.
Alle drei erreichten nach je sieben tatsächlichen Center-Besuchen den
Epilog und kehrten nach Orania zurück. Die reproduzierbaren Startwerte
90230, 90231 und 90232 ergaben 25, 32 und 27 Wildkämpfe, zusammen 84.
Jede Reise umfasste 2.728 erfolgreiche Routenbewegungen, 154 Kartenränder,
65 Türen und sieben Fähren. `package-dev11-qa/natural/journeys-all-characters.json`
protokolliert die Kämpfe und Erholungen; alle Prozesse endeten mit
Exitcode 0. Das Post-Liga-Team, Feldorden und der Start in Orania sind
vorbereitet. Sichtbare Wildpokémon und freiwillige Trainer wurden in
diesen Ressourcenreisen nicht gespielt. Die älteren Quellstandläufe
unten sind Vergleichswerte, keine Zahlen für dev11.

## Repräsentativer Kampfvergleich mit normalem Zufall

`balance-native2.log`, Exitcode 0, und `trainer-balance-90228.json`
prüfen alle 14 Inseltrainer und acht Turmetagen im echten Client. Die
Gegner beginnen mit vollen KP und ihren normalen Attacken; Kampf-KI,
Treffer, Schaden und Zufallsverteilung bleiben unverändert. Ein fester
Startwert macht die Zufallsfolge reproduzierbar, erzwingt aber keine
günstigen Würfe. Die frühere konstante Bestfall-Zufallsfunktion und die
verkürzten Gegner-KP kommen hier nicht zum Einsatz.

Das vorbereitete Team besteht aus Glurak, Lapras, Blitza, Nidoking,
Relaxo und Kokowei. Es verwendet vier gewöhnliche Attacken pro Pokémon,
volle AP, keine Trageitems und keine Medizin im Kampf. Jeder Kampf
beginnt mit einem frischen, geheilten Team: Level 62 für die Inseltrainer,
Level 75 für den späteren Turm. Die Reisestrecken und die Erholung zwischen
Kämpfen sind Fixtures. Ein einfaches Spielerprogramm wählt nach Stärke
und Typ; es verändert weder den Kampfzustand noch die gegnerische KI.
Nach einem K. o. wählt es über das native Teammenü einen gesunden Partner.
Es nutzt keine freiwilligen Wechsel, Statusstrategie oder Vorhersage des
nächsten Zufallswerts. Kampfmodus ist „Folge“/Set.

| Gruppe | Kämpfe / Siege | Angriffsentscheidungen je Kampf | Besiegte eigene Pokémon insgesamt / maximal je Kampf |
| --- | ---: | ---: | ---: |
| Inseltrainer, Team Lv. 62 | 14 / 14 | 3–16 | 17 / 3 |
| Turm, Team Lv. 75 | 8 / 8 | 3–11 | 8 / 2 |

Ein zweiter unabhängiger Startwert (`balance-native3.log`, Exitcode 0,
`trainer-balance-90229.json`) beendet ebenfalls alle 22 Kämpfe erfolgreich:
Inseltrainer 4–13 Entscheidungen, neun eigene K. o. insgesamt und höchstens
zwei pro Kampf; Turm 4–9 Entscheidungen, sieben K. o. insgesamt und höchstens
zwei pro Kampf. Über beide Folgen sind damit 44 volle native Trainerkämpfe
belegt. Die Gegnerroster und Level wurden aufgrund dieser Messung nicht
nachträglich zugunsten des Tests abgeschwächt.

Die Gegner verlangen damit bei ungünstigem Auftakt mehrere Partner, bleiben
für ein breit aufgestelltes gewöhnliches Team überwindbar. Die Zahlen sind
ein konkreter Vergleich dieser Aufstellung, keine Garantie für jedes Team
und kein Beweis eines lückenlosen Durchlaufs ohne Erholung. Ein Level-62-
Durchmarsch bis zur Turmspitze wird ausdrücklich nicht behauptet. Der erste
Treiberlauf `balance-native1.log` scheiterte an einer zu frühen Menüabfrage
des Prüfprogramms; das Produkt musste dafür nicht verändert werden.

## Gluttherme

Die zuvor unbesetzte Gluttherme am Glühweg hat nun einen ansprechbaren
Betreuer. Nach der Liga kann der Spieler freiwillig rasten. Der bestehende
Heilungsbesitzer stellt KP und AP wieder her, heilt Status und belebt
besiegte Teammitglieder. Ablehnen ändert nichts. Die Rast kostet kein Geld
und verändert den ursprünglichen sicheren Rückkehrort nach einer Niederlage
nicht. Eine gespeicherte Auswahl darf keinen inzwischen anderen Spielstand
heilen. Der Betreuer steht auf geprüftem, erreichbar angebundenem Boden.

## Pension auf Eiland Vier

Der Pensionsbetreuer öffnet das vorhandene KASC-Pensionsmenü unter einer
lokalen Überschrift. Es gibt dieselben beiden Elternplätze, wartenden Eier,
Gebühren und Trainingsschritte wie auf Route 5. Es entsteht kein zweiter
Bestand und kein neuer Zugang zur dortigen Evolutionsmaschine. Ist der
bestehende Pensionsbesitzer abgeschaltet, meldet die Insel dies, statt einen
Ersatzbestand anzulegen. Die Insel verlangt weiterhin den Ligaabschluss.

`services-native2.log`, Exitcode 0, und `island-services.json` belegen:

- beide Dienste verweigern den Zugang vor der Liga;
- Ablehnen und Annehmen der Rast, echte KP-/Status-/AP-Wiederherstellung,
  Wiederbelebung, unverändertes Geld und unveränderter Niederlagen-Rückkehrort;
- Abgeben auf Sevii, Speichern/Laden, echte Trainingsschritte und Abholen
  über das ursprüngliche Route-5-Menü;
- Ablehnung bei fehlendem Geld mit erhaltenem Elternteil;
- anschließend Abgeben auf Route 5 und Abholen auf Sevii, jeweils genau
  ein Exemplar und tatsächlicher Gebührenabzug;
- abschließendes Speichern/Laden ohne Eltern- oder Pokémon-Duplikat.

Anreise bis zum Gebäudeeingang, Team, Liga und kontrollierte Verletzungen
sind Fixtures. Die Wege im Gebäude, Gespräche, Elternauswahl, Abgabe,
Abholung und Rast werden durch die Spieloberfläche ausgeführt. Die bereits
separat geprüfte Eierproduktion wird durch diesen Lauf nicht erneut belegt.
102 Bevölkerungs- und 78.501 Kartenintegrationsprüfungen bestehen mit den
beiden zusätzlichen NPCs. Das eingefrorene Entwicklungspaket `dev1` enthält
diese Ergänzungen noch nicht.

`services-ui1.log`, Exitcode 0, prüft zusätzlich die Pensionsüberschrift
im nativen Menü. `services-four-island-nursery.png` wurde visuell geprüft:
links steht „FOUR ISLAND DAY-CARE“, rechts „DAY-CARE“. Das allgemeine
Einstellungslabel wurde durch die passende Pensionsüberschrift ersetzt.

## Zusammenhängender Hauptweg mit normalen Wildbegegnungen

`journey-natural1.log`, Exitcode 0, und `journey-natural-red.json` belegen
jetzt für Rot alle sieben Kapitel bis zur Rückkehr nach Orania mit normalen
Zufallsbegegnungen. Die Zufallsfolge hat den Startwert 90230; Treffer,
Schaden, Gegneraktionen und Fluchtversuche laufen unverändert in der Engine.
Es entstehen 29 Wildkämpfe: 17 Siege und zwölf erfolgreiche Fluchten.
Ein eigenes Pokémon wird besiegt; eine vollständige Niederlage tritt nicht
ein. Der Weg umfasst 2.718 Routenbewegungen, 154 Kartenränder, 65 Türen
und sieben Inselfährfahrten.

Das anfängliche Team besteht aus sechs gewöhnlichen Kanto-Pokémon auf
Level 62. Liga, Orania-Position, Feldorden und das Team sind Start-Fixtures.
Danach verändert der Prüftreiber KP, AP, Status und Erfahrung nicht mehr.
Das Spielerprogramm bekämpft erstmals angetroffene Arten bei ausreichend
gesunder Führung; bei Wiederholungen, weniger als 40 Prozent KP oder
knappen AP versucht es die native Flucht. Ein gescheiterter Fluchtversuch
kann weitere gegnerische Angriffe auslösen. Neue Attacken werden abgelehnt.

Bei der Ankunft auf jeder Insel geht es tatsächlich ins Pokémon-Center
und spricht mit der Schwester. Alle sieben Erholungen werden samt Team
vorher/nachher protokolliert; sechs davon heilen wirklich erlittenen Schaden.
Zwischen diesen Besuchen bleibt der Verbrauch erhalten. Über die Kämpfe
werden 35 AP verbraucht. Im Beutel liegen nur die zwei vorbereiteten Orden;
keine Medizin, Schutz oder nachträglich eingesetzten Vorräte. Das Geld
bleibt bei 10.000. Turtok erreicht Level 63 und kehrt mit 82/182 KP zurück.
Die Details stehen in `journey-resources-90230.json`.

Sichtbare Pokémon bleiben in diesem Lauf ausgeschaltet. Freiwillige
Trainer, Fangversuche und die Beschaffung des Startteams sind separate
Nachweise. Dieser Lauf belegt einen zusammenhängenden Erkundungsweg mit
normalen Zufallsbegegnungen und echten Erholungswegen, keine Schwierigkeit
für jedes mögliche Team oder jeden Spielstil.

Auch Grün und Blau sind im selben Mod-Stand vollständig durchgelaufen:
`natural-followup/journey-green.log` und `journey-blue.log`, beide Exitcode 0.
Die Prüftreiber vergleichen hier zusätzlich an jedem Kapitel-Checkpoint
KP, AP, Status, Level, Geld und Beutel vor dem Speichern und nach dem Laden.
Keine dieser Prüfungen musste abgeschwächt werden.

| Charakter / Zufallsstart | Wildkämpfe | Siege / Fluchten | Verbrauchte AP | Eigene K. o. | Center-Besuche |
| --- | ---: | ---: | ---: | ---: | ---: |
| Rot / 90230 | 29 | 17 / 12 | 35 | 1 | 7 |
| Grün / 90231 | 26 | 18 / 8 | 31 | 0 | 7 |
| Blau / 90232 | 41 | 24 / 17 | 54 | 1 | 7 |

Alle drei Reisen gehen über dieselben 2.718 Routenbewegungen bis Orania,
mit je 154 Kartenrändern, 65 Türen und sieben Inselfährfahrten. Insgesamt
sind 96 natürliche Wildkämpfe und 21 tatsächliche Center-Besuche belegt.
Blau kehrt mit besiegtem Turtok, aber fünf gesunden Partnern zurück; es gibt
keine vollständige Niederlage. `journeys-natural-all-characters.json` führt
die drei Berichte und ihre Grenzen zusammen. Das beweist die geprüfte
Erkundungsstrategie mit diesem Startteam, nicht beliebige Teams oder einen
Durchmarsch durch die optionalen Trainer ohne zusätzliche Erholung.
