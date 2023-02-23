---
title: Kapitel bearbeiten
---

Auf der Seite „Kapitel bearbeiten“ können Editor\*innen Änderungen an einem Kapitel einer [Vorlesung](lecture) vornehmen. Sie können die Position des Kapitels in der Vorlesungsgliederung verändern, die Kapitelnummer festlegen, Abschnitte innerhalb des Kapitels anlegen und den Beschreibungstext des Kapitels bearbeiten.

![](/img/kapitel_bearbeiten.png)

## Navigation zu dieser Seite
Auf die Seite „Kapitel bearbeiten“ gelangt man über die Seite [„Vorlesung bearbeiten“](ed-edit-lecture). Dort klickt man im Vorlesungsinhalt auf den <button>Kapiteltitel</button>.

## Bereiche der Seite
Die Seite gliedert sich in zwei große Teilbereiche: die eigentliche Seite und die [Navigationsleiste](nav-bar). Die Bereiche sind exemplarisch in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/kapitel_bearbeiten_navbar.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/kapitel_bearbeiten_eigentlich.png" width="800"/>  |
|:---: | :---: |
|Navigationsleiste|Eigentliche Seite|

Die eigentliche Seite besteht aus dem Kopf und den Boxen „Basisdaten“ und „Inhalt“. Diese Bereiche sind in den folgenden Screenshots hervorgehoben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/kapitel_bearbeiten_kopf.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/kapitel_bearbeiten_basisdaten.png" width="800"/>  |
|:---: | :---: |
|Kopf|Basisdaten|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/kapitel_bearbeiten_inhalt.png" width="800"/> |  |
|Inhalt||

## Bedienelemente und mögliche Aktionen auf dieser Seite
Nun werden die Bedienelemente der Seite „Kapitel bearbeiten“ beschrieben. Dabei werden die einzelnen Bereiche nacheinander behandelt.

![](/img/kapitel_bearbeiten.png)

### Kopf
In diesem Bereich gibt es Bedienelemente zur Navigation und der Übernahme von Änderungen.

* <button>Speichern</button> Übernimm die vorgenommenen Änderungen. Dieser Button erscheint erst, nachdem die Sitzung bearbeitet worden ist. Wenn dieser Button nicht angeklickt wird, gehen alle Änderungen verloren.
* <button>Verwerfen</button> Verwirf die vorgenommenen Änderungen. Dieser Button erscheint erst, nachdem die Sitzung bearbeitet worden ist.
* <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self"><button>zur Veranstaltung</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self">„Vorlesung bearbeiten“</a>.

### Basisdaten
In der Box „Basisdaten“ kommen die Bedienelemente Eingabefeld, Dropdownmenü, Checkbox und Button vor.

<table>
  <tr>
     <td valign="top">
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/kapitel_bearbeiten_basisdaten_cut.png" width="4000" />
        <ul>
           <li>
              <form>
                <p>
                  <label for="fname">Titel <br></br></label>
                  <input type="text" id="fname" name="fname"></input><br></br>
                </p>
              </form>
              Eingabefeld für den Titel des Kapitels. Dieses Feld muss ausgefüllt werden. Ein Kapitelttitel kann mehrfach innerhalb einer Vorlesung vergeben werden.
           </li>
           <li>
              <label for="cars"></label>Positionierung nach Kapitel <br></br>
              <select name="cars" id="cars">
                 <option value="volvo">am Anfang</option>
                 <option value="saab">anderes Kapitel</option>
                 <option value="mercedes">anderes Kapitel</option>
              </select><br></br> Dropdownmenü zur Festlegung der Position des Kapitels in der Vorlesungsgliederung.
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
            Eingabefeld für die Nummer des Kapitels. Diese überschreibt die automatisch berechnete Nummer des Kapitels. Dabei kann eine Nummer mehrfach vergeben werden.
          </li>
          <li>
              <form>
                <input type="checkbox" id="news" name="mis"></input>
                <label for="news"> von Gliederung ausgenommen</label>
              </form>
              Checkbox zum Exkludieren des Kapitels von der Gliederung. Durch Anklicken der Box kann der Haken gesetzt bzw. entfernt werden. Bei gesetztem Haken wird das Kapitel und alle seine Abschnitte nicht in der Vorlesungsgliederung auf der <a href="/mampf/de/mampf-pages/lecture" target="_self">Vorlesungsseite</a> angezeigt. Auf der Seite <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self">„Vorlesung bearbeiten“</a> hingegen ist es weiterhin vorhanden, allerdings ist es anders als die anderen Kapitel eingefärbt und mit einem * versehen.
          </li>
          <li>
              Abschnitte <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-plus-solid.png" width="15" height="15"/></button> Öffne das Formular zum Anlegen eines neuen Abschnitts.
          </li>
          <li>
              <a href="/mampf/de/mampf-pages/ed-edit-section" target="_self"><button>Abschnitt</button></a> Wechsel auf die <a href="/mampf/de/mampf-pages/ed-edit-section" target="_self">Bearbeitungsseite des Abschnitts</a>.
          </li>
        </ul>
     </td>
  </tr>
</table>

#### Dialogfeld „Abschnitt anlegen“
Das folgende Dialogfenster öffnet sich, nachdem auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-plus-solid.png" width="15" height="15"/></button> bei <i>Abschnitte</i> geklickt worden ist.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/kapitel_bearbeiten_abschnitt_anlegen.png" width="800"/>

* <form>
     <p>
        <label for="fname">Titel</label><br></br>
        <input type="text" id="fname" name="fname" value=""></input><br></br>
     </p>
  </form>
  Eingabefeld für den Titel des Abschnitts. Damit ein neuer Abschnitt angelegt werden kann, muss ein Titel eingegeben werden. Ein Abschnittstitel kann mehrfach innerhalb einer Vorlesung und sogar innerhalb eines Kapitels vergeben werden.
* <label for="cars"></label>Einfügen nach Abschnitt <br></br>
<select name="cars" id="cars">
   <option value="volvo">am Anfang des Kapitels</option>
   <option value="saab">Abschnitt 1</option>
   <option value="mercedes" selected>Abschnitt 2</option>
</select><br></br> Dropdownmenü zur Auswahl der Position des Abschnitts im Kapitel.
* <button>Speichern</button> Lege den Abschnitt an, schließe das Dialogfenster und kehre zurück zur Seite „Kapitel bearbeiten“.
* <button>Abbrechen</button> Schließe das Dialogfenster, ohne einen Abschnitt anzulegen.

### Inhalt
In der Box „Inhalt“ gibt es Bedienelemente zur Texteingabe und -formatierung.

<table>
  <tr>
    <td>
      <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/kapitel_bearbeiten_inhalt_cut.png" width="3000"/>
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
        <li>
          <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link-solid.png" width="12" height="12"/></button> Füge einen Hyperlink ein oder mache aus dem markierten Text einen Hyperlink bzw. mache aus dem Hyperlink einfachen Text.
        </li>
        <li>
          <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-size.png" width="12" height="12"/></button> Vergrößere Text in Standardgröße bzw. verkleinere großen Text.
        </li>
      </ul>
    </td>
    <td>
      <ul>
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
      </ul>
    </td>
  </tr>
</table>

Alle vorgenommenen Änderungen müssen gespeichert werden, sonst werden sie nicht übernommen.

## Von dieser Seite aus erreichbare Seiten
* [Abschnitt bearbeiten](ed-edit-section)
* [Vorlesung bearbeiten](ed-edit-lecture)

## Verwandte Seiten
* [Abschnitt bearbeiten](ed-edit-section)
* [Sitzung bearbeiten](ed-edit-session)
* [Vortrag bearbeiten](edit-talk)
* [Seminar bearbeiten](ed-edit-seminar)
* [Veranstaltung bearbeiten](ed-edit-event-series)
* [Vorlesung bearbeiten](ed-edit-lecture)
