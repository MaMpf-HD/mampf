---
title: Skript
---
Die Seite „Skript“ ist eine Unterseite einer Veranstaltung. Sie ermöglicht Nutzer\*innen Zugriff auf das Skript der Veranstaltung. Dieses kann betrachtet, heruntergeladen und kommentiert werden.

\*Links ergänzen\*

## Navigation zu dieser Seite
\*Realisierung überlegen und ergänzen\*

## Bereiche der Seite
Die Seite „Skript“ gliedert sich in vier Teilbereiche: die eigentliche Seite „Skript“, die [Navigationsleiste](nav-bar.md), die [Seitenleiste](sidebar.md) zur Navigation innerhalb einer Veranstaltung und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Lektionen“ eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_eigentliche_Seite.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_navbar.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_sidebar.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer.png" height="180"/>|
|:---: | :---: |:---: | :---:|
|Eigentliche Seite|Navigationsleiste|Seitenleiste|Footer|

Die eigentliche Seite besteht aus zwei Teilbereichen: den Seiteneinstellungen und den [Mediacards](mediacard.md).

\*theoretisch drei; man kann so viele Skripte importieren, dass es Seitennavigation gibt...\*

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seiteneinstellungen.png" height="250"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seitennavigation.png" height="250"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Mediacards.png" height="250"/>|
|:---: | :---: | :---:|
|Seiteneinstellungen|Seitennavigation|Mediacards|

## Bedienelemente und mögliche Aktionen auf dieser Seite
### Seiteneinstellungen
* <button name="button">Reihenfolge umkehren</button> Ändere die Sortierreihenfolge der Medien.
* <label for="cars"></label><select name="cars" id="cars">
  <option value="" selected disabled hidden>pro Seite</option>
  <option value="volvo">3</option>
  <option value="saab">4</option>
  <option value="mercedes">8</option>
  <option value="audi">12</option>
  <option value="volvo1">24</option>
  <option value="saab2">48</option>
</select> Bestimme die Anzahl der pro Seite angezeigten Medien. Zur Auswahl stehen <i>3</i>, <i>4</i>, <i>8</i> (standardmäßig), <i>12</i>, <i>24</i> und <i>48</i>.
* <label for="cars"></label><select name="cars" id="cars">
  <option value="" selected disabled hidden>Zusatzmaterialien</option>
  <option value="volvo">zu bereits Behandeltem</option>
  <option value="saab">keine</option>
  <option value="mercedes">alle</option>
</select> Ändere Einstellung für die Anzeige von Zusatzmaterialien: <i>zu bereits Behandeltem</i> (standardmäßig), <i>keine</i> oder <i>alle</i>.

### Mediacards
* <a href="/mampf/de/docs/event-series" target="_self"><button name="button">Veranstaltung</button></a> Gehe auf die <a href="/mampf/de/docs/event-series" target="_self">Seite der Veranstaltung</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF.
* <button name="button"><a href="/mampf/de/docs/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/docs/tag" target="_self">Medienseite des Skripts</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> Lade das PDF herunter.
* <a href="/mampf/de/docs/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/docs/comments-medium" target="_self"><button name="button">n Kommentare</button></a> Öffne die zum Medium gehörige <a href="/mampf/de/docs/comments-medium" target="_self">Kommentarseite</a>, um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.

## Von dieser Seite aus aufrufbare Seiten
Von der Seite „Skript“ gelangt man zu diversen anderen Seiten. Im Weiteren wird beschrieben, welche Informationen diese Seiten enthalten und welche Aktionen dort möglich sind.

Zu den verwendeten Begriffen siehe die Erläuterungen zu Medium, Skript und Veranstaltung.

\*Links ergänzen\*

### [Veranstaltungsseite](event-series.md)
Die Veranstaltungsseite informiert über neue Mitteilungen und Forumsbeiträge. Weiterhin gibt sie einen Überblick über den Veranstaltungsinhalt in Form einer Gliederung. Die Veranstaltungsseite öffnet sich durch Klicken auf den <a href="/mampf/de/docs/event-series" target="_self"><button name="button">Veranstaltungstitel</button></a>.

### [Medienseite des Skripts](medium.md)
Auf der Medienseite stehen weitere Informationen zu Umfang, Größe und Inhalt des Skripts zur Verfügung. Außerdem sind mit dem Skript verknüpfte Medien aufgeführt und verlinkt. Darüber hinaus können Kommentare verfasst und gelesen werden. Um auf eine Medienseite zu gelangen, muss man auf den <button name="button"><a href="/mampf/de/docs/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button>-Button klicken.

### [Kommentarseite](comments-medium.md)
Auf dieser Seite können Kommentare gelesen, verfasst und durch Upvote als hilreich gekennzeichnet werden. Eigene Kommentare können geändert und gelöscht werden. Außerdem kann eine Diskussion abonniert werden. Über abonnierte Diskussionen wird man per E-Mail auf dem Laufenden gehalten. Editor\*innen können zudem Diskussionen beenden und Kommentare löschen. Zur Kommentarseite gelangt man, indem auf <a href="/mampf/de/docs/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/docs/comments-medium" target="_self"><button name="button">n Kommentare</button></a> klickt.

## Verwandte Seiten
### Übergeordnete Seite
[Veranstaltungsseite](event-series.md)

### Gleichgrangige Seiten
* [Abgaben](submissions.md)
* [Beispiel-Datenbank](erdbeere.md)
* [Lektionen](lessons.md)
* [Mitteilungen](announcements.md)
* [Modul](module.md)
* [Organisatorisches](general-information.md)
* [Quizzes](quizzes.md)
* [Selbsttest](self-assessment.md)
* [Sonstiges](miscellaneous.md)
* [Übungen](exercises.md)
* [Wiederholung](repetition.md)
* [Worked Examples](worked-examples.md)
