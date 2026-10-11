# Sevii-Doppelkämpfe: Integration mit VASC

Stand: 02.10.2026. Die Arbeit liegt in zwei getrennten, sauberen Worktrees.
VASC baut auf dem veröffentlichten `v3.0.62` auf; der Vierer-Renderer ist
Commit `1c46c2cb`, ergänzt um die isolierte Partner-Canvas-Kopie in
`63cdc2f4`, im Zweig `codex/sevii-double-vasc-integration-20261002`.
KASC baut auf dem veröffentlichten `v6.7.32` auf; der spielbare Kampfcontroller
ist Commit `b6a43efc4` im Zweig `codex/kasc-sevii-release-integration-20261002`.
Beide Zweige enthalten die älteren Sevii-Integrationscommits. Sie sind noch
nicht in die veröffentlichten Versionen übernommen.

## Aktivierung und Schutz bestehender Kämpfe

Nur die vermessenen Sevii-Trainer **BEACH** und **VOLCANO** erhalten einen
Doppelkampf. Dafür muss VASC die öffentliche Capability
`capabilities.seviiDoubleBattle` mit Schema `kasc.sevii-double-visual/v1`,
`ready == true` und `MAP`, `DISCS`, `ARENA`, `TERRARIUM` jeweils als `true`
melden. KASC verlangt außerdem zwei kampfbereite Spieler-Pokémon und zwei
Gegner. Ohne VASC-Capability bleibt der normale Einzelkampfpfad aktiv. Ist
die Capability vorhanden, aber das eigene Team zu klein, beginnt kein Kampf;
der Trainer gibt einen Hinweis. Der Gartenkampf
bleibt ein Einzelkampf, weil die vier geprüften Lichtungen keine freie
physische MAP-Kamera erlauben. Kanto-KASC und VASC ohne KASC erhalten keine
neue Kampfform.

VASC prüft den Kartenbesitzer `kasc.sevii-expedition/v1`, vier verschiedene
begehbare Standplätze, Sicht und Kamera. Am Strand gilt eine eng auf den
vermessenen Platz bei `(13,22)` begrenzte Ausnahme für niedrige Küstenpflanzen;
am Vulkan wird hohes Gras weiter abgewiesen. Ausgefallene oder ausgewechselte
Partner behalten eigene Renderer- und Texturbelege. Eine ungeeignete Ansicht
fällt auf eine sichere Bühne oder die native 2D-Darstellung zurück, ohne den
Kampfzustand neu zu erzeugen.

## Geprüfte Ansichten

| Ansicht | Nachweis im integrierten Spiel |
| --- | --- |
| MAP | Vier getrennte Körper am Strand und am neuen Vulkanplatz `(14,46)`; ein vollständiger Zug in MAP. |
| DISCS | Vier Körper und eigene Podeste; ein vollständiger Zug. |
| ARENA | Vier Körper auf der gemeinsamen Bühne; ein vollständiger Zug. |
| TERRARIUM | Vier Körper mit angepasstem Bildausschnitt; ein vollständiger Zug. |
| Voxel AUS | Native 2D-Anzeige mit zwei Befehlen und Zielwahl; vollständiger Sieg. |

Zusätzlich bestanden ein Kanto-Einzelkampf-Gegentest, Partner-K. o. mit
Auswechslung und Statusschaden am Partner. Die gezielte KASC-Suite meldete
`78.553` erfolgreiche Prüfungen; die VASC-Logiktests für Viererbeleg,
Arena-Bindung, Wiederherstellung und Kamera bestanden. Das private
Sevii-Paket wurde mit `48.099` Dateien verifiziert und meldet bewusst
`releaseReady: false`. Belege liegen unter
`/tmp/sevii-double-native-20261002/` und
`/tmp/kasc-sevii-double-package-20261002/`.
Ein zusätzlicher Grafikzustands-Test bestätigt für alle fünf Ansichten, dass
die Partneranzeige Shader, Clip und Blend des Aufrufers wiederherstellt.
VASCs Partner-Canvas-Kopie ist ebenfalls gegen geerbte Shader-, Clip- und
Transformationszustände sowie Fehler beim Zeichnen getestet.

## Noch vor einer öffentlichen Freigabe prüfen

Die Modusläufe belegen spielbare Züge und lesbare vier Körper, aber noch keine
vollständige Abdeckung aller Attacken- und Effektarten. Der KASC-Controller
benutzt pro Zug zwei Einzelzielaktionen; Mehrfachziele, Angriffe auf den
eigenen Partner und weitere spezielle Doppelkampfregeln brauchen eigene
Spieltests und gegebenenfalls Erweiterungen. VASCs Kamera-HUD-Prüfung
verwendet derzeit die beiden ursprünglichen Statusbesitzer; KASC zeichnet
die Partneranzeigen nach der normalen Kampfoberfläche. Sehr große Pokémon,
enge Mobilbildschirme, komplexe Shader/Scissor-Kombinationen und Effekte auf
Partner-Slots sind deshalb noch gesondert zu prüfen. Speichern/Laden und
Rückkämpfe eines begonnenen Doppelduells brauchen ebenfalls einen eigenen
Durchlauf. Bis diese Punkte geprüft sind, ist der Stand eine verifizierte
lokale Integration und keine öffentliche Release-Freigabe.
