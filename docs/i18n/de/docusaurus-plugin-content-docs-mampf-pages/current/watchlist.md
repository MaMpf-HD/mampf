---
title: Watchlist
---

Auf der Seite „Watchlist“ können Nutzer\*innen Medienlisten anlegen, betrachten und bearbeiten.

![](/img/watchlist.png)

## Navigation zu dieser Seite

Die Seite „Watchlist“ erreicht man, indem auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/list-solid.png" height="15"/></button> oben links in der [Navigationsleiste](nav-bar.md) klickt.

## Bereiche der Seite
Die Seite „Watchlist“ gliedert sich in drei große Teilbereiche: die eigentliche Seite „Watchlist“, die [Navigationsleiste](nav-bar.md) und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Sitzung“ eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Eigentliche_Seite_keine_Sidebar.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Navigationsleiste_keine_Sidebar.png" height="300"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer_keine_Sidebar.png" height="300"/>|
|:---: | :---: | :---:|
|Eigentliche Seite|Navigationsleiste|Footer|

Die eigentliche Seite lässt sich ebenfalls in verschiedene Teilbereiche einteilen: den Auswahl- und Bearbeitungsbereich, die Seiteneinstellungen, die Mediacards und die Seitennavigation. In den folgenden Screenshots sind diese Bereiche markiert.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/watchlist_edit.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/watchlist_seiteneinstellungen.png" height="300"/> |
|:---: | :---: |
|Auswahl und Bearbeitung|Seiteneinstellungen|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/watchlist_mediacards.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/watchlist_seitennavigation.png" height="300"/> |
|Mediacards|Seitennavigation|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Die Bedienelemente der Seite „Watchlist“ werden im Folgenden aufgeführt. Dabei werden die Bedienelemente, die sich in einem der oben beschriebenen Teilbereiche befinden, gemeinsam vorgestellt.

### Auswahl und Bearbeitung
* <button name="button">Noch keine Watchlist angelegt</button> bzw. <button name="button">Ausgewählte Watchlist</button> bzw. <label for="cars"></label>
  <select name="cars" id="cars">
     <option value="" selected disabled hidden>Ausgewählte Wachtlist</option>
     <option value="volvo">Weitere Watchlist</option>
     <option value="saab">Weitere Watchlist</option>
     <option value="mercedes">Weitere Watchlist</option>
  </select><br></br>
  Wenn keine Watchlist vorhanden ist, wird <button name="button">Noch keine Watchlist angelegt</button> angezeigt. Dies ist kein Bedienelement. Wenn eine Watchlist existiert, tritt an diese Stelle <button name="button">Ausgewählte Watchlist</button>, was ebenfalls kein Bedienelement ist. Erst wenn es mehr als eine Watchlist gibt, wird das Element zum Dropdown-Menü <label for="cars"></label>
  <select name="cars" id="cars">
     <option value="" selected disabled hidden>Ausgewählte Wachtlist</option>
     <option value="volvo">Weitere Watchlist</option>
     <option value="saab">Weitere Watchlist</option>
     <option value="mercedes">Weitere Watchlist</option>
  </select>, mit dem man die vorhandenen Watchlisten öffnen kann.
* <form>
     <input type="checkbox" id="not" name="ev"></input>
     <label for="not"> Öffentlich</label><br></br>
  </form>
  Ändere den Öffentlichkeitsstatus der Liste. Setze den Haken, um den Status der  Liste zu <i>öffentlich</i> zu ändern. Wird kein Haken gesetzt oder wird er wieder entfernt, ist die Liste <i>privat</i>. Öffentliche Listen können von anderen Nutzer*innen betrachtet werden. Dazu benötigen sie allderings den Link zur Liste (die Adresse, die in der Adressleiste des Browsers angezeigt wird, wenn die Liste geöffnet ist). Sobald der Haken bei einer zuvor öffentlichen Liste entfernt worden ist, können andere Nutzer*innen die Liste nicht mehr öffnen.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/plus-solid.png" height="12"/></button> Öffne das Dialogfeld „Erstellen“, um eine neue Liste anzulegen.
* <button name="button">Bearbeiten</button> Öffne das Dialgfeld „Bearbeiten“. Dort kann die derzeit geöffnete Liste umbenannt und ihr Beschreibungstext verändert werden.
* <button name="button">Lösche</button> Lösche die gesamte derzeit geöffnete Watchlist.

#### Dialogfeld „Erstellen“
Dieses Dialogfeld öffnet sich, nachdem auf <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/plus-solid.png" height="12"/></button> geklickt worden ist.

<table>
  <tr>
     <td><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/watchlist_erstellen.png" width="500" /></td>
     <td>
        <ul>
           <li>
              <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" height="15"/></button> Schließe das Dialogfenster, ohne eine neue Liste anzulegen.
           </li>
           <li>
              <form>
                 <p>
                    <label for="fname">Name</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld für den Titel der Liste. Dieses Feld muss ausgefüllt werden, damit eine neue Liste anlegt werden kann. Der Titel kann nachträglich bearbeitet werden.
           </li>
           <li>
              <form>
                 <p>
                    <label for="fname">Beschreibung</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld für die Beschreibung der Liste. Das Ausfüllen dieses Felds ist optional. Der Text kann nach dem Anlegen der Liste beliebig oft verändert werden.
           </li>
           <li>
              <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/more_text.PNG" height="15"/></button> Durch Anklicken dieses Buttons und vertikales Verschieben der Maus kann die Größe des Textfelds für die Listenbeschreibung angepasst werden.
           </li>
           <li>
              <button name="button">Erstellen</button> Lege eine Liste mit den in den Eingabefeldern eingetragenen Daten an und schließe das Dialogfenster.
           </li>
           <li>
              <button name="button">Schließen</button> Schließe das Dialogfenster, ohne eine neue Liste anzulegen.
           </li>
        </ul>
     </td>
  </tr>
</table>

#### Dialogfeld „Bearbeiten“
Dieses Dialogfeld öffnet sich, nachdem auf <button name="button">Bearbeiten</button> geklickt worden ist.

<table>
  <tr>
     <td><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/watchlist_bearbeiten.png" width="550" /></td>
     <td>
        <ul>
           <li>
              <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" height="15"/></button> Schließe das Dialogfenster, ohne eine neue Liste anzulegen.
           </li>
           <li>
              <form>
                 <p>
                    <label for="fname">Name</label><br></br>
                    <input type="text" id="fname" name="fname" value="Titel der Liste"></input><br></br>
                 </p>
              </form>
              Eingabefeld für den Titel der Liste. Nimm die gewünschten Änderungen am Listentitel vor.
           </li>
           <li>
              <form>
                 <p>
                    <label for="fname">Beschreibung</label><br></br>
                    <input type="text" id="fname" name="fname" value="Beschreibungstext"></input><br></br>
                 </p>
              </form>
              Eingabefeld für die Beschreibung der Liste. Nimm die gewünschten Änderungen am Beschreibungstext vor.
           </li>
           <li>
              <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/more_text.PNG" height="15"/></button> Durch Anklicken dieses Buttons und vertikales Verschieben der Maus kann die Größe des Textfelds für die Listenbeschreibung angepasst werden.
           </li>
           <li>
              <button name="button">Erstellen</button> Übernimm die vorgenommenen Änderungen und schließe das Dialogfeld. Dieses Elmenent wird erst zum Bedienelement, nachdem Änderungen vorgenommen worden sind.
           </li>
           <li>
              <button name="button">Schließen</button> Schließe das Dialogfeld. Dadurch werden keine vorgenommenen Änderungen übernommen.
           </li>
        </ul>
     </td>
  </tr>
</table>

### Seiteneinstellungen
* <button name="button">Beschreibung</button> Blende die Beschreibung der Liste ein bzw. aus. Dieser Button ist nur vorhanden, wenn die Liste mit einem Text versehen worden ist. Ein Beschreibungstext kann nachträglich hinzugefügt werden, dazu klickt man auf <button>Bearbeiten</button>.
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
  </select> Bestimme die Anzahl der pro Seite angezeigten Medien. Zur Auswahl stehen <i>3</i>, <i>4</i>, <i>8</i>, <i>12</i>, <i>24</i> und <i>48</i>.

### Mediacards

<table>
  <tr>
     <td><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/watchlist_mediacard.png" width="1000" /></td>
     <td>
        <ul>
           <li>
              <button name="button">Mediacard</button> Die Medienreihenfolge kann per Drag-and-Drop verändert werden.
           </li>
           <li>
              <a href="/mampf/de/docs/session" target="_self"><button name="button">Sitzung</button></a> Gehe auf die <a href="/mampf/de/docs/session" target="_self">Seite der Sitzung</a>. Dies kann nur bei Lektionen ein Bedienelement sein. Dazu muss eine Sitzung assoziiert sein. Bei allen anderen Medien steht an dieser Stelle der Veranstaltungstitel.
           </li>
           <li>
              <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/minus-solid.png" height="12"/></button> Entferne das Medium von der Watchlist.
           </li>
           <li>
              <a href="/mampf/de/docs/tag" target="_self"><button name="button">Begriff</button></a> Gehe auf die Seite des <a href="/mampf/de/docs/tag" target="_self">Begriffs</a>.
           </li>
           <li>
              <button name="button"><a href="/mampf/de/docs/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button> Spiele das Video mit <a href="/mampf/de/docs/thyme" target="_self">THymE</a> ab.
           </li>
           <li>
              <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF.
           </li>
           <li>
              <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="8"/></button> Öffne den externen Link.
           </li>
           <li>
              <button name="button"><a href="/mampf/de/docs/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button> Öffne die <a href="/mampf/de/docs/medium" target="_self">Medienseite der Lektion</a>.
           </li>
           <li>
              <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>mp4</button> Lade das Video herunter.
           </li>
           <li>
              <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/long-arrow-alt-down-solid.png" height="12"/>pdf</button> Lade das PDF herunter.
           </li>
        </ul>
     </td>
  </tr>
</table>

### Seitennavigation
* <button name="button">n</button> Wechsel auf Seite n.
* <button name="button">Nächste</button> bzw. <button name="button">Vorige Wechsel</button> auf die nächste bzw. vorige Seite.
* <button name="button">Letzte</button> bzw. <button name="button">Erste</button> Wechsel auf die letzte bzw. erste Seite.

## Hinweis zum Fehlen von Bedienelementen
Nicht immer sind alle der aufgeführten Bedienelemente vorhanden. Bei den Mediacards hängen die verfügbaren Elemente von den Bestandteilen des Mediums (Dateien und Assoziationen) ab. Aus welchen Komponenten ein Medium bestehen kann, ist wiederum durch die Medientyp festgelegt. Die Buttons sind nur vorhanden, wenn dies auch für die entsprechenden Dateien der Fall ist bzw. die entsprechenden Assoziationen (Begriffe und Sitzung) bestehen sind. Die Elemente zur Seitennavigation werden nur angezeigt, falls sich mehr Medien auf der Liste befinden, als pro Seite anzeigt werden sollen.

## Von dieser Seite aus aufrufbare Seiten
### [Seite der getaggten Begriffe](tag.md)
Auf dieser Seite werden Synonyme und Übersetzungen des Begriffs aufgelistet. Zudem sind verknüpfte Begriffe, Abschnitte und Medien angeben und verlinkt. Die Beziehungen zu anderen Begriffen wird mit einer Mindmap visualisiert. Diese Mindmap kann auch zur Navigation genutzt werden. Begriffsseiten öffnen sich durch Klick auf den jeweiligen <a href="/mampf/de/docs/tag" target="_self"><button name="button">Begriff</button></a>.

### [THymE-Player](thyme.md)
Im THymE-Player können Videos abgespielt werden. Der Player zeigt zudem eine Gliederung des Videos und weiterführende Informationen (z.B. Links zu Zusatzmaterial) an. Er öffnet sich durch Klicken auf den <button name="button"><a href="/mampf/de/docs/thyme" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></a></button>-Button.

### [Seite des verknüpften Mediums](medium.md)
Auf der Seite eines Mediums stehen weitere, vom Medientyp abhängige Informationen (z.B. zu Länge bzw. Umfang und Größe von PDFs bzw. Videos) zur Verfügung. Auf allen Medienseiten sind verknüpfte Medien und Begriffe aufgeführt und verlinkt. Zudem können Kommentare verfasst und gelesen werden. Um auf eine Medienseite zu gelangen, muss man auf den <button name="button"><a href="/mampf/de/docs/medium" target="_self"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/info-black.png" height="12"/></a></button>-Button klicken.

## Hinweise für Editor*innen: Zusätzliche Informationen auf Mediacards

Auf den [Mediacards](mediacard) können sich zusätzliche Informationen befinden. Das Symbol <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/file-import-solid.png" height="12"/> im Header weist darauf hin, dass das Medium aus einer anderen Veranstaltung importiert worden ist. Bei Editor\*innen befinden sich gegebenenfalls zusätzliche Icons auf den Mediacards, die Auskunft über die Sichtbarkeit eines Mediums geben.

| Symbol | Bedeutung |
| :---: | :--- |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/eye-slash-solid-red.png" height="12"/> | Das Medium ist noch nicht veröffentlicht. Einfache Nutzer*innen können es noch nicht sehen. |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/eye-slash-solid-blue.png" height="12"/> | Das Medium ist auf Modulebene angesiedelt und mit Tags versehen, die in der Veranstaltung noch nicht behandelt worden sind. Bevor diese Begriffe in der Veranstaltung verwendet worden sind, können einfache Nutzer\*innen dieses Medium nur sehen, wenn sie *alle* im Menü <button name="button">Zusatzmaterialien <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/arrow-drop-down.png" height="12"/></button> ausgewählt haben. Diese Wahl ist nicht die Standardeinstellung. |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/calendar-check-solid-red.png" height="12"/> | Das Medium ist noch nicht veröffentlicht, aber die Veröffentlichung ist geplant. Einfache Nutzer*innen können dieses Medium erst nach dem Zeitpunkt der Veröffentlichung sehen. Dieser kann mithilfe des Tooltips in Erfahrung gebracht werden. |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/lock-solid-red.png" height="12"/> | Das Medium ist gesperrt. Einfache Nutzer*innen können es nicht mehr sehen. |
