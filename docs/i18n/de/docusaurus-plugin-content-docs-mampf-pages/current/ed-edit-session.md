---
title: Sitzung bearbeiten
---

Auf der Seite „Sitzung bearbeiten“ können Editor\*innen Änderungen an einer [Sitzung](session) einer Vorlesung vornehmen. Sie können Medien erstellen, Tags anlegen, hinzufügen und entfernen, Abschnitte assoziieren, sowie das Datum und den Beschreibungstext der Sitzung bearbeiten. Das Pendant zu dieser Seite bei Veranstaltungen des Typs Seminar ist die Seite [„Vortrag bearbeiten“](edit-talk).

![](/img/sitzung_bearbeiten.png)

## Navigation zu dieser Seite
Auf die Seite „Sitzung bearbeiten“ gelangt man über die [Seite der Sitzung](session), die Seite [„Vorlesung bearbeiten“](ed-edit-lecture) oder die Seite [„Abschnitt bearbeiten“](ed-edit-session).

<ul>
  <li>
     <a href="/mampf/de/mampf-pages/session" target="_self"><b>Seite der Sitzung</b></a>
  </li>
  Oben links neben dem Titel der Sitzung befindet sich das Symbol <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/edit-regular.png" width="12" height="12"/></button>, das einen auf die Seite „Sitzung bearbeiten“ führt.
  <li>
     <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self"><b>„Vorlesung bearbeiten“</b></a>
  </li>
  Im Vorlesungsinhalt erreicht man über den <button>Sitzungstermin</button> die Seite „Sitzung bearbeiten“. Bei verwaisten Sitzungen, also solchen bei denen alle assoziierten Abschnitte gelöscht worden sind, befindet sich der  <button>Sitzungstermin</button> unter der Gliederung.
  <li>
     <a href="/mampf/de/mampf-pages/ed-edit-section" target="_self"><b>„Abschnitt bearbeiten“</b></a>
  </li>
     Auf der Bearbeitungsseite eines zur Sitzung assoziierten Abschnitts befindet sich in der Box „Basisdaten“ bei „Sitzungen“ das Bedienelement <button>Sitzungsnummer, Sitzungstermin</button>, über das man die Seite „Sitzung bearbeiten“ erreicht.
</ul>

## Bereiche der Seite
Die Seite gliedert sich in zwei große Teilbereiche: die eigentliche Seite und die [Navigationsleiste](nav-bar). Die Bereiche sind exemplarisch in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/sitzung_bearbeiten_navbar.png" height="350"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/sitzung_bearbeiten_eigentlich.png" height="350"/>  |
|:---: | :---: |
|Navigationsleiste|Eigentliche Seite|

Die eigentliche Seite besteht aus dem Kopf und den Boxen „Basisdaten“ und „Inhalt“. Diese Bereiche sind in den folgenden Screenshots hervorgehoben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/sitzung_bearbeiten_kopf.png" height="350"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/sitzung_bearbeiten_basisdaten.png" height="350"/>  |
|:---: | :---: |
|Kopf|Basisdaten|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/sitzung_bearbeiten_inhalt.png" height="350"/> |  |
|Inhalt||

## Bedienelemente und mögliche Aktionen auf dieser Seite
Nun werden die Bedienelemente der Seite „Abschnitt bearbeiten“ beschrieben. Dabei werden die einzelnen Bereiche nacheinander behandelt.

![](/img/sitzung_bearbeiten.png)

### Kopf
In diesem Bereich gibt es Bedienelemente zur Navigation und der Übernahme von Änderungen.

* <a href="/mampf/de/mampf-pages/session" target="_self"><button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/eye-solid.png" width="12" height="12"/></button></a> Wechsel auf die <a href="/mampf/de/mampf-pages/session" target="_self">Seite der Sitzung</a>.
* <button>Speichern</button> Übernimm die vorgenommenen Änderungen. Dieser Button erscheint erst, nachdem die Sitzung bearbeitet worden ist. Wenn dieser Button nicht angeklickt wird, gehen alle Änderungen verloren.
* <button>Verwerfen</button> Verwirf die vorgenommenen Änderungen. Dieser Button erscheint erst, nachdem die Sitzung bearbeitet worden ist.
* <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self"><button>zur Veranstaltung</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self">„Vorlesung bearbeiten“</a>.
* <button>Löschen</button> Lösche die Sitzung. Zur Sitzung assoziierte Medien werden dabei nicht gelöscht, sondern mit der Vorlesung assoziiert.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/keyboard-arrow-left.png" width="12" height="12"/></button> Wechsel zur Bearbeitungsseite der vorigen Sitzung. (Auf der Bearbeitungsseite der ersten Sitzung ist dieser Button nicht vorhanden.)
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/keyboard-arrow-right.png" width="12" height="12"/></button> Wechsel zur Bearbeitungsseite der nächsten Sitzung. (Auf der Bearbeitungsseite der letzten Sitzung ist dieser Button nicht vorhanden.)

### Basisdaten
In der Box „Basisdaten“ kommen die Bedienelemente Eingabefeld, Dropdownmenü und Button vor.

<table>
  <tr>
     <td valign="top">
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/sitzung_bearbeiten_basisdaten_cut.png" width="3000" />
        <ul>
           <li>
              Sitzungsdatum <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-xmark-solid.png" width="15" height="15"/></button>
           </li>
              Lösche das Sitzungsdatum. Dabei ist zu beachten, dass ein Sitzungsdatum angegeben werden muss.
           <li>
              <form>
                   <p>
                      <label for="fname">Datum</label><br></br>
                      <input type="text" id="fname" name="fname" value="TT.MM.JJJJ"></input><br></br>
                   </p>
                </form>
                Eingabefeld zur Festlegung des Sitzungstermins. Dieses Feld ist erst vorhanden, nachdem das Sitzungsdatum gelöscht worden ist. Sobald man in dieses Feld klickt, öffnet sich ein Datepicker. Das Feld kann manuell oder mithilfe des Datepickers ausgefüllt werden. Dieses Feld muss ausgefüllt werden.
           </li>
        </ul>
     </td>
     <td valign="top">
        <ul>
          <li>
              Medien <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-plus-solid.png" width="15" height="15"/></button> Öffne das Formular zum Anlegen eines neuen Mediums.
          </li>
          <li>
             <a href="/mampf/de/mampf-pages/edit-medium" target="_self"><button>Medientitel</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/edit-medium" target="_self">„Medium bearbeiten“</a>.
          </li>
          <li>
              <form>
                <p>
                  <label for="fname">Abschnitte</label><br></br>
                  <input type="text" id="fname" name="fname"></input><br></br>
                </p>
              </form>
              Eingabefeld und Dropdown-Menü. Tippe in das Eingabefeld oder scrolle durch die Liste verfügbarer Abschnitte und wähle die aus, die mit der Sitzung verknüpft werden sollen.
          </li>
          <li>
              Verknüpfter Abschnitt <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button>
          </li>
              Löse die Verknüpfung von Abschnitt und Sitzung auf. Dabei ist zu beachten, dass mindestens ein Abschnitt zur Sitzung assoziiert sein muss.
          <li>
              Verknüpfte Tags <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-plus-solid.png" width="15" height="15"/></button> Öffne das Formular zum Anlegen eines neuen Tags.
          </li>
          <li>
              <form>
                <p>
                  <label for="fname">Verknüpfte Tags</label><br></br>
                  <input type="text" id="fname" name="fname"></input><br></br>
                </p>
              </form>
              Eingabefeld und Dropdown-Menü. Tippe in das Eingabefeld oder scrolle durch die Liste verfügbarer Tags und wähle die aus, die mit der Sitzung verknüpft werden sollen.
          </li>
          <li>
              Verknüpfter Tag <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button>
          </li>
              Löse die Verknüpfung von Tag und Sitzung auf.
        </ul>
     </td>
  </tr>
</table>

#### Dialogfeld „Medium anlegen“
Das folgende Dialogfenster öffnet sich, nachdem auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-plus-solid.png" width="15" height="15"/></button> bei <i>Medien</i> geklickt worden ist.

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/sitzung_bearbeiten_medium_anlegen.png" width="3850"/>
     </td>
     <td>
        <ul>
           <li>
              Typ<br></br><label for="cars"></label>
                 <select name="cars" id="cars">
                    <option value="" selected disabled hidden>Lektion</option>
                    <option value="volvo2">Lektion</option>
                    <option value="volvo">Worked Example</option>
                    <option value="saab">Übung</option>
                    <option value="saab3">Skript</option>
                    <option value="mercedes">Wiederholung</option>
                    <option value="saab2">Quiz</option>
                    <option value="saab4">Quiz-Frage</option>
                    <option value="saab5">Quiz-Erläuterung</option>
                    <option value="saab6">Beispiel-Datenbank</option>
                    <option value="mercedes2">Sonstiges</option>
                 </select><br></br>
             Dropdown-Menü zur Auswahl des Medientyps. Sofern der gewählte Medientyp nicht <i>Quiz</i>, <i>Quiz-Frage</i>, <i>Quiz-Erläuterung</i> oder <i>Skript</i> ist, kann er nachträglich auf der Seite <a href="/mampf/de/mampf-pages/edit-medium" target="_self">„Medium bearbeiten“</a> verändert werden.
          </li>
          <li>
             <form>
                <p>
                   <label for="fname">Titel</label><br></br>
                   <input type="text" id="fname" name="fname"></input><br></br>
                </p>
             </form>
             Eingabefeld für den Medientitel. Dieses Feld muss ausgefüllt werden, damit ein neues Medium anlegt werden kann. Der Titel kann nachträglich auf der Seite <a href="/mampf/de/mampf-pages/edit-medium" target="_self">„Medium bearbeiten“</a> bzw. <a href="/mampf/de/mampf-pages/edit-quiz" target="_self">„Quiz bearbeiten“</a> bzw. <a href="/mampf/de/mampf-pages/edit-medium-question" target="_self">„Frage bearbeiten“</a> bzw. <a href="/mampf/de/mampf-pages/edit-medium-remark" target="_self">„Erläuterung bearbeiten“</a> bzw. <a href="/mampf/de/mampf-pages/ed-edit-manuscript" target="_self">„Skript bearbeiten“</a> geändert werden.
          </li>
          <li>
             <a href="/mampf/de/mampf-pages/edit-medium" target="_self"><button>Speichern und bearbeiten</button></a> Lege das Medium und wechsel auf die Seite <a href="/mampf/de/mampf-pages/edit-medium" target="_self">„Medium bearbeiten“</a> bzw. <a href="/mampf/de/mampf-pages/edit-quiz" target="_self">„Quiz bearbeiten“</a> bzw. <a href="/mampf/de/mampf-pages/edit-medium-question" target="_self">„Frage bearbeiten“</a> bzw. <a href="/mampf/de/mampf-pages/edit-medium-remark" target="_self">„Erläuterung bearbeiten“</a> bzw. <a href="/mampf/de/mampf-pages/ed-edit-manuscript" target="_self">„Skript bearbeiten“</a>.
          </li>
          <li>
             <button>Abbrechen</button> Brich die Aktion ab, lege kein neues Medium an und schließe das Dialogfenster.
          </li>
        </ul>
     </td>
  </tr>
</table>

#### Dialogfeld „Tag anlegen“
Das folgende Dialogfenster öffnet sich, nachdem auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-plus-solid.png" width="15" height="15"/></button> bei <i>Verknüpfte Tags</i> geklickt worden ist.

<table>
  <tr>
     <td valign="top">
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/abschnitt_bearbeiten_tag_anlegen.png" width="4000" />
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
           <li>
              Aliase</li><label for="cars"></label>
                 <select name="cars" id="cars">
                    <option value="" selected disabled hidden>de</option>
                    <option value="volvo">de</option>
                    <option value="volvo2">en</option>
                 </select><br></br>Dropdown-Menü zur Sprachauswahl für eine weitere Bezeichnung des Tags. Zur Auswahl stehen Deutsch und Englisch.
        </ul>
     </td>
     <td valign="top">
        <ul>
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
              Eingabefeld und Dropdown-Menü. Tippe in das Eingabefeld oder scrolle durch die Liste verfügbarer Tags und wähle die aus, die mit dem Tag verknüpft werden sollen.
           </li>
           <li>
           Verknüpfter Tag <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button>
           </li>
           Löse die Verknüpfung der Tags auf.
           <li>
              <form>
                 <p>
                    <label for="fname">Module</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld und Dropdown-Menü. Tippe in das Eingabefeld oder scrolle durch die Liste verfügbarer Module und wähle die aus, die mit dem Tag verknüpft werden sollen.
           </li>
           <li>
           Module <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button>
           </li>
           Löse die Verknüpfung von Tag und Modul auf.
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

### Inhalt
In der Box „Inhalt“ gibt es Bedienelemente zur Texteingabe und -formatierung. Außerdem können Bedienelemente zum Betrachten von verknüpften Videos und PDFs sowie zum Import von Gliederungsdaten aus dem Skript vorhanden sein.

Damit Bedienelemente zum Betrachten von verknüpften Videos und PDFs verfügbar sind, muss eine der zwei folgenden Bedingungen erfüllt sein:
1. Eine Lektion ist zur verknüpften Sitzung assoziiert und das zur Lektion gehörige Video wurde mit dem [THymE-Editor](thyme-editor) gegliedert.
2. Das Vorlesungsskript wurde mit dem MaMpf-LaTeX-Paket erstellt und seine Gliederung ist in MaMpf importiert. Falls das MaMpf-Paket verwendet wird, hat die Videogliederung der assoziierten Lektionen keinen Einfluss auf den extrahierten Inhalt.

Damit es die Bedienelemente zum Gliederungsimport gibt, muss die Veranstaltung skriptbasiert sein. Außerdem muss die Sitzung zu mindestens einem Abschnitt assoziiert sein, darf also nicht verwaist sein.

Die folgenden Bedienelemente können vorhanden sein:

<table>
  <tr>
    <td>
      <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/sitzung_bearbeiten_inhalt_thyme.png" width="3000"/>
      Gliederungsimport
      <ul>
        <li>
          <label for="cars"></label>Anfangs-Item <br></br>
          <select name="cars" id="cars">
             <option value="saab">Marker 1</option>
             <option value="mercedes">Marker 2</option>
             <option value="audi">Marker 3</option>
          </select><br></br> Dropdownmenü und Eingabefeld zur Festlegung des Anfangspunktes, ab dem Informationen zum Inhalt aus den Metadaten des Skripts importiert werden (nur bei skriptbasierten Vorlesungen).
        </li>
        <li>
          <label for="cars"></label>End-Item <br></br>
          <select name="cars" id="cars">
             <option value="saab">Marker 1</option>
             <option value="mercedes">Marker 2</option>
             <option value="audi">Marker 3</option>
          </select><br></br> Dropdownmenü und Eingabefeld zur Festlegung des Endpunktes, bis zu dem Informationen zum Inhalt aus den Metadaten des Skripts importiert werden (nur bei skriptbasierten Vorlesungen).
        </li>
      </ul>
      Texteingabe und -formatierung
      <ul>
        <li>
          <form>
                  <p>
                     <label for="fname">Details</label><br></br>
                     <input type="text" id="fname" name="fname"></input><br></br>
                  </p>
               </form>
               Eingabefeld für den Beschreibungstext.
        </li>
        <li>
          <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-bold.png" width="12" height="12"/></button> Beginne bzw. beende Fettdruck an der Stelle, an der sich der Cursor befindet, oder mache den markierten Text fett bzw. stelle den Fettdruck ab.
        </li>
        <li>
          <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-italic.png" width="12" height="12"/></button> Beginne bzw. beende Kursivdruck an der Stelle, an der sich der Cursor befindet, oder mache den markierten Text kurisv bzw. stelle den Kursivdruck ab.
        </li>
      </ul>
    </td>
    <td>
      <ul>
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
          <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-quote.png" height="8"/></button> Beginne bzw. beende ein Zitat an der Stelle, an der sich der Cursor befindet, oder mache aus dem markierten Text ein Zitat bzw. aus dem markierten Zitat einfachen Text.
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
          <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/undo.png" height="8"/></button> Mache die letzte Aktion rückgängig. Dazu muss zuvor etwas am Text verändert worden sein.
        </li>
        <li>
          <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/redo.png" height="8"/></button> Wiederhole die letzte Aktion. Dazu muss die letzte Aktion zuvor rückgängig gemacht worden sein.
        </li>
      </ul>
      Extrahierter Inhalt
        <ul>
          <li>
            <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/menu-book.png" width="12" height="12"/></button> Öffne das Skript an der entsprechenden Stelle in einem neuen Tab. Dieses Bedienelement kann nur in skriptbasierten Vorlesungen vorkommen.
          </li>
          <li>
            <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/video-library.png" width="12" height="12"/></button> Öffne das Video an der entsprechenden Stelle in <a href="/mampf/de/mampf-pages/thyme" target="_self">THymE</a>.
          </li>
          <li>
            <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" width="12" height="12"/></button> Öffne das PDF in einem neuen Tab.
          </li>
        </ul>
    </td>
  </tr>
</table>

Alle vorgenommenen Änderungen müssen gespeichert werden, sonst werden sie nicht übernommen.

## Verwaiste Sitzungen
Eine Sitzung erhält den Status „verwaist“, wenn sie nur zu gelöschten Abschnitten assoziiert ist. Sie erscheint dann nicht mehr in der Veranstaltungsgliederung auf der [Vorlesungsseite](lecture). Sobald ihr ein neuer Abschnitt zugewiesen wird, ist sie nicht mehr verwaist. Dies ist auf der Seite Bearbeitungsseite der verwaisten Sitzung möglich. Diese erreicht man über die [Bearbeitungsseite der Vorlesung](ed-edit-lecture). Das <button>Sitzungsdatum</button> von verwaisten Sitzungen, das auf die Bearbeitungsseite der verwaisten Sitzung führt, befindet sich unter der Gliederung.

## Von dieser Seite aus erreichbare Seiten
* [Medium bearbeiten](edit-medium)
* [Vorlesung bearbeiten](ed-edit-lecture)
* [Sitzung](session)
* [THymE](thyme)

## Verwandte Seiten
* [Kapitel bearbeiten](ed-edit-chapter)
* [Abschnitt bearbeiten](ed-edit-section)
* [Vortrag bearbeiten](edit-talk)
* [Veranstaltung bearbeiten](ed-edit-event-series)
* [Vorlesung bearbeiten](ed-edit-lecture)
* [Seminar bearbeiten](ed-edit-seminar)
* [Tag bearbeiten](ed-edit-tag)
* [Medium bearbeiten](edit-medium)
* [THymE-Editor](thyme-editor)
