---
title: Modul bearbeiten
---

Auf der Seite „Modul bearbeiten“ können Einstellungen des Moduls bearbeitet und Inhalte hinzugefügt werden. Diese Seite ist nur Editor\*innen des betreffenden Moduls und Adminstrator\*innen zugänglich.

![](/img/modul_bearbeiten_thumb.png)

## Navigation zu dieser Seite
Die Seite „Modul bearbeiten“ ist über verschiedene Wege erreichbar. Drei davon werden nun aufgelistet.

<ul>
   <li>
      <a href="/mampf-pages/ed-overview" target="_self"><b>Übersichtsseite</b></a>
   </li>
   Über den <button>Modultitel</button> in der Box „Meine Module“ gelangt man auf die Seite „Modul bearbeiten“.
  <li>
     <a href="/mampf-pages/ed-edit-event-series" target="_self"><b>Bearbeitungsseite einer  Veranstaltung</b></a>
  </li>
  Am Seitenanfang auf der rechten Seite befindet sich der Button <button>zum Modul</button>, der einen auf die Seite „Modul bearbeiten“ führt.
  <li>
     <a href="/mampf-pages/ed-search-extended#tab-modulsuche" target="_self"><b>Modulsuche</b></a>
  </li>
  Nach Durchführung einer Modulsuche wird eine Ergebnistabelle angezeigt. Mit dem Button <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/edit-regular.png" width="12" height="12"/></button> in der Aktionspalte dieser Tabelle ist die Seite „Modul bearbeiten“ erreichbar.
</ul>

## Bereiche der Seite

Die Seite gliedert sich in zwei große Teilbereiche: die eigentliche Seite und die [Navigationsleiste](nav-bar). Die Bereiche sind exemplarisch in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/modul_bearbeiten_navbar.png" width="700"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/modul_bearbeiten_eigentlich.png" width="700"/>  |
|:---: | :---: |
|Navigationsleiste|Eigentliche Seite|

Die eigentliche Seite besteht aus dem Kopf und den Boxen „Basisdaten“,„Medien“, „Weitere Informationen“, „Bild“ und „Tags“. Diese Bereiche sind in den folgenden Screenshots hervorgehoben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/modul_bearbeiten_kopf.png" width="700"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/modul_bearbeiten_basisdaten.png" width="700"/>  |
|:---: | :---: |
|Kopf|Basisdaten|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/modul_bearbeiten_medien.png" width="700"/> | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/modul_bearbeiten_weitere_infos.png" width="700"/>  |
|Medien|Weitere Informationen|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/modul_bearbeiten_bild.png" width="700"/> | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/modul_bearbeiten_tags.png" width="700"/>  |
|Bild|Tags|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Im Folgenden werden sämtliche mögliche Bedienelemente der Seite „Modul  bearbeiten“ aufgeführt. Dabei werden zuerst die Bedienelemente im Kopf und dann die der Boxen „Basisdaten“,„Medien“, „Weitere Informationen“, „Bild“ und „Tags“ beschrieben.

### Kopf
In diesem Bereich sind erst Bedienelemente verfügbar, nachdem eine Änderung vorgenommen worden ist. Bei diesen handelt es sich um die folgenden beiden Buttons:

* <button>Speichern</button> Übernimm die vorgenommenen Änderungen.
* <button>Verwerfen</button> Verwirf die vorgenommenenn Änderungen.

### Box „Basisdaten“
![](/img/modul_bearbeiten_basisdaten_cut.png)

* <form>
   <p>
      <label for="fname">Titel</label><br></br>
      <input type="text" id="fname" name="fname"></input><br></br>
   </p>
</form>
  Eingabefeld für den Titel des Moduls.
* <form>
   <p>
      <label for="fname">Kurztitel</label><br></br>
      <input type="text" id="fname" name="fname"></input><br></br>
   </p>
</form>
  Eingabefeld für die Abkürzung des Modultitels. Diese wird beispielsweise im Schnellzugriff und bei Assoziationen verwendet.
* <form>
   Sprache<br></br>
   <input type="radio" id="de" name="lang" checked></input>
   <label for="de"> Deutsch</label>&nbsp;
   <input type="radio" id="eng" name="lang"></input>
   <label for="eng"> Englisch</label>
</form> Radiobuttons zur Sprachauswahl, wobei die Optionen <i>Deutsch</i> und <i>Englisch</i> verfügbar sind.
* <form>
   <p>
      <label for="fname">Module, auf denen das vorliegende Modul aufbaut</label><br></br>
      <input type="text" id="fname" name="fname"></input><br></br>
   </p>
</form>
  Eingabefeld und Dropdownmenü. Tippe in das Feld oder wähle aus dem ausklappten Menü die Module aus, auf denen das bearbeitete Modul aufbaut. Je nach vorgenommener Einstellung im Profil wirkt sich die hier getroffene Auswahl auf die Inhalte aus, die Nutzer*innen angezeigt werden: In den <a href="mampf-pages/profile#einstellungen" target="_self">Profileinstellungen</a> muss in der Box „Einstellungen“ eine Entscheidung zu angezeigten verknüpften Inhalten getroffen werden. Eine dort verfügbare Option ist „auch aus allen Modulen, die sich inhaltlich vor den von mir abonnierten Modulen einsortieren“.
* Modul <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button> Entferne das Modul aus dem Feld.
* <form>
   <p>
      <label for="fname">EditorInnen</label><br></br>
      <input type="text" id="fname" name="fname"></input><br></br>
   </p>
</form>
  Eingabefeld und Dropdownmenü. Gib mindestens zwei Zeichen ein. Anschließend können Personen aus der daraufhin ausklappenden Liste ausgewählt werden.
* EditorIn <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button> Entferne die Person aus dem Feld.
* Veranstaltungen <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/add-circle.png" width="12" height="12"/></button> Öffne das Formular „Veranstaltung anlegen“, um im Modul eine Veranstaltung anzulegen.
* <a href="mampf-pages/ed-edit-event-series" target="_self"><button>Veranstaltung</button></a> Wechsel auf die Seite <a href="mampf-pages/ed-edit-event-series" target="_self">„Veranstaltung bearbeiten“</a> zu wechseln. Dieses Bedienelement ist nur vorhanden, wenn es eine Veranstaltung im Modul gibt.
* <form>
    <input type="checkbox" id="news" name="mis"></input>
    <label for="news"> semesterunabhängig </label>
 </form>
 Checkbox, die nur vorhanden ist und bearbeitet werden kann, wenn es keine Veranstaltungen im Modul gibt. Setze den Haken, um die Veranstaltung semesterunabhängig zu machen. In semesterunabhängigen Modulen kann höchstens eine Veranstaltung angelegt werden.
* <form>
   <p>
      <label for="fname">Teilbereiche</label><br></br>
      <input type="text" id="fname" name="fname"></input><br></br>
   </p>
</form>
  Eingabefeld und Dropdownmenü. Tippe in das Feld oder wähle aus dem ausklappten Menü die Teilbereiche aus, zu denen das Modul gehören soll. Diese Einstellung kann in der <a href="mampf-pages/my-home-page#veranstaltungssuche" target="_self">Veranstaltungssuche</a> berücksichtigt werden. Darüber hinaus bestimmt sie die Einordnung des Moduls in der Box „Module“ in den <a href="mampf-pages/profile#module" target="_self">Profileinstellungen</a>.
* Teilbereich <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button> Entferne den Teilbereich aus dem Feld.

#### Formular „Veranstaltung anlegen“
Das Formular „Veranstaltung anlegen“ öffnet sich, nachdem auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/add-circle.png" width="12" height="12"/></button> geklickt worden ist. Folgende Bedienelemente sind dort zu finden:

![](/img/modal_veranstaltung_anlegen.png)

* <label for="cars"></label>Semester <br></br>
<select name="cars" id="cars">
   <option value="saab" selected>Semester 1</option>
   <option value="mercedes">Semester 2</option>
   <option value="audi">Semester 3</option>
</select><br></br> Dropdownmenü zur Einstellung des Semesters.
* <form>
   <p>
      <label for="fname">DozentIn</label><br></br>
      <input type="text" id="fname" name="fname"></input><br></br>
   </p>
</form> Eingabefeld und Dropdownmenü. Gib mindestens zwei Zeichen ein. Anschließend kann eine Person aus der daraufhin ausklappenden Liste ausgewählt werden. Diese ersetzt die zuvor eingetragene Person.
* DozentIn <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button> Entferne die Person aus dem Feld. Dort ist zunächst der eigene Name eingetragen.
* <label for="cars"></label>Typ <br></br>
 <select name="cars" id="cars">
    <option value="saab" selected>Vorlesung</option>
    <option value="mercedes">Seminar</option>
    <option value="audi">Proseminar</option>
    <option value="volvo1">Oberseminar</option>
 </select><br></br> Dropdownmenü zur Einstellung des Veranstaltungstyps. Zur Auswahl stehen <i>Vorlesung</i>, <i>Seminar</i>, <i>Proseminar</i> und <i>Oberseminar</i>.
* <button>Speichern</button> Lege eine Veranstaltung mit den ausgewählten Einstellungen an.
* <button>Abbrechen</button> Schließe das Formular, ohne eine Veranstaltung anzulegen.


### Box „Medien“
![](/img/modul_bearbeiten_medien_cut.png)

* <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/add-circle.png" width="12" height="12"/></button> Öffne das Formular „Medium anlegen“.
* Tab <button>Typ</button> Wähle einen anderen Typ, um Medien dieses Typs angezeigt zu bekommen.
* Tab <button>Modul</button> bzw. <button>Veranstaltung</button> Wähle das Modul oder eine Veranstaltung aus dem Modul, um Medien angezeigt zu bekommen, die auf der ausgewählten Ebene angesiedelt sind.  
* <a href="mampf-pages/edit-medium" target="_self"><button>Medium</button></a> Wechsel auf die Seite <a href="mampf-pages/edit-medium" target="_self">„Medium bearbeiten“</a>.

#### Formular „Medium anlegen“
Das Formular „Medium anlegen“ öffnet sich, nachdem in der Box „Medien“ auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/add-circle.png" width="12" height="12"/></button> geklickt worden ist.

![](/img/modul_create_medium.png)

* Typ <br></br><label for="cars"></label>
   <select name="cars" id="cars">
      <option value="" selected disabled hidden>Lektion</option>
      <option value="volvo1">Lektion</option>
      <option value="volvo2">Worked Example</option>
      <option value="volvo3">Übung</option>
      <option value="volvo4">Skript</option>
      <option value="volvo5">Wiederholung</option>
      <option value="volvo6">Quiz</option>
      <option value="volvo7">Quiz-Frage</option>
      <option value="volvo8">Quiz-Erläuterung</option>
      <option value="volvo9">Beispiel-Datenbank</option>
      <option value="volvo10">Sonstiges</option>
   </select><br></br>
   Dropdown-Menü zur Auswahl des Medientyps. Dabei sind die Typen <i>Lektion</i>, <i>Worked Example</i>, <i>Übung</i>, <i>Skript</i>, <i>Wiederholung</i>, <i>Quiz</i>, <i>Quiz-Frage</i>, <i>Quiz-Erläuterung</i>, <i>Beispiel-Datenbank</i> und <i>Sonstiges</i> verfügbar. Bei den Typen <i>Quiz</i>, <i>Quiz-Frage</i>, <i>Quiz-Erläuterung</i> und <i>Skript</i> ist eine nachträgliche Änderung des Medientyps nicht möglich. Die anderen Typen sind im Nachhinein veränderbar, allerdings erlaubt MaMpf nur eine Änderung zu einem der folgenden Medientypen <i>Lektion</i>, <i>Worked Example</i>, <i>Übung</i>, <i>Wiederholung</i>, <i>Beispiel-Datenbank</i> und <i>Sonstiges</i>. Siehe auch <a href="/mampf/de/mampf-pages/medium" target="_self">Medium</a>.
* <form>
     <p>
         <label for="fname">Titel</label><br></br>
         <input type="text" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Eingabefeld für den Titel des Medium. Dies ist ein Pflichtfeld.
* <a href="/mampf/de/mampf-pages/edit-medium" target="_self"><button>Speichern und bearbeiten</button></a> Lege das Medium an, schließe das Dialogfenster und wechsel auf die Seite <a href="/mampf/de/mampf-pages/edit-medium" target="_self">„Medium bearbeiten“</a>.
* <button>Abbrechen</button> Schließe das Dialogfenster, ohne ein Medium anzulegen.

### Box „Weitere Informationen“
![](/img/modul_bearbeiten_weitere_infos_cut.png)

<ul>
   <li>
      <button>Ein-/Ausklappen</button> Klappe den Inhalt der Box ein bzw. aus.
   </li>
   <li>
      <form>
         <input type="checkbox" id="ass" name="ass" checked></input>
         <label for="ass"> Weitere Informationen </label>
     </form>
   </li>
   <li>
      <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-bold.png" width="12" height="12"/></button> Beginne bzw. beende Fettdruck an der Stelle, an der sich der Cursor befindet, oder mache den markierten Text fett bzw. stelle den Fettdruck ab.
   </li>
   <li>
      <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-italic.png" width="12" height="12"/></button> Beginne bzw. beende Kursivdruck an der Stelle, an der sich der Cursor befindet, oder mache den markierten Text kurisv bzw. stelle den Kursivdruck ab.
    </li>
    <li>
      <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/strikethrough.png" width="12" height="12"/></button> Beginne bzw. beende das Durchstreichen des Texts an der Stelle, an der sich der Cursor befindet, oder streiche den markierten Text durch bzw. stelle das Durchstreichen ab.
    </li>
    <li>
      <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link-solid.png" width="12" height="12"/></button> Füge einen Hyperlink ein oder mache aus dem markierten Text einen Hyperlink bzw. mache aus dem Hyperlink einfachen Text.
    </li>
    <li>
      <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-size.png" width="12" height="12"/></button> Vergrößere Text in Standardgröße bzw. verkleinere großen Text.
     </li>
     <li>
        <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-quote.png" width="16" height="8"/></button> Beginne bzw. beende ein Zitat an der Stelle, an der sich der Cursor befindet, oder mache aus dem markierten Text ein Zitat bzw. aus dem markierten Zitat einfachen Text.
     </li>
     <li>
        <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-list-bulleted.png" width="12" height="12"/></button> Falls es an dieser Stelle noch keine Liste gibt, beginne an der Stelle, an der sich der Cursor befindet, eine unnummierte Liste bzw. mache aus dem markierten Text eine unnummierte Liste. Falls es bereits eine Liste gibt, verschiebe den markierten Eintrag bzw. den Eintrag, an dem sich der Cursor befindet, auf die nächsthöhere Ebene. Falls es keine nächsthöhere Ebene gibt, mache aus der Liste Fließtext.
      </li>
      <li>
        <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-list-numbered.png" width="12" height="12"/></button> Falls es an dieser Stelle noch keine Liste gibt, beginne an der Stelle, an der sich der Cursor befindet, eine nummierte Liste bzw. mache aus dem markierten Text eine nummierte Liste. Falls es bereits eine Liste gibt, verschiebe den markierten Eintrag bzw. den Eintrag, an dem sich der Cursor befindet, auf die nächsthöhere Ebene. Falls es keine nächsthöhere Ebene gibt, mache aus der Liste Fließtext.
      </li>
      <li>
        <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-indent-decrease.png" width="12" height="12"/></button> Setze den Listeintrag auf die nächsthöhere Ebene. Dieses Bedienelmente ist nur bei Listen vorhanden.
      </li>
      <li>
        <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-indent-increase.png" width="12" height="12"/></button> Setze den Listeneintrag auf die nächsttiefere Ebene. Dieses Bedienelmente ist nur bei Listen vorhanden, wenn es einen Eintrag aus derselben Ebene gibt.
      </li>
      <li>
        <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/undo.png" width="16" height="8"/></button> Mache die letzte Aktion rückgängig. Dazu muss zuvor etwas am Text verändert worden sein.
      </li>
     <li>
        <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/redo.png" width="16" height="8"/></button> Wiederhole die letzte Aktion. Dazu muss die letzte Aktion zuvor rückgängig gemacht worden sein.
      </li>
      <li>
        <form>
           <p>
              <label for="fname"></label>
              <input type="text" id="fname" name="fname"></input><br></br>
           </p>
        </form>Eingabefeld für den Text.
      </li>
</ul>

### Box „Bild“
![](/img/modul_bearbeiten_bild_cut.png)

* <button>Ein-/Ausklappen</button> Klappe den Inhalt der Box ein bzw. aus.
* <button>Datei</button>
* <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button>

### Box „Tags“
![](/img/modul_bearbeiten_tags_cut.png)

* <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/add-circle.png" width="12" height="12"/></button> Öffne das Formular „Tag anlegen“.
* <form>
   <p>
      <input type="text" id="fname" name="fname"></input><br></br>
   </p>
</form>
  Eingabefeld. Gib mindestens zwei Zeichen ein und wähle aus dem Dropdownmenü, das daraufhin ausklappt, die Tags aus, die zum Modul assoziiert werden sollen.
* <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button> Tag. Entferne den Tag aus der Box und löse damit die Assoziation zwischen dem Tag und dem Modul auf.


##### Formular „Tag anlegen“
Das folgende Formular öffnet sich, nachdem auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-plus-solid.png" width="15" height="15"/></button> bei in der Box „Tags“ geklickt worden ist.

<table>
  <tr>
     <td valign="top">
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/create-tag.png" width="1500" /><br></br><br></br>
        <ul>
           <li>
              <form>
                 <p>
                    <label for="fname">Titel <br></br>de&nbsp;</label>
                 <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld für den deutschen Titel des Tags. Mindestens dieses Feld oder das Feld für den englischen Titel muss ausgefüllt werden, damit ein neuer Tag anlegt werden kann. Der Titel kann nachträglich auf der Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a> bearbeitet werden.
           </li>
           <li>
              <form>
                 <p>
                    <label for="fname">Titel <br></br>en&nbsp;</label>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld für den englischen Titel des Tags. Mindestens dieses Feld oder das Feld für den deutschen Titel muss ausgefüllt werden, damit ein neuer Tag anlegt werden kann. Der Titel kann nachträglich auf der Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a> bearbeitet werden.
           </li>
        </ul>
     </td>
     <td valign="top">
        <ul>
           <li>Aliase
           </li>
              <label for="cars"></label>
              <select name="cars" id="cars">
                 <option value="" selected disabled hidden>de</option>
                 <option value="volvo">de</option>
                 <option value="volvo2">en</option>
              </select><br></br>
              Dropdown-Menü zur Sprachauswahl für eine weitere Bezeichnung des Tags. Zur Auswahl stehen Deutsch und Englisch.
           <li>
              <form>
                 <p>
                    <label for="fname">Aliase<br></br></label>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld für eine weitere Bezeichnung des Tags. Die Bezeichnung kann nachträglich auf der Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a> bearbeitet werden.
           </li>
           <li>
              <form>
                 <p>
                    <label for="fname">Verknüpfte Tags</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld und Dropdown-Menü. Tippe in das Eingabefeld oder scrolle durch die Liste verfügbarer Tags und wähle die aus, die mit der Tag verknüpft werden sollen.
           </li>
           <li>
              <button name="button">Speichern</button> Lege einen Tag mit den in den Eingabefeldern eingetragenen Daten an und schließe das Dialogfenster.
           </li>
           <li>
              <button name="button">Abbrechen</button> Schließe das Dialogfenster, ohne einen neuen Tag anzulegen.
           </li>
        </ul>
     </td>
  </tr>
</table>

## Von dieser Seite aus aufrufbare Seiten

* [Veranstaltung bearbeiten](ed-edit-event-series)
* [Medium bearbeiten](edit-medium)

## Verwandte Seiten
