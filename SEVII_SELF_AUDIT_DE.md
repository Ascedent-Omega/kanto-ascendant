# Sevii und KASC: Selbstprüfung von dev22 (01.10.2026)

## Ergebnis

Die erneut geprüften Kernpfade des **Entwicklungspakets dev22** laufen im
isolierten nativen Client. Es ist noch **keine Veröffentlichung**:
`releaseReady=false`. Die folgenden Aussagen gelten für
`/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/package-dev22.zip`
mit SHA-256
`480ad15687bb09c94c5ca089cbddff50b4f05bd4130a1caf3f43e49eea62cb3a`.
Der Test verändert keine vorhandenen Nutzerspielstände.

## Erneut bestandene Prüfungen

| Bereich | Tatsächlicher Nachweis |
| --- | --- |
| Paket und Code | Inventar und ZIP-CRC bestanden; 663 Lua-Module sind syntaktisch ladbar und stimmen bytegenau mit der Paketkopie überein. 35 isolierte Sevii-/Fangserien-Tests und sechs Pakettests bestanden. |
| Zusammenhängendes Spiel | Rot beendet sieben Kapitel und fährt nach Orania zurück. Ein Lauf mit normalen Zufallskämpfen erreichte 2.728 Schritte, 154 Kartenränder, 65 Türen, sieben Inselfähren, 22 Kämpfe und sieben Center-Besuche. Startteam, Ligastatus und Ausgangsort waren Testvorbereitungen; sichtbare Wild-Pokémon und optionale Trainer waren aus. |
| Kanto-/Sevii-Karte | Die eigene Karte erscheint bei Ankunft; SELECT öffnet Inselinformationen mit Beschreibung, START wechselt nach Kanto und zurück. FLIEGEN bleibt bis zum reparierten Funksignal gesperrt; danach funktioniert die native Fluganimation. Die Rückfahrt per Fähre ist davon unabhängig. |
| NG+-Legenden | Der tatsächliche `game:startNewGame`-Übergang behält alten Archivbesitz und setzt Durchlaufbesitz zurück. Alte statische Kanto-Legenden werden wieder sichtbar. Regirock, Regice und Registeel sowie Groudon, Kyogre und Rayquaza wurden im jeweiligen nativen Kampf nach früherem Besitz erneut gefangen; Jirachi ebenfalls nach der Konvergenztür. Der zweite Fang derselben Art im neuen Durchlauf bleibt gesperrt. |
| Fangserien-Card | Standardzustand, Abschalten, Speichern/Laden und Reset beim neuen Spiel sind geprüft. Im ASCENDANT-Modus führen 10/11/21/31 Fänge zu 0/1/3/6 Zusatzwürfen für dieselbe Art; ausgeschaltete Card und NATURAL-Modus geben keine Zusatzwürfe. |

Bei der Fangserienprüfung fiel ein echter Flucht-Grenzfall auf: Der
spielerische Rückzug nach einem Ohnmachtsdialog nutzte einen anderen
Codeweg als die normale FLUCHT-Aktion. Der gemeinsame `runRoll`-Weg ist
im dev22-Paket korrigiert und nativ geprüft; beide eigenen Rückzüge
erhalten die Serie, eine wilde Flucht beendet sie weiterhin.

Belege stehen unter
`/Users/maarten/Documents/Recompile/.qa/sevii-expedition-20260928/self-audit-dev22/`.
Die maßgeblichen Dateien sind `journey-natural-red.json`,
`map-description4.log`, `ngplus-static.log`, `jirachi-recatch3.log`,
`regice-ngplus.log`, `registeel-ngplus.log`, `weather-blue-ngplus.log`,
`weather-green-ngplus.log` und `lua-syntax.log`; für Regirock, Groudon und
die Card die gleichnamigen `package-dev22-*-self-audit.log`-Dateien im
übergeordneten QA-Verzeichnis. Frühere fehlgeschlagene Versuche der
Jirachi- und Karten-Treiber waren Fehler der Teststeuerung bzw. einer zu
engen Textassertion; die korrigierten nativen Läufe bestanden.

## Nicht als bestanden zu werten

- Ein kompletter NG+-Menüablauf mit Wahl der Spielfigur und anschließender
  regulärer Story ist noch nicht Ende zu Ende gespielt. Geprüft wurden der
  echte Engine-Neustart-Hook und gezielte native Fänge mit vorbereiteten
  Questvoraussetzungen.
- Die aktuelle dev22-Paketkopie wurde natürlich mit **Rot** vollständig
  durchgespielt. Natürliche Gesamtreisen mit Grün und Blau stammen aus
  früheren Entwicklungsständen; die neue Fangserien- und NG+-Änderung
  wurde dort nicht erneut über sieben Kapitel gefahren.
- Der umfassende Altspielstand-Upgrade-Durchlauf stammt aus dev11.
  Migration und Besitzpfade wurden seither gezielt geprüft, aber nicht
  nochmals als kompletter dev22-Altspielstand-Durchlauf.
- Gen-2-/Gen-3-Items sind noch nicht vollständig mit Fundorten und
  Wirkungen versehen. Der letzte Itemaudit weist 190 Identitäten,
  89 feste Sevii-Quellen und 34 registrierte Beutelwirkungen aus.
- Finale Balance, visuelle Prüfung sämtlicher Dialogseiten und das
  Installationspaket mit verpflichtendem Voxel Ascendant benötigen noch
  Abnahme. Die automatisierten Läufe belegen Spielbarkeit der geprüften
  Pfade, keine vollständige manuelle Inhaltsfreigabe.

Das Entwicklungsarchiv bleibt deshalb ausdrücklich unveröffentlicht.
