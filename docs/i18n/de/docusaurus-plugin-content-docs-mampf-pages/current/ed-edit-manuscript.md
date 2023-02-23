---
title: Skript bearbeiten
---
Auf der Seite „Skript bearbeiten“ können Editor\*innen Änderungen an einem Medium vom Typ <i>Skript</i> vornehmen. Dazu gehören die Veröffentlichung des Skriptes, das Bearbeiten von Medientitel, Zugriffsrechten und Sprache, die Verknüpfug des Skripts mit anderen Medien, das Verfassen oder Bearbeiten der Inhaltsangabe, das Hochladen oder Ersetzen des PDFs sowie das Betrachten der Aufruf- und Downloadstatistik. Falls in den [Veranstaltungseinstellungen](ed-edit-event-series#einstellungen) die Inhaltsvermittlung „unter Verwendung eines Veranstaltungsskriptes, das mit dem MaMpf LaTeX-Paket erstellt wurde“  ausgewählt ist, können Editor\*innen zudem die Gliederung und Tags aus dem Skript importieren, sofern das Skript mit dem [MaMpf-LaTeX-Paket](https://github.com/MaMpf-HD/mampf-sty/releases/) erstellt wurde.

Der Medientyp <i>Skript</i> und die zugehörige Bearbeitungsseite haben viel mit den anderen Medientypen und ihren Bearbeitungsseiten gemeinsam, bringen aber einige Besonderheiten mit sich. So können Skripte nur auf Veranstaltungsebene aber nicht auf Modulebene angelegt werden. Ferner kann es pro Veranstaltung höchstens ein Skript geben. Bei keinem anderen Medientyp bestehen diese Einschränkungen. Außerdem kann bei Skripten der Medientyp nicht verändert werden. Weiterhin ist es unter bestimmten Voraussetzungen möglich, Gliederung und Tags aus dem Skript zu importieren.

![](/img/skript_bearbeiten_cut.png)

## Navigation
Auf die Seite „Skript bearbeiten“ gelangt man über die [Seite des Skriptes](medium) oder die Seite [„Veranstaltung bearbeiten“](ed-edit-event-series).

<ul>
  <li>
     <a href="/mampf/de/mampf-pages/medium" target="_self"><b>Seite des Skriptes</b></a>
  </li>
  Oben links neben dem Titel des Skriptes befindet sich das Symbol <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/edit-regular.png" width="12" height="12"/></button>, das einen auf die Seite „Skript bearbeiten“ führt.
  <li>
     <a href="/mampf/de/mampf-pages/ed-edit-event-series" target="_self"><b>„Veranstaltung bearbeiten“</b></a>
  </li>
  In der Box „Medien“ erreicht man über den <button>Skripttitel</button> im Tab <button>Skript</button> die Seite „Skript bearbeiten“.
</ul>

## Bereiche der Seite
Die Seite gliedert sich in zwei große Teilbereiche: die eigentliche Seite und die [Navigationsleiste](nav-bar). Die Bereiche sind exemplarisch in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/skript_bearbeiten_navbar.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/skript_bearbeiten_eigentlich.png" width="800"/>  |
|:---: | :---: |
|Navigationsleiste|Eigentliche Seite|

Die eigentliche Seite besteht aus dem Kopf und den Boxen „Basisdaten“, „Dokumente“ und „Inhalt“. Diese Bereiche sind in den folgenden Screenshots hervorgehoben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/skript_bearbeiten_kopf.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/skript_bearbeiten_basis.png" width="800"/>  |
|:---: | :---: |
|Kopf|Basisdaten|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/skript_bearbeiten_inhalt.png" width="800"/> |  <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/skript_bearbeiten_dok.png" width="800"/>|
|Inhalt|Dokumente|


## Bedienelemente und mögliche Aktionen auf dieser Seite
Nun werden die Bedienelemente der Seite „Skript bearbeiten“ beschrieben. Dabei werden die einzelnen Bereiche nacheinander behandelt.

### Kopf
In diesem Bereich gibt es Steuerelemente zur Navigation, der Verwaltung der Veröffentlichung und der Übernahme von Änderungen.

* <a href="/mampf/de/mampf-pages/medium" target="_self"><button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/eye-solid.png" width="12" height="12"/></button></a> Wechsel auf die <a href="/mampf/de/mampf-pages/medium" target="_self">Seite des Skriptes</a>.
* <button>Bearbeiten</button> Verwalte die Veröffentlichung. Dieser Button ist nur bei unveröffentlichten Skripten mit geplanter Veröffentlichung vorhanden.
* <button>Stornieren</button> Storniere die geplante Veröffentlichung. Dieser Button ist nur bei unveröffentlichten Skripten mit geplanter Veröffentlichung vorhanden.
* <button>Speichern</button> Übernimm die vorgenommenen Änderungen. Dieser Button erscheint erst, nachdem Änderungen vorgenommen worden sind.
* <button>Verwerfen</button> Verwirf die vorgenommenen Änderungen. Dieser Button erscheint erst, nachdem Änderungen vorgenommen worden sind.
* <a href="/mampf/de/mampf-pages/ed-edit-event-series" target="_self"><button>zur Veranstaltung</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-event-series" target="_self">„Veranstaltung bearbeiten“</a>.
* <button>Veröffentlichen</button> Öffne das Formular „Veröffentlichung des Mediums verwalten“. Veröffentliche das Medium. Dieser Button kann nur bei unveröffentlichten Skripten vorhanden sein. Damit der Button angezeigt wird, muss ferner die Veranstaltung, zu der das Skript gehört, schon veröffentlicht worden sein und es dürfen keine Änderungen am Skript seit dem letzten Speichern vorgenommen worden sein.
* <button>Löschen</button> Lösche das Skript. Dieser Button wird nur angezeigt, wenn es keine Dokumente zu dem Skript gibt.

#### Formular „Veröffentlichung des Mediums verwalten“
Das Formular „Veröffentlichung des Mediums verwalten“ öffnet sich, nach dem auf <button>Veröffentlichen</button> geklickt worden ist.

![](/img/medium_veroeffentlichen_ohne_quiz.png)

* <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="12" height="12"/></button> Bricht die Aktion ab und schließe das Formular.
* Veröffentlichungsdatum <form>
    <input type="radio" id="de1" name="lang" checked></input>
    <label for="vererb"> sofort</label><br></br>
    <input type="radio" id="de2" name="lang"></input>
    <label for="ohnever"> zum folgenden Zeitpunkt</label>
 </form> Radio Buttons zur Festlegung des Veröffentlichungsdatums. Zur Auswahl stehen <i>sofort</i> und <i>zum folgenden Zeitpunkt</i>. Soll das Medium zu einem bestimmten Zeitpunkt veröffentlicht werden, muss dieser in das entsprechende Feld eingetragen werden.
* <form>
     <p>
         <input type="text" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Eingabefeld für den geplanten Veröffentlichungszeitpunkt. Dieser kann manuell eingegeben oder im Datepicker, der sich beim Anklicken des Felds öffnet, ausgewählt werden. Dieses Bedienelement ist nur aktiv, wenn als Veröffentlichtungsdatum <i>zum folgenden Zeitpunkt</i> ausgewählt ist.
* Zugriffsrechte <form>
    <input type="radio" id="de4" name="lang" checked></input>
    <label for="vererb"> frei</label><br></br>
    <input type="radio" id="de5" name="lang"></input>
    <label for="ohnever"> nur registrierte MaMpf-NutzerInnen</label><br></br>
    <input type="radio" id="de6" name="lang"></input>
    <label for="vererb"> nur AbonnentInnen</label><br></br>
    <input type="radio" id="de7" name="lang"></input>
    <label for="ohnever"> gesperrt</label>
 </form> Radio Buttons zur Festlegung der Zugriffsrechte, die erst nach der Veröffentlichung des Skriptes verfügbar sind. Zur Auswahl stehen <i>frei</i>, <i>nur registrierte MaMpf-NutzerInnen</i>, <i>nur AbonnentInnen</i> und <i>gesperrt</i>. Diese Einstellung kann nachträglich in der Box „Basisdaten“ verändert werden.
* <form>
      <input type="checkbox" id="ass" name="ass"></input>
      <label for="ass"> Kommentare für dieses Medium deaktivieren </label>
  </form>
   Checkbox. Setze oder entferne durch Anklicken den Haken, um die Kommentarfunktion für das Medium zu deaktivieren bzw. aktivieren. Diese Einstellung kann nachträglich in der Box „Basisdaten“ verändert werden. Standardmäßig ist der Haken nicht gesetzt. Auf der Seite  <a href="/mampf/de/mampf-pages/ed-edit-event-series#kommentare" target="_self">„Veranstaltung bearbeiten“</a> kann eingestellt werden, dass der Haken standardmäßig in diesem Formular gesetzt wird.
* <form>
      <input type="checkbox" id="ass" name="ass"></input>
      <label for="ass"> Ich bestätigte hiermit, dass durch die Veröffentlichung des Mediums auf der MaMpf-Plattform keine Rechte Dritter verletzt werden.</label>
  </form>
   Checkbox. Setze durch Anklicken den Haken und bestätige damit, dass die Veröffentlichung keine Rechte Dritter verletzt. Dieser Haken muss für die Veröffentlichung des Mediums gesetzt werden.
* <button>Speichern</button> Veröffentliche das Medium bzw. bestätige die die geplante Veröffentlichung und schließe das Formular.

Bei <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/unveroeffentlicht.png" height="16"/>, <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/veroeffentlichungszeitpunkt.png" height="16"/> und <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/gesperrt.png" height="16"/> handelt es sich nicht um Bedienelemente. Sie informieren lediglich über den Öffentlichkeitsstatus des Skriptes und bei Skripten mit geplanter Veröffentlichung über deren Zeitpunkt. Falls an dieser Stelle kein Badge angezeigt wird, ist das Skript öffentlich und alle Nutzer\*innen, die über die unter „Basisdaten“ ausgewählten Rechte verfügen, können das Skript sehen und darauf zugreifen.


### Basisdaten
In diesem Bereich können Detailseinstellungen des Skriptes verändert werden, dazu gehören Titel, Bearbeitungs- und Zugriffsrechte, Verknüpfungen und Spracheinstellungen.

<table>
  <tr>
     <td valign="top">
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/skript_bearbeiten_basis_cut.png" width="2000"/><br></br><br></br>
        <ul>
           <li>
              <form>
                 <p>
                    <label for="fname">EditorInnen</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
             Eingabefeld und Dropdown-Menü. Gib mindestens zwei Zeichen ein, scrolle durch die Liste aller Nutzer*innen und wähle die aus, die Editorenrechte für das Skript erhalten sollen.
           </li>
           <li>
              EditorIn <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button>
           </li>
              Entziehe dieser Person die Editorenrechten für das Skript. Das funktioniert nur, wenn die Person keine höheren Rechte als Medienbearbeitung in dieser Veranstaltung besitzt. Jedes Medium benötigt mindestens ein*e Editor*in.
          <li>
              <form>
                 <p>
                    <label for="fname">Titel</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
                Eingabefeld für den Skripttitel. Der Titel kann bearbeitet werden.
           </li>
        </ul>
     </td>
     <td valign="top">
        <ul>
           <li>
              <form>
                 <p>
                    <label for="fname">Verknüpfte Medien</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld und Dropdown-Menü. Gib mindestens zwei Zeichen ein, scrolle durch die Liste aller Medien und wähle die aus, die mit dem Skript verknüpft werden sollen.
           </li>
           <li>
              Verknüpftes Medium <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="15" height="15"/></button>
           </li>
              Hebe die Assoziierung mit dem Medium auf.
           <li>
              <form>Zugriffsrechte<br></br>
                 <input type="radio" id="de" name="lang" checked></input>
                 <label for="de"> frei</label><br></br>
                 <input type="radio" id="eng" name="lang"></input>
                 <label for="eng"> nur registrierte MaMpf-NutzerInnen</label><br></br>
                 <input type="radio" id="de2" name="lang"></input>
                 <label for="de2"> nur AbonenntInnen</label><br></br>
                 <input type="radio" id="eng2" name="lang"></input>
                 <label for="eng2"> gesperrt</label>
              </form>
              Wähle aus, welche Nutzergruppe das Skript sehen können soll. Diese Einstellung kann beliebig oft, aber erst nach der Veröffentlichung des Skriptes verändert werden. Zur Auswahl stehen <i>frei</i>, <i>nur registrierte MaMpf-NutzerInnen</i>, <i>nur AbonenntInnen</i> und <i>gesperrt</i>.
           </li>
           <li>
              <form>
                 <input type="checkbox" id="news" name="mis"></input><label for="news">Kommentare deaktiviert</label>
              </form>
              Deaktiviere durch Setzen des Hakens die Möglichlichkeit, das Skript zu kommentieren, bzw. aktiviere sie durch Entfernen des Hakens.
           </li>
           <li>
              <form>
                 Sprache<br></br>
                 <input type="radio" id="de" name="lang" checked></input>
                 <label for="de"> Deutsch</label>&nbsp;
                 <input type="radio" id="eng" name="lang"></input>
                 <label for="eng"> Englisch</label>
              </form>
              Lege die Sprache des Skriptes fest. Die gewählte Sprache wird auf der hier beschriebenen Seite, der <a href="/mampf/de/mampf-pages/medium" target="_self">Medienseite</a> und der <a href="/mampf/de/mampf-pages/mediacard" target="_self">Mediacard</a> verwendet. Davon sind insbesondere die Einträge in THmyE und die Tags betroffen. Zur Auswahl stehen Deutsch und Englisch.
           </li>
           <li>
              <form>
                 <p>
                    <label for="fname">Boost</label><br></br>
                    <input type="text" id="fname" name="fname" value="0.0"></input>
                 </p>
              </form>
              Verändere die Reihenfolge, in der Medien anzeigt werden. Je höher der Boostwert ist, desto weiter vorne wird das Skript aufgeführt. Dies wirkt sich nicht auf die Anzeigereihenfolge von Medien aus, die zu einer Sitzung assoziiert sind.
           </li>
        </ul>
     </td>
  </tr>
</table>

Alle vorgenommenen Änderungen müssen gespeichert werden, sonst werden sie nicht übernommen.

### Inhalt
Der unter Inhaltsangabe eingegebene Text erscheint auf der [Medienseite](medium) in der Box „Inhalt“. Dazu stehen Bedienelemente zur Textformatierung und -bearbeitung zur Verfügung:

<table>
  <tr>
     <td valign="top">
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/medium_bearbeiten_vortragender_inhalt.png" width="4000" /><br></br><br></br>
        <ul>
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
              <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/format-quote.png" height="8"/></button> Beginne bzw. beende ein Zitat an der Stelle, an der sich der Cursor befindet, oder mache aus dem markierten Text ein Zitat bzw. aus dem markierten Zitat einfachen Text.
           </li>
        </ul>
     </td>
     <td valign="top">
        <ul>
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
           <li>
              <form>
                 <p>
                    <label for="fname"></label>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>Eingabefeld für den Inhaltstext.
           </li>
        </ul>
     </td>
  </tr>
</table>

Alle vorgenommenen Änderungen müssen gespeichert werden, sonst werden sie nicht übernommen.

Falls die Gliederung aus dem Skript importiert wurde, gibt es bei „Extrahierter Inhalt“ zusätzlich das Bedienelement <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/menu-book.png" width="12" height="12"/></button>. Dieses führt dazu, dass das Skript an der entsprechenden Stelle in einem neuen Tab geöffnet wird. Damit die Gliederung aus dem PDF übernommen werden kann, muss zu einen in den [Veranstaltungseinstellungen](ed-edit-event-series#einstellungen) die Inhaltsvermittlung „unter Verwendung eines Veranstaltungsskriptes, das mit dem MaMpf LaTeX-Paket erstellt wurde“ ausgewählt und zum anderen das Skript mit dem [MaMpf-LaTeX-Paket](https://github.com/MaMpf-HD/mampf-sty/releases/) erstellt worden sein. Weitere Informationen zum Gliederungs- und Tagimport sind im Abschnitt über die Box „Dokumente“ zu finden.

![](/img/skript_bearbeiten_inhalt_import_plus.png)

### Dokumente
In diesem Bereich können ein PDF hinzugefügt, bearbeitet oder entfernt werden. Bei Auswahl der Inhaltsvermittlung „unter Verwendung eines Veranstaltungsskriptes, das mit dem MaMpf LaTeX-Paket erstellt wurde“ in den [Veranstaltungseinstellungen](ed-edit-event-series#einstellungen) können hier außerdem die Gliederung und Tags aus dem Skript importiert werden. Bevor ein PDF hochgeladen wurde, sieht die Box aus wie im folgenden Screenshot.

![](/img/skript_bearbeiten_dokumente.png)

Zwei Bedienelemente sind verfügbar:
* <button>Statistik</button> Öffne die Downloadstatistik des Skriptes.
* <button>Datei</button> Wähle eine Datei vom Endgerät aus, die hochgeladen werden soll. Die Datei muss das richtige Format haben, d.h. PDF. Höchstens eine Datei kann hinzugefügt werden. Wenn also schon eine Datei vorhanden ist, wird diese nach dem Speichern unwiderruflich überschrieben.

Nachdem eine Datei ausgewählt worden ist, erscheint in der Box „Dokumente“ der Button <button>Upload</button> und im Kopf der Button <button>Speichern</button>. Um die Datei erfolgreich hinzuzufügen, muss erst auf <button>Upload</button> und anschließend auf <button>Speichern</button> geklickt werden. Danach bestehen Unterschiede je nach Wahl der in den [Veranstaltungseinstellungen](ed-edit-event-series#einstellungen) ausgewählten Inhaltsermittlung.

#### Statistik
Die Downloadstatistik öffnet sich, wenn man in der Box „Dokumente“ auf <button>Statistik</button> klickt. Dort werden Anzahl und Tag der Downloads von PDFs graphisch dargestellt. In diesem Fenster gibt es nur den Button zum Schließen des Fensters. Dieser befindet sich in der oberen rechten Ecke.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/medienstatistik_aufruf_download_nur_manu.png" width="400"/>

#### Medienbasierte Inhaltsermittlung
Bei der medienbasierten Inhaltsermittlung gibt es nach dem Hochladen eines PDFs die beiden weiteren Bedienelemente <button>Screenshot</button> und <button>Ansehen</button> in der Box „Dokumente“.

![](/img/skript_bearbeiten_dokumente_standard.png)

In der Box sind somit die folgenden Bedienelemente verfügbar.

* <button>Statistik</button> Öffne die Downloadstatistik des Skriptes.
* <button>Datei</button> Wähle eine Datei vom Endgerät aus, die hochgeladen werden soll. Die Datei muss das richtige Format haben, d.h. PDF. Höchstens eine Datei kann hinzugefügt werden. Wenn also schon eine Datei vorhanden ist, wird diese nach dem Speichern unwiderruflich überschrieben.
* <button>Screenshot</button> Öffne den Screenshot, der auf der <a href="/mampf/de/mampf-pages/medium" target="_self">Medienseite</a> und der <a href="/mampf/de/mampf-pages/mediacard" target="_self">Mediacard</a> angezeigt wird, in einem Dialogfeld. Dabei wird stets die erste Seite des PDFs verwendet.
* <button>Ansehen</button> Öffne das Skript in einem neuen Tab.

#### Inhaltsermittlung unter Verwendung eines Skriptes, das mit dem MaMpf-Paket erstellt wurde
Bei der Inhaltsvermittlung „unter Verwendung eines Veranstaltungsskriptes, das mit dem MaMpf LaTeX-Paket erstellt wurde“ kommen nach dem Hochladen eines PDFs ebenfalls die Bedienelemente <button>Screenshot</button> und <button>Ansehen</button> hinzu. Darüber hinaus sind auch die Buttons <button>Details</button> und <button>Übernehmen</button> vorhanden.

![](/img/skript_bearbeiten_dokumente_upload.png)

Somit stehen die folgenden Bedienelemente zur Verfügung:

* <button>Statistik</button> Öffne die Downloadstatistik des Skriptes.
* <button>Datei</button> Wähle eine Datei vom Endgerät aus, die hochgeladen werden soll. Die Datei muss das richtige Format haben, d.h. PDF. Höchstens eine Datei kann hinzugefügt werden. Wenn also schon eine Datei vorhanden ist, wird diese nach dem Speichern unwiderruflich überschrieben.
* <button>Screenshot</button> Öffne den Screenshot, der auf der <a href="/mampf/de/mampf-pages/medium" target="_self">Medienseite</a> und der <a href="/mampf/de/mampf-pages/mediacard" target="_self">Mediacard</a> angezeigt wird, in einem Dialogfeld. Dabei wird stets die erste Seite des PDFs verwendet.
* <button>Details</button> Öffne das Formular „Struktur des Manuskripts“, um die Elemente, die importiert werden sollen, auszuwählen und im Fall von Widersprüchen im Skript weitere Informationen zu erhalten.
* <button>Übernehmen</button> Importiere die im Formular „Struktur des Manuskripts“ ausgewählten Elemente. Dies ist nur möglich, wenn es keine Widersprüche im Skript gibt.

Der Hinweis „Achtung: Die Struktur des Manuskripts wurde noch nicht übernommen.“ verschwindet, nachdem auf <button>Übernehmen</button> geklickt worden ist.

##### Formular „Struktur des Manuskripts“
Das Formular „Struktur des Manuskripts“ öffnet sich, nachdem in der Box „Dokumente“ auf <button>Details</button> geklickt worden ist. Dies ist nur bei der Inhaltsvermittlung „unter Verwendung eines Veranstaltungsskriptes, das mit dem MaMpf LaTeX-Paket erstellt wurde“ möglich.

![](/img/skript_bearbeiten_details.png)

In diesem Formular sind die folgenden Bedienelemente vorhanden:
* <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" width="12" height="12"/></button> Schließe das Formular.
* <button>Kapiteltitel</button> Klappe Details zum Kapitel aus bzw. ein.
* <button>Abschnittstitel</button> Klappe Details zum Abschnitt aus bzw. ein.
* <a href="/mampf/de/mampf-pages/ed-editmedium" target="_self"><button>Begriff</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-editmedium" target="_self">„Tag bearbeiten“</a>. Dieses Bedienelement ist nur vorhanden, wenn der Begriff bereits importiert oder auf andere Weise angelegt wurde.
*  <form><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/tag-solid.png" width="12" height="12"/><input type="checkbox" id="ass" name="ass"></input></form>
   Checkbox. Setze bzw. entferne den Haken durch Anklicken. Wenn der Haken gesetzt ist, wird der Tag bei der Übernahme importiert.
* <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/eye_other.png" height="14"/> <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/toggle-on.png" width="12" height="12"/> bzw. <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/outline-toggle-off.png" width="12" height="12"/> Schalter. Verschiebe den Regler durch Anklicken. Wenn <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/toggle-on.png" width="12" height="12"/> ausgewählt ist, wird das Gliederungselement importiert und auf den Seiten <a href="/mampf/de/mampf-pages/section" target="_self">„Abschnitt“</a> und <a href="/mampf/de/mampf-pages/ed-edit-section" target="_self">„Abschnitt bearbeiten“</a> angezeigt.

Nachdem in der Box „Dokumente“ auf <button>Übernehmen</button> geklickt worden ist, wird in der Box „Inhalt“ die Grobstruktur der importierten Gliederung, d.h. Kapitel und Abschnitte, angezeigt. Die Feinstruktur kann auf der Seite [„Abschnitt bearbeiten“](ed-edit-section) betrachtet werden.

![](/img/skript_bearbeiten_inhalt_import.png)

## Verwandte Seiten
* [Abschnitt bearbeiten](ed-edit-section)
* [Erläuterung bearbeiten](edit-medium-remark)
* [Frage bearbeiten](edit-medium-question)
* [Medium bearbeiten](edit-medium)
* [Quiz bearbeiten](edit-quiz)
* [Veranstaltung bearbeiten](ed-edit-event-series)
