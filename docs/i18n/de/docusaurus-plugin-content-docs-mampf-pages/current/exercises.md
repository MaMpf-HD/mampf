---
title: Übungen
---
Die Seite „Übungen“ ist eine Unterseite einer Veranstaltung. Sie ermöglicht Nutzer\*innen Zugriff auf die Übungen zur Veranstaltung. In einer Übung werden inhaltlich zusammengehörende Dateien (PDF, Video und externer Link) gebündelt. Diese können betrachtet, heruntergeladen und kommentiert werden.

\*Links ergänzen\*

## Navigation zu dieser Seite
\*Realisierung überlegen und ergänzen\*

## Bereiche der Seite
Die Seite „Übungen“ gliedert sich in vier Teilbereiche: die eigentliche Seite „Übungen“, die [Navigationsleiste](nav-bar.md), die [Seitenleiste](sidebar.md) zur Navigation innerhalb einer Veranstaltung und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Lektionen“ eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_eigentliche_Seite.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_navbar.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_sidebar.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer.png" height="180"/>|
|:---: | :---: |:---: | :---:|
|Eigentliche Seite|Navigationsleiste|Seitenleiste|Footer|

Die eigentliche Seite besteht ebenfalls aus drei Teilbereichen: den Seiteneinstellungen, der Seitennavigation und den [Mediacards](mediacard.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Lektionen“ markiert.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seiteneinstellungen.png" height="250"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seitennavigation.png" height="250"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Mediacards.png" height="250"/>|
|:---: | :---: | :---:|
|Seiteneinstellungen|Seitennavigation|Mediacards|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Mithilfe eines Screenshots, auf dem drei [Mediacards](mediacard.md) zu sehen sind, werden nun sämtliche mögliche Buttons der Seite „Übungen“ beschrieben.

### Seiteneinstellungen
* <button name="button">Reihenfolge umkehren</button> Ändere die Sortierreihenfolge der Medien.
* <button name="button">alle</button> Zeige alle Medien auf einer Seite an. Dieser Button ist nicht vorhanden, wenn bereits alle Übungen auf einer Seite angezeigt werden.
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

### Seitennavigation
* <button name="button">n</button> Wechsel auf Seite n.
* <button name="button">Nächste</button> bzw. <button name="button">Vorige</button> Wechsel auf die nächste bzw. vorige Seite.
* <button name="button">Letzte</button> bzw. <button name="button">Erste</button> Wechsel auf die letzte bzw. erste Seite.

### Mediacards
* <a href="/mampf/de/docs/event-series" target="_self"><button name="button">Veranstaltung</button></a> Gehe auf die <a href="/mampf/de/docs/event-series" target="_self">Seite der Veranstaltung</a>.
* <a href="/mampf/de/docs/tag" target="_self"><button name="button">Begriff</button></a> Gehe auf die <a href="/mampf/de/docs/tag" target="_self">Seite des Begriffs</a>.
* <button name="button"><a href="/mampf/de/docs/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button> Spiele das Video mit <a href="/mampf/de/docs/thyme" target="_self">THymE</a> ab.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="8"/></button> Öffne den externen Link.
* <button name="button"><a href="/mampf/de/docs/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/docs/tag" target="_self">Medienseite der Übung</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>mp4</button> Lade das Video herunter.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> Lade das PDF herunter.
* <a href="/mampf/de/docs/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/docs/comments-medium" target="_self"><button name="button">n Kommentare</button></a> Öffne die zum Medium gehörige <a href="/mampf/de/docs/comments-medium" target="_self">Kommentarseite</a>, um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.

## Hinweis zum Fehlen von Bedienelementen
Nicht immer sind alle der aufgeführten Bedienelemente verfügbar. Eine Übung kann aus einem PDF, einem Video und einem externen Link bestehen, sie kann aber auch weniger Komponenten enthalten. Die entsprechenden Buttons sind nur vorhanden, wenn dies auch für die entsprechenden Dateien gilt. Ebenso verhält es sich bei den Buttons zur Seitennavigation: Erst wenn es mehr Übungen gibt, als pro Seite angezeigt werden sollen (standardmäßig acht), sind diese Buttons verfügbar. Damit Begriffe angezeigt werden, müssen welche mit der Übung verknüpft sein.

## Von dieser Seite aus aufrufbare Seiten
Von der Seite „Übungen“ gelangt man zu diversen anderen Seiten. Im Weiteren wird beschrieben, welche Informationen diese Seiten enthalten und welche Aktionen dort möglich sind. Die vorhandenen Bedienelemente bestimmen, welche Seiten erreichbar sind.

Zu den verwendeten Begriffen siehe die Erläuterungen zu Begriff, Medium, THymE, Übung und Veranstaltung.

\*Links ergänzen\*

### [Veranstaltungsseite](event-series.md)
Die Veranstaltungsseite informiert über neue Mitteilungen und Forumsbeiträge. Weiterhin gibt sie einen Überblick über den Veranstaltungsinhalt in Form einer Gliederung. Die Veranstaltungsseite öffnet sich durch Klicken auf den <a href="/mampf/de/docs/event-series" target="_self"><button name="button">Veranstaltungstitel</button></a>.

### [Seite der getaggten Begriffe](tag.md)
Auf dieser Seite werden Synonyme und Übersetzungen des Begriffs aufgelistet. Zudem sind verknüpfte Begriffe, Abschnitte und Medien angeben und verlinkt. Die Beziehungen zu anderen Begriffen wird mit einer Mindmap visualisiert. Diese Mindmap kann auch zur Navigation genutzt werden. Begriffsseiten öffnen sich durch Klick auf den jeweiligen <a href="/mampf/de/docs/tag" target="_self"><button name="button">Begriff</button></a>.

### [THymE-Player](thyme.md)
Im THymE-Player können Videos abgespielt werden. Der Player zeigt zudem eine Gliederung des Videos und weiterführende Informationen (z.B. Links zu Zusatzmaterial) an. Er öffnet sich durch Klicken auf den <button name="button"><a href="/mampf/de/docs/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button>-Button.

### [Medienseite einzelner Übungen](medium.md)
Auf der Medienseite stehen weitere Informationen zu Umfang, Größe und Inhalt der Übung zur Verfügung. Außerdem sind mit der Übung verknüpfte Medien und Begriffe aufgeführt und verlinkt. Darüber hinaus können Kommentare verfasst und gelesen werden. Um auf eine Medienseite zu gelangen, muss man auf den <button name="button"><a href="/mampf/de/docs/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button>-Button klicken.

### [Kommentarseite](comments-media.md)
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
* [Skript](manuscript.md)
* [Sonstiges](miscellaneous.md)
* [Wiederholung](repetition.md)
* [Worked Examples](worked-examples.md)