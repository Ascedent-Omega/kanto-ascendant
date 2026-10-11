# Sevii-Dialogreview und Kanto-Abgleich – dev24 (01.10.2026)

Im Kanto-Abgleich wurde der Zinnober-Forscher berichtigt: Mit installiertem
Sevii verweist er für Regirock jetzt auf Tanoby und nennt den alten Zugang
versiegelt. Seine freiwillige Rückfahrt zum Vulkan bleibt erhalten. Ohne
Sevii-Karten verwendet er weiterhin den bisherigen Kanto-Dialog. Der
Entstehungsinsel-Kapitän benennt nun die tatsächlichen Vulkanmessungen und
drei Risspfade statt unbestimmter „drei Fangsiegel“. Spielregeln und
Freischaltungen wurden dadurch nicht verändert.

Die vorhandenen Kanto-Prüfungen passen zum Inselvertrag: Lavados bleibt an
seinem Vulkan; Regirocks Tanoby-Abschluss erfüllt den weiterhin nötigen
Durchlaufnachweis für Deoxys; Wetterlegenden bleiben an Charakter, eigene
schwarze Tür, Hoenn-Fundament und Insel-Finale gebunden; Jirachis vollständige
Hoenn-Forschung führt ausschließlich zur Konvergenztür. Latias und Latios
behalten ihre Kanto-Wanderung und erweitern nur ihr Aufenthaltsgebiet.
Die Inselkarte ist bei Ankunft da, Fliegen folgt erst nach Kapitel fünf,
und die Fähre bleibt jederzeit nutzbar. Die Story- und Fundorttabellen wurden
an den aktuellen Legendenvertrag angepasst; ältere QA-Abschnitte sind
ausdrücklich als Archiv gekennzeichnet.

Die Dialoge der sieben Hauptkapitel, der optionalen Inselgeschichten, der Bewohner und der wichtigsten Dienste wurden auf Englisch und Deutsch redigiert. Figuren sprechen jetzt aus ihrer Situation heraus: Mara reagiert auf ihre Messungen, Lina auf ihre Rettung, Hagen auf die Erinnerung seiner Familie, Noah auf die eingeschlossene Besatzung und Selma auf die Rückkehr der Menschen. Questabschluss-Titel und Entwicklungsbegriffe wurden aus gesprochenen Abschlüssen entfernt. Die nötigen Richtungen, Schalterfolgen, Begegnungsbedingungen und Freischaltungen stehen weiterhin in den Expeditionsnotizen und Menüs.

Die Handlung bleibt unverändert: Giratina öffnete den Übergang aus der Zerrwelt, ist hier nicht fangbar und bleibt nach dem lokalen Siegel eine Gefahr für spätere Geschichten. Die neu angesiedelten Pokémon bleiben. Regis erscheinen nur in Tanoby, Wetterlegenden erst nach dem eigenen Schrein und Hoenn-Nachweis. Fähren bleiben jederzeit nutzbar; die Regionskarte ist bei Ankunft da und zeigt START/SELECT selbst an, während Fliegen erst nach der Stationsrettung freigeschaltet wird.

Neuer Epilog nach diesem Review: Selma übergibt den GS-Ball und nennt Eich
als Ansprechpartner. Eich bittet darum, den Ball zu behalten und später
wiederzukommen; er fragt Professorin Ivy. Die englische und deutsche
Dialogfassung benennt denselben Auftrag. Die Orange Islands sind damit eine
offene Fortsetzung, kein vorgezogener Celebi-Fundort.

Der neue Eich-Dialog wurde im nativen Labor mit sichtbarem Eich in Englisch
und mit `translation-german-universal` 0.2.0 in Deutsch ausgelöst und nach
Speichern/Laden geprüft (`gsball-ivy-dev24-en2.log`,
`gsball-ivy-dev24-de2.log`; beide Exitcode 0). Eich nennt Ivy in beiden
Sprachen und bittet ausdrücklich um die spätere Rückkehr mit dem Ball.
Der Ball bleibt beim Spieler, und der Hinweis überlebt den
Neustart. Der ältere deutschsprachige Sieben-Kapitel-Lauf unten belegt den
vorherigen Storytext; die neue Szene hat ihren eigenen fokussierten Lauf.

Statischer Sprachabgleich: 378 direkte englisch/deutsche `tr`-Textpaare in 25 Sevii-Modulen, keine leere Seite, keine abweichende Absatzstruktur und keine auffällig einseitigen langen Übersetzungen. Die zusätzlichen dynamischen `en`/`de`-Tabellen sind ebenfalls paarig. Hinweise in Journalen und technischen Fehlermeldungen bleiben absichtlich sachlicher als Figurenrede. Die deutsche Fassung verwendet jetzt echte Umlaute und `ß`; natürliche Folgen wie „neuen“, „blauen“, „Quelle“ und der Eigenname „Hoenn“ bleiben unverändert.

Validierung: 32 Sevii-Lua-Tests, sechs Paket-Integritätstests und zusammenhängende Sieben-Kapitel-Läufe mit Rot in Englisch und Deutsch bestanden. Der abschließende deutsche Lauf (`dialogue-review-de16/journey-red.json`) nutzte `translation-german-universal` 0.2.0 mit aktivem Deutsch. Jeder Lauf umfasste 2.642 Routenbewegungen, 150 Kartenübergänge, 51 Türen und sieben Fährfahrten; Abschluss und Rückkehr nach Orania wurden geprüft. Die Läufe schalteten Zufalls- und sichtbare Begegnungen aus und sind keine Balance- oder Fangquotentests.
