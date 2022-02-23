---
title: Lektionen
---
Die Seite „Lektionen“ ist eine Unterseite einer Veranstaltung. Sie ermöglicht Nutzer\*innen Zugriff auf Lektionen der Veranstaltung. In einer Lektion werden inhaltlich zusammengehörende Dateien (PDF, Video und externer Link) gebündelt. Diese können betrachtet bzw. abgespielt und heruntergeladen sowie kommentiert werden.

![](/img/Lektionen_thumb.png)

\*Links ergänzen\*

## Navigation zu dieser Seite
\*Realisierung überlegen und ergänzen\*

## Bereiche der Seite
Die Seite „Lektionen“ gliedert sich in vier Teilbereiche: die eigentliche Seite „Lektionen“, die [Navigationsleiste](nav-bar.md), die [Seitenleiste](sidebar.md) zur Navigation innerhalb einer Veranstaltung und den [Footer](footer.md). Die Bereiche sind in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_eigentliche_Seite.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_navbar.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Lektionen_sidebar.png" height="150"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer.png" height="180"/>|
|:---: | :---: |:---: | :---:|
|Eigentliche Seite|Navigationsleiste|Seitenleiste|Footer|

Die eigentliche Seite kann ebenfalls in Teilbereichen eingeteilt werden: den Seiteneinstellungen, der Seitennavigation und den [Mediacards](mediacard.md). In den folgenden Screenshots sind diese Bereiche markiert.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seiteneinstellungen.png" height="250"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Seitennavigation.png" height="250"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Mediacards.png" height="250"/>|
|:---: | :---: | :---:|
|Seiteneinstellungen|Seitennavigation|Mediacards|

## Bedienelemente und mögliche Aktionen auf dieser Seite
### Seiteneinstellungen
* <button name="button">Reihenfolge umkehren</button> Ändere die Sortierreihenfolge der Medien.
* <button name="button">alle</button> Zeige alle Medien auf einer Seite an. Dieser Button ist nicht vorhanden, wenn bereits alle Lektionen auf einer Seite angezeigt werden.
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
* <button name="button">n</button> Wechsel auf Seite n.
* <button name="button">Nächste</button> bzw. <button name="button">Vorige Wechsel</button> auf die nächste bzw. vorige Seite.
* <button name="button">Letzte</button> bzw. <button name="button">Erste</button> Wechsel auf die letzte bzw. erste Seite.

### Mediacards
* <a href="/mampf/de/docs/session" target="_self"><button name="button">Sitzung</button></a> Gehe auf die <a href="/mampf/de/docs/session" target="_self">Seite der Sitzung</a>.
* <a href="/mampf/de/docs/tag" target="_self"><button name="button">Begriff</button></a> Gehe auf die Seite des <a href="/mampf/de/docs/tag" target="_self">Begriffs</a>.
* <button name="button"><a href="/mampf/de/docs/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button> Spiele das Video mit <a href="/mampf/de/docs/thyme" target="_self">THymE</a> ab.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="8"/></button> Öffne den externen Link.
* <button name="button"><a href="/mampf/de/docs/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/docs/medium" target="_self">Medienseite der Lektion</a>.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>mp4</button> Lade das Video herunter.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> Lade das PDF herunter.
* <a href="/mampf/de/docs/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/docs/comments-medium" target="_self"><button name="button">n Kommentare</button></a> Öffne die zum Medium gehörige <a href="/mampf/de/docs/comments-medium" target="_self">Kommentarseite</a>, um einen Kommentar zu verfassen oder bereits veröffentlichte Kommentare zu lesen.

## Hinweis zum Fehlen von Bedienelementen
Nicht immer sind alle der aufgeführten Bedienelemente verfügbar. Eine Lektion kann aus einem PDF, einem Video und einem externen Link bestehen, sie kann aber auch weniger Komponenten enthalten. Die entsprechenden Buttons sind nur vorhanden, wenn dies auch für die entsprechenden Dateien gilt. Ebenso verhält es sich bei den Buttons zur Seitennavigation: Erst wenn es mehr Lektionen gibt, als pro Seite angezeigt werden sollen (standardmäßig acht), sind diese Buttons verfügbar. Damit Begriffe angezeigt werden, müssen welche mit der Lektion verknüpft sein. Die Verlinkung zur Sitzung ist nur vorhanden, wenn eine Sitzung assoziiert ist.

## Von dieser Seite aus aufrufbare Seiten
Von der Seite „Lektionen“ gelangt man zu diversen anderen Seiten. Im Weiteren wird beschrieben, welche Informationen diese Seiten enthalten und welche Aktionen dort möglich sind. Die vorhandenen Bedienelemente bestimmen, welche Seiten erreichbar sind.

Zu den verwendeten Begriffen siehe die Erläuterungen zu Begriff, Medium, Lektion, Sitzung und THymE.

\*Links ergänzen\*

### [Seite der assoziierten Sitzung](session.md)
Auf der Sitzungsseite gibt es eine Gliederung, mit der zur gewünschten Stelle im PDF oder Video navigiert werden kann, und eine Übersicht über alle verknüpften Begriffe, Abschnitte und Medien. Diese sind ebenfalls verlinkt und können durch Anklicken geöffnet werden. Sitzungsseiten sind über den <a href="/mampf/de/docs/session" target="_self"><button name="button">Titel</button></a> erreichbar.

### [Seite der getaggten Begriffe](tag.md)
Auf dieser Seite werden Synonyme und Übersetzungen des Begriffs aufgelistet. Zudem sind verknüpfte Begriffe, Abschnitte und Medien angeben und verlinkt. Die Beziehungen zu anderen Begriffen wird mit einer Mindmap visualisiert. Diese Mindmap kann auch zur Navigation genutzt werden. Begriffsseiten öffnen sich durch Klick auf den jeweiligen <a href="/mampf/de/docs/tag" target="_self"><button name="button">Begriff</button></a>.

### [THymE-Player](thyme.md)
Im THymE-Player können Videos abgespielt werden. Der Player zeigt zudem eine Gliederung des Videos und weiterführende Informationen (z.B. Links zu Zusatzmaterial) an. Er öffnet sich durch Klicken auf den <button name="button"><a href="/mampf/de/docs/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button>-Button.

### [Medienseite einzelner Lektionen](medium.md)
Auf der Medienseite stehen weitere Informationen zu Länge bzw. Umfang und Größe von PDFs bzw. Videos zur Verfügung. Über die dort aufgeführte Gliederung der Lektion kann an die entsprechende Stelle im PDF oder Video gesprungen werden. Außerdem sind mit dieser Lektion verknüpfte Medien und Begriffe aufgeführt und verlinkt. Zudem können Kommentare verfasst und gelesen werden. Um auf eine Medienseite zu gelangen, muss man auf den <button name="button"><a href="/mampf/de/docs/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button>-Button klicken.

### [Kommentarseite](comments-medium.md)
Auf dieser Seite können Kommentare gelesen, verfasst und durch Upvote als hilfreich gekennzeichnet werden. Eigene Kommentare können geändert und gelöscht werden. Außerdem kann eine Diskussion abonniert werden. Über abonnierte Diskussionen wird man per E-Mail auf dem Laufenden gehalten. Editor\*innen können zudem Diskussionen beenden und Kommentare löschen. Zur Kommentarseite gelangt man, indem auf <a href="/mampf/de/docs/comments-medium" target="_self"><button name="button">Kommentieren</button></a> bzw. <a href="/mampf/de/docs/comments-medium" target="_self"><button name="button">n Kommentare</button></a> klickt.

## Hinweise für Editor*innen
### Seite bearbeiten

Zum Anlegen und Bearbeiten von Lektionen siehe die Seite [„Veranstaltung bearbeiten“](ed-edit-event-series).

### Zusätzliche Informationen auf Mediacards

Auf den [Mediacards](mediacard) können sich zusätzliche Informationen befinden. Das Symbol <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/file-import-solid.png" height="12"/> im Header weist darauf hin, dass das Medium aus einer anderen Veranstaltung importiert worden ist. Bei Editor\*innen befinden sich gegebenenfalls zusätzliche Icons auf den Mediacards, die Auskunft über die Sichtbarkeit eines Mediums geben.

\* Screenshots \*

| Symbol | Bedeutung |
| :---: | :--- |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/eye-slash-solid-red.png" height="12"/> | Das Medium ist noch nicht veröffentlicht. Einfache Nutzer*innen können es noch nicht sehen. |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/eye-slash-solid-blue.png" height="12"/> | Das Medium ist auf Modulebene angesiedelt und mit Tags versehen, die in der Veranstaltung noch nicht behandelt worden sind. Bevor diese Begriffe in der Veranstaltung verwendet worden sind, können einfache Nutzer\*innen dieses Medium nur sehen, wenn sie *alle* im Menü <button name="button">Zusatzmaterialien <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/arrow-drop-down.png" height="12"/></button> ausgewählt haben. Diese Wahl ist nicht die Standardeinstellung. |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/calendar-check-solid-red.png" height="12"/> | Das Medium ist noch nicht veröffentlicht, aber die Veröffentlichung ist geplant. Einfache Nutzer*innen können dieses Medium erst nach dem Zeitpunkt der Veröffentlichung sehen. Dieser kann mithilfe des Tooltips in Erfahrung gebracht werden. |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/lock-solid-red.png" height="12"/> | Das Medium ist gesperrt. Einfache Nutzer*innen können es nicht mehr sehen. |

## Verwandte Seiten
### Übergeordnete Seite
[Veranstaltungsseite](event-series.md)

### Gleichrangige Seiten
* [Abgaben](submissions.md)
* [Beispiel-Datenbank](erdbeere.md)
* [Mitteilungen](announcements.md)
* [Modul](module.md)
* [Organisatorisches](general-information.md)
* [Quizzes](quizzes.md)
* [Selbsttest](self-assessment.md)
* [Skript](manuscript.md)
* [Sonstiges](miscellaneous.md)
* [Übungen](exercises.md)
* [Wiederholung](repetition.md)
* [Worked Examples](worked-examples.md)
