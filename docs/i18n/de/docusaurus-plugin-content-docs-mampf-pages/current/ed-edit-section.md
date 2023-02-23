---
title: Abschnitt bearbeiten
---

Auf der Seite „Abschnitt bearbeiten“ können Editor\*innen Änderungen am [Abschnitt](section) einer Vorlesung vornehmen. Sie können Sitzungen erstellen, Tags anlegen, hinzufügen und entfernen, den Abschnitt von der Gliederung ausnehmen sowie den Titel, die Position und den Beschreibungstext des Abschnitts bearbeiten.

![](/img/abschnitt_bearbeiten_schmal.png)

## Navigation zu dieser Seite
Auf die Seite „Abschnitt bearbeiten“ gelangt man über die [Seite des Abschnitts](section) oder die Seite [„Vorlesung bearbeiten“](ed-edit-lecture).

<ul>
  <li>
     <a href="/mampf/de/mampf-pages/section" target="_self"><b>Seite des Abschnitts</b></a>
  </li>
  Oben links neben dem Titel des Abschnitts befindet sich das Symbol <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/edit-regular.png" width="12" height="12"/></button>, das einen auf die Seite „Abschnitt bearbeiten“ führt.
  <li>
     <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self"><b>„Vorlesung bearbeiten“</b></a>
  </li>
  Im Vorlesungsinhalt erreicht man über den <button>Abschnittstitel</button> die Seite „Abschnitt bearbeiten“.
</ul>

## Bereiche der Seite
Die Seite gliedert sich in zwei große Teilbereiche: die eigentliche Seite und die [Navigationsleiste](nav-bar). Die Bereiche sind exemplarisch in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/abschnitt_bearbeiten_navbar.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/abschnitt_bearbeiten_eigentlich.png" width="800"/>  |
|:---: | :---: |
|Navigationsleiste|Eigentliche Seite|

Die eigentliche Seite besteht aus dem Kopf und den Boxen „Basisdaten“ und „Inhalt“. Diese Bereiche sind in den folgenden Screenshots hervorgehoben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/abschnitt_bearbeiten_kopf.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/abschnitt_bearbeiten_basisdaten.png" width="800"/>  |
|:---: | :---: |
|Kopf|Basisdaten|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/abschnitt_bearbeiten_inhalt.png" width="800"/> |  |
|Inhalt||

## Bedienelemente und mögliche Aktionen auf dieser Seite
Nun werden die Bedienelemente der Seite „Abschnitt bearbeiten“ beschrieben. Dabei werden die einzelnen Bereiche nacheinander behandelt.

![](/img/abschnitt_bearbeiten_kurz.png)

### Kopf
In diesem Bereich gibt es Bedienelemente zur Navigation und der Übernahme von Änderungen.

* <a href="/mampf/de/mampf-pages/section" target="_self"><button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/eye-solid.png" width="12" height="12"/></button></a> Wechsel auf die <a href="/mampf/de/mampf-pages/section" target="_self">Seite des Abschnitts</a>.
* <button>Speichern</button> Übernimm die vorgenommenen Änderungen. Dieser Button erscheint erst, nachdem der Abschnitt bearbeitet worden ist. Wenn dieser Button nicht angeklickt wird, gehen alle Änderungen verloren.
* <button>Verwerfen</button> Verwirf die vorgenommenen Änderungen. Dieser Button erscheint erst, nachdem der Abschnitt bearbeitet worden ist.
* <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self"><button>zur Veranstaltung</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self">„Vorlesung bearbeiten“</a>.
* <button>Löschen</button> Lösche den Abschnitt. Falls es Sitzungen zu diesem Abschnitt gibt, erhalten diese den Status „verwaist“ und werden in der Gliederung auf der <a href="/mampf/de/mampf-pages/lecture" target="_self">Vorlesungsseite</a> nicht mehr angezeigt. Verwaiste Sitzungen werden auf der Seite <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self">„Vorlesung bearbeiten“</a> unter der Gliederung aufgeführt. Auf der Seite <a href="/mampf/de/mampf-pages/ed-edit-session" target="_self">„Sitzung bearbeiten“</a> kann ihnen wieder ein Abschnitt zugewiesen werden, wodurch sie wieder in der Gliederung auf der Vorlesungsseite erscheinen.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/keyboard-arrow-left.png" width="12" height="12"/></button> Wechsel zur Bearbeitungsseite des vorigen Abschnitts. (Auf der Bearbeitungsseite des ersten Abschnitts ist dieser Button nicht vorhanden.)
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/keyboard-arrow-right.png" width="12" height="12"/></button> Wechsel zur Bearbeitungsseite des nächsten Abschnitts. (Auf der Bearbeitungsseite des letzten Abschnitts ist dieser Button nicht vorhanden.)

### Basisdaten
In der Box „Basisdaten“ kommen die Bedienelemente Eingabefeld, Dropdownmenü, Checkbox und Button vor.

<table>
  <tr>
     <td valign="top">
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/abschnitt_bearbeiten_basisdaten_cut_schmal.png" width="4000" />
        <ul>
           <li>
              <form>
                <p>
                  <label for="fname">Titel <br></br></label>
                  <input type="text" id="fname" name="fname"></input><br></br>
                </p>
              </form>
              Eingabefeld für den Titel des Abschnitts. Dieses Feld muss ausgefüllt werden. Ein Abschnittstitel kann mehrfach innerhalb einer Vorlesung und sogar innerhalb eines Kapitels vergeben werden.
           </li>
           <li>
              <label for="cars"></label>Kapitel <br></br>
              <select name="cars" id="cars">
                 <option value="saab">Kapitel 1</option>
                 <option value="mercedes">Kapitel 2</option>
                 <option value="audi">Kapitel 3</option>
              </select><br></br> Dropdownmenü zur Auswahl des übergeordneten Kapitels.
           </li>
           <li>
              <label for="cars"></label>Positionierung nach Abschnitt <br></br>
              <select name="cars" id="cars">
                 <option value="volvo">am Anfang</option>
                 <option value="saab">anderer Abschnitt</option>
                 <option value="mercedes">anderer Abschnitt</option>
              </select><br></br> Dropdownmenü zur Auswahl des direkt vorausgehenden Abschnitts.
           </li>
        </ul>
     </td>
     <td valign="top">
        <ul>
          <li>
            <form>
              <p>
                <label for="fname">Anzeigenr.<br></br></label>
                <input type="text" id="fname" name="fname"></input><br></br>
              </p>
            </form>
            Eingabefeld für die Nummer des Abschnitts. Diese überschreibt die automatisch berechnete Nummer des Abschnitts. Dabei kann eine Nummer mehrfach vergeben werden.
          </li>
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
              Eingabefeld und Dropdown-Menü. Tippe in das Eingabefeld oder scrolle durch die Liste verfügbarer Tags und wähle die aus, die mit dem Abschnitt verknüpft werden sollen.
          </li>
          <li>
              Verknüpfter Tag <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button>
          </li>
              Löse die Verknüpfung von Tag und Abschnitt auf.
          <li>
              Sitzungen <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-plus-solid.png" width="15" height="15"/></button> Öffne das Formular zum Anlegen einer neuen Sitzung.
          </li>
          <li>
              <a href="/mampf/de/mampf-pages/ed-edit-session" target="_self"><button>Sitzung</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-session" target="_self">„Sitzung bearbeiten“</a>. Die Nummerierung der Sitzungen richtet sich nach dem Sitzungstermin und ist daher variabel.
          </li>
          <li>
              <form>
                <input type="checkbox" id="news" name="mis"></input>
                <label for="news"> von Gliederung ausgenommen</label>
              </form>
              Checkbox zum Exkludieren des Abschnitts von der Gliederung. Durch Anklicken der Box kann der Haken gesetzt bzw. entfernt werden. Bei gesetztem Haken wird der Abschnitt nicht in der Vorlesungsgliederung auf der <a href="/mampf/de/mampf-pages/lecture" target="_self">Vorlesungsseite</a> angezeigt. Auf der Seite <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self">„Vorlesung bearbeiten“</a> hingegen ist er weiterhin vorhanden, allerdings ist er dunkler als die anderen Abschnitte eingefärbt und mit einem * versehen.
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

#### Dialogfeld „Sitzung anlegen“
Das folgende Dialogfenster öffnet sich, nachdem auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-plus-solid.png" width="15" height="15"/></button> bei <i>Sitzungen</i> geklickt worden ist.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/abschnitt_bearbeiten_sitzung_anlegen.png" width="800"/>

* <form>
     <p>
        <label for="fname">Datum</label><br></br>
        <input type="text" id="fname" name="fname" value="TT.MM.JJJJ"></input><br></br>
     </p>
  </form>
  Eingabefeld zur Festlegung des Sitzungstermins. Sobald man in dieses Feld klickt, öffnet sich ein Datepicker. Das Feld kann manuell oder mithilfe des Datepickers ausgefüllt werden. Damit eine neue Sitzung angelegt werden kann, muss in das Feld ein valides Datum eingetragen worden sein.
* <form>
        <p>
           <label for="fname">Abschnitte</label><br></br>
           <input type="text" id="fname" name="fname"></input><br></br>
        </p>
     </form>
     Eingabefeld und Dropdown-Menü. Tippe in das Eingabefeld oder scrolle durch die Liste verfügbarer Abschnitte und wähle die aus, die mit der Sitzung verknüpft werden sollen.
* Verknüpfter Abschnitt <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button>
  Löse die Verknüpfung von Abschnitt und Sitzung auf.
* <button>Speichern</button> Lege die Sitzung an, schließe das Dialogfenster und kehre zurück zur Seite „Abschnitt bearbeiten“.
* <a href="/mampf/de/mampf-pages/ed-edit-session" target="_self"><button>Speichern und bearbeiten</button></a> Lege die Sitzung an, schließe das Dialogfenster und wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-session" target="_self">„Sitzung bearbeiten“</a>.
* <button>Abbrechen</button> Schließe das Dialogfenster, ohne eine Sitzung anzulegen.

### Inhalt
In der Box „Inhalt“ gibt es Bedienelemente zur Texteingabe und -formatierung. Außerdem können Bedienelemente zum Betrachten von verknüpften Videos und PDFs vorhanden sein. Nun werden die Bedienelemente zur Texteingabe und -formatierung vorgestellt.

<table>
  <tr>
    <td>
      <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/abschnitt_bearbeiten_inhalt_cut.png" width="3000"/>
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
        <li>
          <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/strikethrough.png" width="12" height="12"/></button> Beginne bzw. beende das Durchstreichen des Texts an der Stelle, an der sich der Cursor befindet, oder streiche den markierten Text durch bzw. stelle das Durchstreichen ab.
        </li>
      </ul>
    </td>
    <td>
      <ul>
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
    </td>
  </tr>
</table>

Damit Bedienelemente zum Betrachten von verknüpften Videos und PDFs verfügbar sind, muss eine der zwei folgenden Bedingungen erfüllt sein:
1. Eine Lektion ist zur verknüpften Sitzung assoziiert und das zur Lektion gehörige Video wurde mit dem [THymE-Editor](thyme-editor) gegliedert.
2. Das Vorlesungsskript wurde mit dem MaMpf-LaTeX-Paket erstellt und seine Gliederung ist in MaMpf importiert. Falls das MaMpf-Paket verwendet wird, hat die Videogliederung der assoziierten Lektionen keinen Einfluss auf den extrahierten Inhalt.

Falls eine der beiden Bedingungen erfüllt ist, können die folgenden Bedienelemente bei „Aus Medium extrahierter Inhalt“ vorzufinden sein:

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

Alle vorgenommenen Änderungen müssen gespeichert werden, sonst werden sie nicht übernommen.

## Von dieser Seite aus erreichbare Seiten
* [Abschnitt](section)
* [Sitzung bearbeiten](ed-edit-session)
* [Vorlesung bearbeiten](ed-edit-lecture)
* [THymE](thyme)

## Verwandte Seiten
* [Kapitel bearbeiten](ed-edit-chapter)
* [Sitzung bearbeiten](ed-edit-session)
* [Vortrag bearbeiten](edit-talk)
* [Veranstaltung bearbeiten](ed-edit-event-series)
* [Vorlesung bearbeiten](ed-edit-lecture)
* [Seminar bearbeiten](ed-edit-seminar)
* [Tag bearbeiten](ed-edit-tag)
* [Medium bearbeiten](edit-medium)
* [THymE-Editor](thyme-editor)
