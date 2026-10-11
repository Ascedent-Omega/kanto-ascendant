# KASC: optionale Fangserie

Die eigenständige Card **FANGSERIE / CATCH COMBO** ist im KASC-Menü
standardmäßig eingeschaltet und lässt sich dort deaktivieren. Nur der Fang
wilder Pokémon zählt. Wiederholte Fänge derselben Art erhöhen die Serie;
ein Fang einer anderen Art beginnt bei 1. Eine Flucht des wilden Pokémon
bricht sie ab. Eigene Flucht, Gehen, Kartenwechsel und andere Kämpfe erhalten
die Serie. Der aktuelle Stand steht im Shiny-Dex und wird gespeichert.
Die Card wirkt bereits im normalen Kanto-Durchlauf ab den ersten wilden
Begegnungen; der Shiny-Dex mit dem sichtbaren Zähler ist dafür schon vor
der Liga über das ASCENDANT-Menü erreichbar. Sevii ist keine Voraussetzung.

Ab 11, 21 und 31 Fängen erhält **nur diese Art** im Shiny-Modus
**ASCENDANT** zusätzlich 1, 3 oder 6 Shiny-Würfe. Die Stufen sind an die
Fangserien-Idee von *Pokémon: Let's Go* angelehnt; die Würfelzahlen sind
für KASC gewählt und keine behaupteten Originalquoten. Die [offizielle
Beschreibung der Fangserie](https://www.pokemon.com/us/features/keep-that-catch-combo-going)
nennt insbesondere dieselbe Art, die wilde Flucht und die Stufe über 30.
Im Modus
**NATÜRLICH 1/8192** wirkt die Card nicht auf die Shiny-Chance. Bei
deaktivierter Card gibt es weder Serienzuwachs noch Bonuswürfe.

Der isolierte Lua-Test prüft Zähler, Stufen und Abbruch. Ein nativer
Clienttreiber prüft Fangereignisse, die echte Begegnungs- und Shiny-
Vorprüfung, den Fluchtweg, den Schalter und Speichern/Laden. Dies ist
kein statistischer Langzeittest der Shiny-Quote.
