---
title: Medien eines Typs
---
Die Seiten „Medien eines Typs“ sind Unterseiten von Veranstaltungen. Dabei handelt es sich um die folgenden Seiten:

* [Lektionen](lessons.md)
* [Quizzes](quizzes.md)
* [Skript](manuscript.md)
* [Sonstiges](miscellaneous.md)
* [Übungen](exercises.md)
* [Wiederholung](repetition.md)
* [Worked Examples](worked-examples.md)

Diese Seiten sind identisch aufgebaut und ermöglichen Nutzer\*innen Zugriff auf alle Medien des jeweiligen Typs aus dieser Veranstaltung. Unterschiede bestehen nur in den auf den [Mediacards](mediacard.md) verfügbaren Bedienelementen.

![](/img/Lektionen_thumb.png)

## Bereiche der Seite
Die Seiten gliedern sich in vier Teilbereiche: die eigentliche Seite, die [Navigationsleiste](nav-bar.md), die [Seitenleiste](sidebar.md) zur Navigation innerhalb einer Veranstaltung und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Lektionen“ eingezeichnet.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_eigentliche_Seite.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_navbar.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_sidebar.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer.png" height="180"/>|
|:---: | :---: |:---: | :---:|
|Eigentliche Seite|Navigationsleiste|Seitenleiste|Footer|

Die eigentliche Seite besteht ebenfalls aus drei Teilbereichen: den Seiteneinstellungen, der Seitennavigation und den Mediacards. Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Lektionen“ markiert.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seiteneinstellungen.png" height="250"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seitennavigation.png" height="250"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Mediacards.png" height="250"/>|
|:---: | :---: | :---:|
|Seiteneinstellungen|Seitennavigation|Mediacards|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Nun werden sämtliche mögliche Bedienelemente einer Seite eines Medientyps sortiert nach Seitenbereich aufgeführt.

### Seiteneinstellungen

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seiteneinstellungen_close.png" height="50"/>|
|:---: |
|Buttons für die Seiteneinstellungen|

* <button name="button">Reihenfolge umkehren</button> Ändere die Sortierreihenfolge der Medien.
* <button name="button">alle</button> Zeige alle Medien auf einer Seite an. Dieser Button ist nicht vorhanden, wenn bereits alle Medien auf einer Seite angezeigt werden.
* <label for="cars"></label>
  <select name="cars" id="cars">
     <option value="" selected disabled hidden>pro Seite</option>
     <option value="volvo">3</option>
     <option value="saab">4</option>
     <option value="mercedes">8</option>
     <option value="audi">12</option>
     <option value="volvo1">24</option>
     <option value="saab2">48</option>
  </select> Bestimme die Anzahl der pro Seite angezeigten Medien. Zur Auswahl stehen <i>3</i>, <i>4</i>, <i>8</i> (standardmäßig), <i>12</i>, <i>24</i> und <i>48</i>.
* <label for="cars"></label>
  <select name="cars" id="cars">
     <option value="" selected disabled hidden>Zusatzmaterialien</option>
     <option value="volvo">zu bereits Behandeltem</option>
     <option value="saab">keine</option>
     <option value="mercedes">alle</option>
  </select> Ändere Einstellung für die Anzeige von Zusatzmaterialien: <i>zu bereits Behandeltem</i> (standardmäßig), <i>keine</i> oder <i>alle</i>.

### Seitennavigation
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seitennavigation_close_1.png" height="40"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seitennavigation_close_2.png" height="40"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seitennavigation_close_3.png" height="40"/>|
|:---: | :---: | :---:|
|Auf der ersten Seite|Zwischen erster und letzter Seite|Auf der letzten Seite|

* <button name="button">n</button> Wechsel auf Seite n.
* <button name="button">Nächste</button> bzw. <button name="button">Vorige</button> Wechsel auf die nächste bzw. vorige Seite.
* <button name="button">Letzte</button> bzw. <button name="button">Erste</button> Wechsel auf die letzte bzw. erste Seite.

### Mediacards
Die auf den Mediacards vorkommenden Bedienelemente richten sich nach dem Medientyp. Nach diesem wird im Folgenden differenziert.

\*Screenshot\*

#### Lektion
* <a href="/mampf/de/mampf-pages/session" target="_self"><button name="button">Sitzung</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/session" target="_self">Seite der Sitzung</a>.
* <a href="/mampf/de/mampf-pages/tag" target="_self"><button name="button">Begriff</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/tag" target="_self">Seite des Begriffs</a>.
* <button name="button"><a href="/mampf/de/mampf-pages/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button> Spiele das Video mit <a href="/mampf/de/mampf-pages/thyme" target="_self">THymE</a> ab.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="8"/></button> Öffne externen Link.
* <button name="button"><a href="/mampf/de/mampf-pages/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/mampf-pages/medium" target="_self">Medienseite der Lektion</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>mp4</button> Lade das Video herunter.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> Lade das PDF herunter.
* <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">n Kommentare</button></a> Öffne die zum Medium gehörige <a href="/mampf/de/mampf-pages/comments-medium" target="_self">Kommentarseite</a>, um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.

#### Quiz
* <a href="/mampf/de/mampf-pages/event-series" target="_self"><button name="button">Veranstaltung</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/event-series" target="_self">Seite der Veranstaltung</a>.
* <a href="/mampf/de/mampf-pages/tag" target="_self"><button name="button">Begriff</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/tag" target="_self">Seite des Begriffs</a>.
* <button name="button"><a href="/mampf/de/mampf-pages/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/mampf-pages/medium" target="_self">Medienseite des Quiz'</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/videogame-asset.png" height="12"/></button> Starte das Quiz.
* <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">n Kommentare</button></a> Öffne die zum Medium gehörige <a href="/mampf/de/mampf-pages/comments-medium" target="_self">Kommentarseite</a>, um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.

#### Skript
* <a href="/mampf/de/mampf-pages/event-series" target="_self"><button name="button">Veranstaltung</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/event-series" target="_self">Seite der Veranstaltung</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF.
* <button name="button"><a href="/mampf/de/mampf-pages/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/mampf-pages/tag" target="_self">Medienseite des Skripts</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> Lade das PDF herunter.
* <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">n Kommentare</button></a> Öffne die zum Medium gehörige <a href="/mampf/de/mampf-pages/comments-medium" target="_self">Kommentarseite</a>, um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.

#### Sonstiges
* <a href="/mampf/de/mampf-pages/event-series" target="_self"><button name="button">Veranstaltung</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/event-series" target="_self">Seite der Veranstaltung</a>.
* <a href="/mampf/de/mampf-pages/tag" target="_self"><button name="button">Begriff</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/tag" target="_self">Seite des Begriffs</a>.
* <button name="button"><a href="/mampf/de/mampf-pages/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button> Spiele das Video mit <a href="/mampf/de/mampf-pages/thyme" target="_self">THymE</a> ab.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="8"/></button> Öffne externen Link.
* <button name="button"><a href="/mampf/de/mampf-pages/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/mampf-pages/medium" target="_self">Medienseite</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>mp4</button> Lade das Video herunter.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> Lade das PDF herunter.
* <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">n Kommentare</button></a> Öffne die zum Medium gehörige <a href="/mampf/de/mampf-pages/comments-medium" target="_self">Kommentarseite</a>, um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.

#### Übung
* <a href="/mampf/de/mampf-pages/event-series" target="_self"><button name="button">Veranstaltung</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/event-series" target="_self">Seite der Veranstaltung</a>.
* <a href="/mampf/de/mampf-pages/tag" target="_self"><button name="button">Begriff</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/tag" target="_self">Seite des Begriffs</a>.
* <button name="button"><a href="/mampf/de/mampf-pages/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button> Spiele das Video mit <a href="/mampf/de/mampf-pages/thyme" target="_self">THymE</a> ab.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="8"/></button> Öffne den externen Link.
* <button name="button"><a href="/mampf/de/mampf-pages/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/mampf-pages/medium" target="_self">Medienseite der Übung</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>mp4</button> Lade das Video herunter.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> Lade das PDF herunter.
* <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">n Kommentare</button></a> Öffne die zum Medium gehörige <a href="/mampf/de/mampf-pages/comments-medium" target="_self">Kommentarseite</a>, um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.

#### Wiederholung
* <a href="/mampf/de/mampf-pages/event-series" target="_self"><button name="button">Veranstaltung</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/event-series" target="_self">Seite der Veranstaltung</a>.
* <a href="/mampf/de/mampf-pages/tag" target="_self"><button name="button">Begriff</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/tag" target="_self">Seite des Begriffs</a>.
* <button name="button"><a href="/mampf/de/mampf-pages/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button> Spiele das Video mit <a href="/mampf/de/mampf-pages/thyme" target="_self">THymE</a> ab.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="8"/></button> Öffne externen Link.
* <button name="button"><a href="/mampf/de/mampf-pages/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/mampf-pages/medium" target="_self">Medienseite der Wiederholung</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>mp4</button> Lade das Video herunter.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> Lade das PDF herunter.
* <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">n Kommentare</button></a> Öffne die zum Medium gehörige <a href="/mampf/de/mampf-pages/comments-medium" target="_self">Kommentarseite</a>, um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.

#### Worked Example
* <a href="/mampf/de/mampf-pages/event-series" target="_self"><button name="button">Veranstaltung</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/event-series" target="_self">Seite der Veranstaltung</a>.
* <a href="/mampf/de/mampf-pages/tag" target="_self"><button name="button">Begriff</button></a> Gehe auf die <a href="/mampf/de/mampf-pages/tag" target="_self">Seite des Begriffs</a>.
* <button name="button"><a href="/mampf/de/mampf-pages/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button> Spiele das Video mit <a href="/mampf/de/mampf-pages/thyme" target="_self">THymE</a> ab.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="8"/></button> Öffne externen Link.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/leak-add.png" height="12"/></button> Öffne das Geogebra-Applet.
* <button name="button"><a href="/mampf/de/mampf-pages/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/mampf-pages/medium" target="_self">Medienseite des Worked Examples</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>mp4</button> Lade das Video herunter.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> Lade das PDF herunter.
* <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">n Kommentare</button></a> Öffne die zum Medium gehörige <a href="/mampf/de/mampf-pages/comments-medium" target="_self">Kommentarseite</a>, um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.

#### Übersicht
Bedienelement | Medientyp | Aktion
------------- | --------- | ------
<a href="/mampf/de/mampf-pages/session" target="_self"><button name="button">Sitzung</button></a> | nur Lektion | Gehe auf die [Seite der Sitzung](session.md).
<a href="/mampf/de/mampf-pages/event-series" target="_self"><button name="button">Veranstaltung</button></a> | alle außer Lektion | Gehe auf die [Seite der Veranstaltung](event-series.md).
<a href="/mampf/de/mampf-pages/tag" target="_self"><button name="button">Begriff</button></a> | alle außer Skript | Gehe auf die [Seite des Begriffs](tag.md).
<button name="button"><a href="/mampf/de/mampf-pages/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button> | Lektion, Sonstiges, Übung, Wiederholung und Worked Example | Spiele das Video mit [THymE](thyme.md) ab.
<button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> | Lektion, Skript, Sonstiges, Übung, Wiederholung und Worked Example | Öffne das PDF.
<button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="8"/></button> | Lektion, Sonstiges, Übung, Wiederholung und Worked Example | Öffne den externen Link.
<button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/videogame-asset.png" height="12"/></button>| nur Quiz | Starte das Quiz.
<button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/leak-add.png" height="12"/></button> | nur Worked Example | Öffne Geogebra-Applet.
<button name="button"><a href="/mampf/de/mampf-pages/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> | alle | Öffne die [Medienseite](medium.md)
<button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>mp4</button> | Lektion, Sonstiges, Übung, Wiederholung und Worked Example | Lade das Video herunter.
<button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> | Lektion, Skript, Sonstiges, Übung, Wiederholung und Worked Example | Lade das PDF herunter.
<a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/mampf-pages/comments-medium" target="_self"><button name="button">n Kommentare</button></a> | alle | Öffne die zum Medium gehörige [Kommentarseite](comments-medium), um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.
