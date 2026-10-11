# Sevii auf den aktuellen Online-Releases: Integrationsstand

Stand: 02.10.2026. GitHub Releases und die Tags wurden frisch abgeglichen.
Die aktuellen öffentlichen Stände sind KASC `v6.7.32`
(`a95d0d160d468137d3ea759de3f95d4f4815a893`) und VASC `v3.0.62`
(`24f0d68cd7b07cd7e32092b369c9b572436bc2be`). `origin/main` ist bei
beiden Repositories älter als die Release-Tags und deshalb keine geeignete
Integrationsbasis.

Die zwei getrennten lokalen Integrationszweige bauen auf diesen Tags auf:

| Projekt | Lokaler Entwicklungscommit | Basis |
| --- | --- | --- |
| KASC mit Sevii | `aa0ea6cb9` (Integrationsbasis `160244d18`) | `v6.7.32` |
| VASC mit Sevii-Test-7-Grafik | `dc654ef0` (Integrationsbasis `22df91b3`) | `v3.0.62` |

Das ursprüngliche VASC-Test-7-Paket beruht auf `v3.0.61` und ist als
historisches Testartefakt unverändert. Auf KASC `v6.7.32` wurden die 33
geänderten Quelldateien der Sevii-Entwicklung per 3-Wege-Patch ohne Konflikt
und 187 neue Dateien ohne Namenskollision übernommen. Das eigene, aus der
bereitgestellten ROM importierte Kartenbundle ist lokal bytegleich kopiert,
bleibt aber per `.gitignore` außerhalb von Git. Keiner der beiden Zweige ist
installiert oder veröffentlicht.

Auf dem KASC-Integrationszweig bestanden der Syntaxcheck für 148 geänderte
und neue Lua-Dateien, alle 34 Sevii-Unit-Tests, sechs Paketintegritäts-Tests
und vier gezielte Regressionen für Kantos Pyro-Route, Hoenn-Besucher,
Randomizer-Fortschritt und Hoenn-NG+-Habitate. Der große Sevii-Test prüfte
78.549 Bedingungen auf dem lokal importierten Kartenbestand. Eine bereits
auf dem alten Zweig fehlschlagende GS-Ball-Testvorgabe füllte 25 statt der
tatsächlichen 20 Beutelplätze; der Test verwendet jetzt `Bag.capacity` und
bestand mit 292 Prüfungen. Das Produktionsverhalten wurde dafür nicht
geändert.

Auf dem VASC-Integrationszweig bestanden der Syntaxcheck für 66 geänderte
Lua-Dateien und gezielte Sevii-, Fenster-, Treppen-, Smart-Map-, Kampf- und
Terrarium-Tests. Der separate native Review bestätigte vier gezielte Läufe
für Häuser/Fenster in normalem und vollem Voxel sowie beide Wälder über
Frühling, Sommer, Herbst, Winter und erneuten Frühling. Diese nativen Läufe
verwendeten noch ein eingefrorenes älteres KASC-Testpaket; sie beweisen noch
keine gemeinsame Spielsitzung der beiden neuen Zweige.

Der anschließende gemeinsame native Lauf auf dem eingefrorenen Paar KASC
`160244d18` und VASC `22df91b3` bestätigte Kantos Smart-Map mit
Regionenwechsel, Kantos Voxel- und 2D-Ansichten und einen Kanto-Einzelkampf
in MAP, ARENA, DISCS und TERRARIUM einschließlich eines echten Zuges. Der
Sevii-Wald bestand die Weltansichten und einen Einzelkampf in MAP, DISCS und
TERRARIUM. Ein weiterer Strandlauf bestätigte dort MAP, DISCS, TERRARIUM,
einen echten Zug (Gegner-KP 173→74, Surfer-AP 15→14), die Rückkehr ins
Kampfmenü und den Wechsel zurück nach 2D. ARENA blieb im Wald und am
offenen Strand nach begrenztem Warten bei MAP: Für diese Quellen fehlte ein
explizit geprüfter Hintergrund.

VASC `f266e080` ordnet deshalb ausschließlich der originalgetreu validierten
Berry-Forest-, Pattern-Bush- und Treasure-Beach-Quelle bereits geprüfte
Wald- bzw. Küstenhintergründe zu. Der neue exakte Kartenvertrag und gezielte
Kampf-Regressionstests bestanden. Der native Sichttest bestätigte in beiden
Wäldern und am Strand echte ARENA-Frames ohne MAP-Rückfall. Das zunächst
gewählte Strandmotiv zeigte jedoch Kantos Stadt und Vulkan. `dc654ef0`
ersetzt nur diese exakte Strandbindung durch eine geprüfte Sand-/Felsbank
mit offenem Meer. Der getrennte native Strandlauf bestand mit 507 echten
ARENA-Frames; die echte Karte blieb `KA_SEVII_TREASURE`, und das Bild zeigte
keine Kanto-Stadt und keinen Vulkan. Das Küstenmotiv bleibt eine
Wiederverwendung und ist kein exaktes Sevii-Kartenpanorama oder
Vier-Slot-Beleg.
Auch Fähr-Rückfahrt, Smart-Map/Fly und Speichern/Laden im gemeinsamen Stand
brauchen noch einen vollständigen nativen Durchlauf. Ein 2-gegen-2-Kampf wird nicht
aktiviert: KASCs nativer Kampfcontroller besitzt noch keine vollständigen
vier Slots, und VASC bietet dafür noch keinen öffentlichen geprüften
Fähigkeitsbeleg. KASC fragt ausschließlich den versionierten öffentlichen
Beleg für alle vier Grafikansichten ab und bleibt bis dahin bei `false`.
Die Gartenlichtung bei (9,6) fiel in der echten
Kameraprüfung durch; Strand und Vulkanpfad sind nur Geländekandidaten.

Siehe `SEVII_VASC_DOUBLE_INTEGRATION_DE.md` für den Aktivierungsvertrag.
