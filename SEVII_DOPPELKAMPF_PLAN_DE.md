# Sevii-Doppelkämpfe: technische Abnahme vor Einbau

**Aktualisierung 02.10.2026:** Die unten beschriebene Voxel-Vorbereitung
liegt auf einem älteren VASC-Quellstand. Das tatsächlich gepackte
Sevii-Test-7-Paket basiert auf VASC 3.0.61; online ist bereits VASC 3.0.62.
Test 7 besitzt zudem den Modus TERRARIUM. Die frühere Gartenlichtung ist in
einer echten Kamera-Probe durchgefallen. Für die sichere Übernahme und alle
vier Ansichten gilt
[`SEVII_VASC_DOUBLE_INTEGRATION_DE.md`](SEVII_VASC_DOUBLE_INTEGRATION_DE.md).
Keine der älteren Voxel-Dateien darf das Test-7-Paket vollständig ersetzen.

Stand: 01.10.2026. Im aktuellen Sevii-Entwicklungsstand sind die 14 Insel-
und acht Turmtrainer echte Einzelkämpfe. Ihre Siege, Preise, Skalierung und
Rückkämpfe wurden in der nativen KASC-Kampf-Engine geprüft. Es gibt noch
keinen freigegebenen Sevii-Doppelkampf.

Die Gen-3-Engine besitzt einen vollständigen Vier-Battler-Modus mit
Zielauswahl, getrennten Befehlen, Auswechslungen und Doppel-HUD. Ihr
`battle_bridge` benötigt jedoch eine aktive Game3-Session und ein
Game3-Team. Sevii wird aktuell aus der KASC-Kanto-Overworld über
`src.battle.BattleState.newTrainer` gestartet; dieser Zustand hält pro Seite
nur einen aktiven Kämpfer. Ein `doubleBattle`-Kennzeichen an einem
Sevii-Trainer würde deshalb keinen Doppelkampf ergeben. Der Game3-Schaden
bestimmt physisch/speziell weiterhin nach Attackentyp; KASC erlaubt seit
Gen 4 die einzelne Attackenkategorie. Die Game3-Kampfregeln könnten also
Spieler-Pokémon und -Attacken aus späteren Generationen nicht unverändert
übernehmen. Ein stiller Wechsel zur Game3-Engine ist ausgeschlossen.

Voxel Ascendants bisherige KASC-Kampfbühne hatte nur je einen
Spieler- und Gegnerdarsteller. Eine additive Vier-Darsteller-Anordnung in
`lib/BattleScene.lua` legt nun zwei Fußpunkte pro Seite quer zur Kampfachse;
die vier einschlägigen Voxel-Layout-Tests bestehen. Die native
Sevii-Geländevermessung prüft begehbare, freie 5 × 7-Zellenbereiche und
Voxel-Kamerahöhen sowie die Sicht auf alle vier Fußpunkte:
**Strand, Vulkanpfad und Garten** besitzen je einen passenden Platz
(`double-arena-all-modes-final2.log`, 3/14). Der zuerst gefundene
Gartenplatz war für die Kamera blockiert; eine zweite Lichtung bei (9,6)
ist frei. Der Planer gibt nur diese drei vermessenen Plätze aus. Ein
echter visueller Kampf-Screenshot mit vier Sprites steht noch aus; die
Orte sind darum Kandidaten, keine freigegebenen Bühnen.
Brücke, Turmeingang und die anderen engen Orte dürfen nicht automatisch
als Vierer-Bühne gelten. Der neu angelegte Planer `sevii_double_arenas.lua`
bewegt keine Overworld-Figur und aktiviert noch keinen Kampf.

Voxel kann optionale `player2`-/`enemy2`-Darsteller jetzt jeweils in eine
eigene Textur einlesen. Der Partner-Capture stellt den ursprünglichen
Kampfzustand auch nach einem Fehler wieder her; der zugehörige Sprite-Test
besteht. Der native Erst- und Rückkampf blieb nach dieser Änderung
unverändert (`double-foundation-rematch-regression-final.log`, Stufe 75→77,
einmaliger Preis). Es gibt allerdings noch keinen echten Vier-Slot-KASC-Kampf, der
diese Daten liefert. Der native KASC-Kampfcontroller
braucht noch vier aktive Slots, zwei Befehle und Zielauswahl pro Seite,
Auswechslungen, Flächenattacken und korrekte Effekte/Boni. Erst dann kann
die Voxel-Szene diese Slots übernehmen; HUD und Animationen müssen ebenfalls
auf vier Kämpfer geprüft werden.

Die drei 3D-BTL-Ansichten sind jetzt separat vorbereitet:

| Ansicht | Vierer-Bühne im Quellbaum |
| --- | --- |
| MAP | Vier Darsteller und eigene Texturen; ein künftiger Sevii-Doppelkampf verwendet genau die vier vermessenen Kartenzellen statt eines zufälligen Zweier-Ankers. Auch große Sprites verschieben ihre Füße nicht aus der Lichtung. |
| DISCS | Vier Plattformen folgen den sichtbaren Füßen, auch wenn ein Kämpfer ausfällt; der Schattenpass nimmt alle vier Darsteller mit. |
| ARENA | Eine gemeinsame Bühne umschließt alle vier Füße; große Doppelpaare vergrößern den Kameraabstand. |

Der Modus OFF benutzt KASCs native 2D-Kampfoberfläche und deren bisherige
Einzelkampfsteuerung. Auch in MAP, DISCS und ARENA fehlen noch die native
Vier-Slot-Zugwahl und das vierteilige Kampf-HUD; die vorbereiteten Ansichten
sind daher kein spielbarer Doppelmodus. Die acht gezielten Voxel-Tests für
Layout, Plattformen, Sprite-Capture und bestehende Darstellungen bestehen.
Der echte Sevii-Erstkampf samt Rückkampf bestand nach dem Modus-Umbau
erneut (`double-all-modes-rematch-regression.log`, Stufe 75→77).

Ein nativer Kernversuch (`double-core-probe-c.log`) bestätigt eine sinnvolle
Wiederverwendung: KASCs `executeAction` kann eine Attacke eines zweiten
Spieler-Pokémon auf ein anderes Gegner-Pokémon anwenden, ohne den ersten
Gegner zu treffen. Das ist aber **noch kein spielbarer Doppelkampf**:
Zugauswahl, Aktionsreihenfolge, HP-Anzeigen, K.-o.-Abwicklung,
Einwechslung, Flächenattacken und Siegprüfung referenzieren im
Kampfcontroller weiterhin nur `self.player` und `self.enemy`. Diese
Mehrkämpfer-Lebenszyklen brauchen eine gemeinsame native Erweiterung, keine
zweite Einzelkampf-Instanz.

Eine saubere Umsetzung muss daher in dieser Reihenfolge erfolgen:

1. Den nativen KASC-Kampfcontroller auf vier aktive Slots erweitern und
   Attacken, Werte, Status, PP, Items, Einwechslungen und Siegzustand
   unverändert durch dieselben KASC-Regeln führen. NG+- und
   Generationsregeln bleiben wirksam.
2. Vier Befehle und ihre Ziel-/Statusanzeigen mit Maus, Tastatur und
   Controller bedienen; die vorbereitete Voxel-Szene muss alle vier
   Sprites, Effekte und Lebensbalken im echten Kampf sichtbar halten.
3. Erst dann einige räumlich passende Sevii-Kämpfe als Doppelkämpfe
   markieren. Trainerpaare bekommen genau einen gemeinsamen Siegzustand,
   einen Erstpreis und denselben Rückkampf-Cooldown wie Einzeltrainer.
4. Native Kämpfe einschließlich Wechsel, flächiger Attacken,
   Zielauswahl, K. o., Verlust, Speichern/Laden und Rückkampf auf
   frühen NG+- und späten Erstspielständen bestehen lassen.

Bis diese Punkte erfüllt sind, bleiben die vorhandenen Einzelkämpfe
unverändert; zwei unmittelbar aufeinanderfolgende Einzelkämpfe werden
nicht als Doppelkämpfe ausgewiesen.
