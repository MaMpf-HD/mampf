---
title: Clicker
---

Ein Clicker ist ein Feedbackkanal, der auf MaMpf als Seite realisiert ist. Personen mit dem Editorlink können Feedback zu einer Fragestellung erbitten und Personen mit dem Teilnehmerlink können dieses Feedback geben. Pro Clicker ist zu jedem Zeitpunkt genau eine Fragestellung möglich. Dabei können auch Fragen aus der MaMpf-Datenbank verwendet werden. Die Fragen bzw. Antwortmöglichkeiten können beliebig oft verändert werden, weshalb Clicker wiederverwendet werden können.

![](/img/clicker.png)

## Navigation zu dieser Seite
Clicker sind über die [Übersichsseite](ed-overview) der Adminstration erreichbar. Die Übersicht öffnet sich, je nachdem ob man sich bereits im Administrationsmodus befindet oder nicht, wenn man auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/home-solid.png" width="12" height="12"/></button> bzw. <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/tools-solid.png" width="12" height="12"/></button> in der [Navigationsleiste](nav-bar) klickt. Dort gelangt man über den <button>Clickertitel</button> in der Box „Meine Clicker“ zum gewünschten Clicker. Dies ist nur möglich, wenn es bereits Clicker gibt. Um einen Clicker anzulegen, steht der Button <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-plus-solid.png" width="12" height="12"/></button> im Kopf der Box „Meine Clicker“ zur Verfügung.

## Bereiche der Seite
Die Seite gliedert sich in zwei große Teilbereiche: die eigentliche Seite und die [Navigationsleiste](nav-bar). Die Bereiche sind exemplarisch in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_navbar.png" width="700"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_eigentlich.png" width="700"/>  |
|:---: | :---: |
|Navigationsleiste|Eigentliche Seite|

Die eigentliche Seite besteht aus einem Akkordeon mit den Rubriken „Nutzerlink“, „Editorlink“, „Löschen“, „Antworten“ bzw. „Frage“ und „Ergebnis“. Dies ist in den folgenden Screenshots dargestellt.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_link_user.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_link_ed.png" width="800"/>  |
|:---: | :---: |
|Nutzerlink|Editorlink|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_loeschen.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_frage_antworten.png" width="800"/>  |
|Löschen|Antworten|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_results.png" width="800"/> |  |
|Ergebnis||

## Bedienelemente und mögliche Aktionen auf dieser Seite
Im Folgenden werden sämtliche mögliche Bedienelemente des Clickers aufgeführt. Die Bedienelemente befinden sich sowohl im als auch unter dem Akkordeon. Zunächst werden die Bedienelemente der einzelnen Akkordeonfächer beschrieben.

![](/img/clicker.png)

### Akkordeon
Das Akkordeon bestehen aus den Fächern „Nutzerlink“, „Editorlink“, „Löschen“, „Antworten“ bzw. „Frage“ und „Ergebnis“.

#### Nutzerlink
Im Fach „Nutzerlink“ gibt es den Button <button>QR-Code anzeigen</button> bzw. <button>QR-Code verstecken</button>, mit dem der QR-Code aus- bzw. eingeklappt werden kann. Teilnehmer\*innen können den Code mithilfe der Kamera ihres Smartphone scannen, um auf die Teilnehmerseite des Clickers zu gelangen. Alternativ können sie auch die angezeigte Adresse in das Adressfeld ihres Browsers eingeben.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_qr.png" width="800"/>

#### Editorlink
Im Fach „Editorlink“ ist der Button <button>Anzeigen</button> bzw. <button>Verbergen</button> vorzufinden. Mit diesem kann der Editorlink ein- bzw. ausgeblendet werden. Unter diesem Link kann der Clicker ohne Login verwaltet werden. Teilnehmer\*innen sollten diesen Link nicht zu sehen bekommen.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_ed_link.png" width="800"/>

#### Löschen
Im Fach „Löschen“ kommt lediglich der Button <button>Löschen</button> vor, mit dem der Clicker gelöscht werden kann.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_delete.png" width="800"/>

#### Antworten bzw. Frage
Das Aussehen und die Bedienelemente dieses Fach richten sich danach, ob eine Quizfrage zum Clicker assoziiert ist.

##### Keine Assoziierung mit einer Quizfrage
Ist keine Quizfrage zum Clicker assoziiert, so gibt es Radiobuttons und einen einfachen Button. Diese sind nur bedienbar, wenn der Clicker geschlossen ist.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_antworten.png" width="800"/>

* Anzahl der Auswahlmöglichkeiten
<form><input type="radio" id="de" name="lang"></input>
   <label for="2"> 2</label>
   <input type="radio" id="de" name="lang" checked></input>
   <label for="3"> 3</label>
   <input type="radio" id="de" name="lang"></input>
   <label for="4"> 4</label>
   <input type="radio" id="de" name="lang"></input>
   <label for="5"> 5</label>
   <input type="radio" id="de" name="lang"></input>
   <label for="6"> 6</label></form> Radiobuttons zur Festlegung der Anzahl der Antwortenmöglichkeiten. Zur Auswahl stehen <i>2</i>, <i>3</i>, <i>4</i>, <i>5</i> und <i>6</i>, wobei <i>3</i> der voreingestellte Wert ist.
* <button>Quizfrage assoziieren</button> Wechsel zur Suche, um eine Frage zu finden und zum Clicker zu assoziieren. Nachdem eine Assoziierung angelegt worden ist, erscheint die Ansicht „Assoziierung mit einer Quizfrage“.

##### Bei Assoziierung mit einer Quizfrage
Ist eine Frage assoziiert, so wird diese angezeigt und es gibt zwei Buttons. Diese sind nur bedienbar, wenn der Clicker geschlossen ist.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_frage.png" width="800"/>

* <button>Assoziierung zu Quizfrage aufheben</button> Hebe die bestehende Assoziierung zwischen Frage und Clicker auf. Nachdem die Assoziierung aufgehoben worden ist, erscheint die Ansicht „Keine Assoziierung mit einer Quizfrage“.
* <button>Andere Quizfrage assoziieren</button> Wechsel zur Suche, um eine andere Frage zu finden und diese zum Clicker zu assoziieren.

##### Suche
Bei der Suche gibt es zunächst nur eine Suchmaske. Nachdem eine Suche durchgeführt worden ist, werden die Treffer in einer Tabelle aufgeführt und bei entsprechender Trefferzahl stehen auch Elemente zur Seitennavigation zur Verfügung. Einzelne Treffer können durch Anlicken in der Vorschau geöffnet werden.

###### Maske
In der Suchmaske sind folgende Bedienelemente vorzufinden:

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_suche_kompakt.png" width="5000"/>
        <ul>
          <li>
            Assoziiert zu / Verknüpfte Tags / EditorInnen<br></br> <form>
                <input type="checkbox" id="ass" name="ass" checked></input>
               <label for="ass"> alle</label>
             </form><br></br> bzw. <br></br><br></br>
              <form>
                  <p>
                     <label for="fname">Assoziiert zu / Verknüpfte Tags / EditorInnen</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                  </p>
               </form>
               <form>
                   <input type="checkbox" id="news" name="mis"></input>
                   <label for="news"> alle</label>
                </form>
                Checkbox und bei nicht gesetztem Haken auch Eingabefeld mit Dropdownmenü. Im Dropdownmenü können Assoziationen / verknüpfte Tags / Editor*innen der Frage ausgewählt werden.
           </li>
           <li>
             Assoziiert zu <form>
                <input type="radio" id="de" name="lang" checked></input>
                <label for="vererb"> mit Verebung</label>
                <input type="radio" id="de" name="lang"></input>
                <label for="ohnever"> ohne Vererbung</label>
             </form> Radiobuttons mit den Auswahlmöglichkeiten <em>mit Vererbung</em> und <em>ohne Vererbung</em>. Wenn <em>mit Vererbung</em> ausgewählt ist, werden bei Modulen auch mit Veranstaltungen und Sitzungen verknüpfte Fragen und bei Veranstaltungen mit Sitzungen verknüpfte Fragen berücksichtigt.
           </li>
        </ul>
     </td>
     <td valign="top">
        <ul>
            <li>
              Verknüpfte Tags <form>
                 <input type="radio" id="de" name="lang" checked></input>
                 <label for="oder"> ODER</label>
                 <input type="radio" id="de" name="lang"></input>
                 <label for="und"> UND</label>
              </form> Radiobuttons mit den Auswahlmöglichkeiten <em>ODER</em> und <em>UND</em>. Bestimme, ob die Fragen mindestens einen (<em>ODER</em>) oder alle (<em>UND</em>) Tags tragen sollen.
            </li>
            <li>
              <form>
                 <p>
                    <label for="fname">Volltext</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld für den Suchbegriff. Dieses Feld muss nicht ausgefüllt werden, um eine Suche durchzuführen.
            </li>
            <li>
              <label for="cars"></label>Zugriffsrechte <br></br>
              <select name="cars" id="cars">
                 <option value="volvo">egal</option>
                 <option value="saab">frei</option>
                 <option value="mercedes">nur registierte MaMpf-NutzerInnen</option>
                 <option value="audi">nur AbonnentInnen</option>
                 <option value="volvo1">gesperrt</option>
                 <option value="saab2">unveröffentlicht</option>
              </select><br></br> Dropdownmenü zur Einstellung der Zugriffsrechte. Zur Auswahl stehen <i>egal</i>, <i>frei</i>, <i>nur registrierte MaMpf-NutzerInnen</i>, <i>nur AbonnentInnen</i>, <i>gesperrt</i> und <i>unveröffentlicht</i>. Diese Eigenschaft kann auf der Seite <a href="/mampf/de/mampf-pages/edit-medium-question" target="_self">„Frage bearbeiten (Medium)“</a> geändert werden.
            </li>
            <li>
              <label for="cars"></label>Anzahl der Antworten <br></br>
              <select name="cars" id="cars">
                 <option value="volvo">egal</option>
                 <option value="saab">1</option>
                 <option value="mercedes">2</option>
                 <option value="audi">3</option>
                 <option value="volvo1">4</option>
                 <option value="saab2">5</option>
                 <option value="mercedes2">6</option>
                 <option value="audi3">>6</option>
              </select><br></br> Dropdownmenü zur Einstellung der Anzahl der Antworten. Zur Auswahl stehen <i>egal</i>, <i>1</i>, <i>2</i>, <i>3</i>, <i>4</i>, <i>5</i>, <i>6</i> und <i>>6</i>.
            </li>
            <li>
              <label for="cars"></label>Treffer pro Seite <br></br>
              <select name="cars" id="cars">
                 <option value="volvo">10</option>
                 <option value="saab">20</option>
                 <option value="mercedes">50</option>
              </select><br></br> Dropdownmenü zur Einstellung der pro Seite angezeigten Treffer. Zur Auswahl stehen <i>10</i>, <i>20</i> und <i>50</i>.
            </li>
            <li>
              <button>Suchen</button> Starte eine Suche unter Verwendung der gewählten Kriterien.
            </li>
            <li>
              <button>Abbrechen</button> Brich die begonnene Aktion ab und schließe die Suche. Dadurch wird keine Assoziation angelegt bzw. geändert.
            </li>
        </ul>
     </td>
  </tr>
</table>

###### Seitennavigation
Wenn es mehr Treffer, als pro Seite angezeigt werden sollen, gibt, stehen folgende Buttons zur Seitennavigation zur Verfügung.

* <button name="button">n</button> Wechsel auf Seite n.
* <button name="button">Nächste</button> bzw. <button name="button">Vorige Wechsel</button> auf die nächste bzw. vorige Seite.
* <button name="button">Letzte</button> bzw. <button name="button">Erste</button> Wechsel auf die letzte bzw. erste Seite.

###### Treffer
Die Treffer werden in einer Tabelle mit den fünf Spalten „Beschreibung“ (Medientitel), „Assoziiert zu“, „Verknüpfte Tags“, „EditorInnen“ und „Zugänglichkeit“ präsentiert. Die Anzahl der Zeilen kann in der Suchmaske festgelegt werden.

![](/img/clicker_treffer.png)

In jeder Zeile gibt es bis zu drei Typen von Bedienelemente. Die Anzahl der Bedienelemente hängt einerseits von den angelegten Assoziationen und andererseits von den Nutzerrechten ab.

* <button>Modul</button>, <button>Veranstaltung</button>, <button>Sitzung</button> bzw. <button>Vortrag</button> Bei Personen mit entsprechenden Editorenrechten führt dies auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-module" target="_self">„Modul bearbeiten“</a>, <a href="/mampf/de/mampf-pages/ed-edit-event-series" target="_self">„Veranstaltung bearbeiten“</a>, <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self">„Vorlesung bearbeiten“</a> (bei Sitzungen) bzw. <a href="/mampf/de/mampf-pages/ed-edit-seminar" target="_self">„Seminar bearbeiten“</a> (bei Vorträgen). Bei Personen ohne entsprechenden Editorenrechte gibt es <button>Modul</button> nicht. Sie gelangen auf die Seite <a href="/mampf/de/mampf-pages/event-series" target="_self">„Veranstaltung“</a>, <a href="/mampf/de/mampf-pages/seminar" target="_self">„Seminar“</a> bzw. <a href="/mampf/de/mampf-pages/lecture" target="_self">„Vorlesung“</a>.
* <button>Begriff</button> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a>.
* <button>Zeile</button> Öffne das Medium in der Vorschau.

Fährt man über eine Zeile, so färbt sie sich orange. Klickt man auf eine Zeile, so färbt sie sich grün und die zugehörige Frage wird in der Vorschau geöffnet. Dann werden weitere Bedienelemente verfügbar. Sobald man eine Zeile durch Anklicken ausgewählt hat, färben sich die Zeilen bei den aktuellen Sucherergebnissen nicht mehr orange, wenn man über sie hovert.
Die Zugänglichkeit der Fragen wird mittels Icons angezeigt. Diese hat jedoch keinen Einfluss darauf, ob die Fragen mit dem Clicker assoziiert werden können. Zur Bedeutung der Icons siehe die [Mediensuche](ed-search-extended#zugänglichkeit).

###### Vorschau
Sobald man eine Frage aus der Treffertabelle angeklickt hat, wird die Frage in der Vorschau angezeigt. Dort gibt es dann den Button <button>Quizfrage assoziieren</button>. Wenn man diesen Button betätigt, wird die Frage mit dem Clicker assoziiert, die Suche geschlossen und im Fach  „Antworten bzw. Frage“ die Ansicht „Bei Assoziierung mit einer Quizfrage“ angezeigt.

![](/img/clicker_vorschau.png)

#### Ergebnis
Im Fach „Ergebnis“ gibt es keine Bedienelemente, solange der Clicker freigeschaltet ist.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_ergebnis_laufend.png" width="800"/>

Wenn der Clicker geschlossen ist, kann mit dem Button <button>Anzeigen</button> bzw.  <button>Verbergen</button> das Ereignis der letzten Befragung ein- bzw. ausgeblendet werden.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_ergebnis.png" width="800"/>

### Unter dem Akkordeon

Unterhalb des Akkordeons gibt es den Button <button>Clicker freischalten</button> bzw. <button>Clicker schließen</button>, mit dem der Clicker geöffnet bzw. geschlossen werden kann.

## Aus Sicht einfacher Nutzer*innen
Öffnet man den Clicker mit den Nutzerlink, so sieht man eine der beiden folgenden Ansichten:

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_stud_multiple.png" width="1000"/> | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_frage_stud.png" width="1000"/> |
|:---: | :---: |
|Nur Antwortmöglichkeiten|Assoziierte Frage|

Nach Auswahl einer Antwort färbt sich diese blau:

| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_stud_multiple_antwort.png" width="1000"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/clicker_frage_stud_antwort.png" width="1000"/> |
|:---: | :---: |
|Nur Antwortmöglichkeiten|Assoziierte Frage|

Wenn der Clicker nicht freigeschaltet ist oder bereits eine Antwortmöglichkeit ausgewählt worden ist, sieht man auf der Nutzerseite lediglich einen blauen Spinner.

## Von dieser Seite aus aufrufbare Seiten
* [Tag bearbeiten](ed-edit-tag)
* [Modul bearbeiten](ed-edit-module) (nur bei Bearbeitungsrechten für das Modul)
* [Veranstaltung bearbeiten](ed-edit-event-series) (nur bei Bearbeitungsrechten für die Veranstaltung)

## Verwandte Seiten
* [Frage bearbeiten](ed-edit-question)
* [Frage bearbeiten (Medium)](ed-edit-medium-question)
