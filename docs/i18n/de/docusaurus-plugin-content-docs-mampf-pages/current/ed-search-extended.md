---
title: Erweiterte Suche
---

Auf der Seite „Erweiterte Suche“ können Editor\*innen nach Medien, Veranstaltungen, Modulen und Tags suchen. Dazu stehen diverse Filter zur Verfügung.

![](/img/suche_thumb.png)

## Navigation zu dieser Seite
Diese Seite ist nur im Administrationsmodus über <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/magnifying-glass-solid.png" height="12"/></button> in der [Navigationsleiste](nav-bar) erreichbar.

## Bereiche der Seite
Die Seite gliedert sich in zwei große Teilbereiche: die eigentliche Seite und die [Navigationsleiste](nav-bar). Die Bereiche sind exemplarisch in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_navbar_schmal.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_eigentlich_schmal.png" height="300"/>  |
|:---: | :---: |
|Navigationsleiste|Eigentliche Seite|

Oben auf der eigentlichen Seite gibt es eine Registernavigation, mit deren Hilfe zwischen den vier Tabs „Mediensuche“, „Veranstaltungssuche“, „Modulsuche“ und „Tagsuche“ gewechselt werden kann. Unterhalb der Registernavigation wird der gewählte Tab, der aus einer Suchmaske besteht, angezeigt.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_tags_nav.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_tags_maske.png" width="800"/>  |
|:---: | :---: |
|Registernavigation|Tab|

Die vier Tabs sehen folgendermaßen aus:

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_medien.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_veranstaltungen.png" width="800"/>  |
|:---: | :---: |
|Mediensuche|Veranstaltungssuche|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_module.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_tags.png" width="800"/>  |
|Modulsuche|Tagsuche|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Im Folgenden werden sämtliche mögliche Bedienelemente der erweiterten Suche aufgeführt. Dabei wird zunächst die Registernavigation beschrieben, über die die Tabs „Mediensuche“, „Veranstaltungssuche“, „Modulsuche“ und „Tagsuche“ erreicht werden können. Anschließend werden die einzelnen Tabs nacheinander behandelt. Diese bestehen jeweils aus einer Suchmaske am Seitenanfang, der Seitennavigation in der Seitenmitte rechts und den Treffern am Seitenende. Bei der Mediensuche gibt es außerdem eine Vorschau für die Treffer am Seitenende rechts. Bei der Beschreibung wird auch auf Unterschiede zwischen Veranstaltungseditor\*innen, Moduleditor\*innen und Administrator\*innen eingegangen.

### Registernavigation
Die Registernavigation besteht aus vier Buttons, wobei die <button>Mediensuche</button> vorausgewählt ist. Die Buttons führen zum entsprechenden Tab.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_registernav.png" width="500"/>

<ul>
    <li>
       <button>Mediensuche</button> Wechsel zum Tab „Mediensuche“.
    </li>
    <li>
       <button>Veranstaltungssuche</button> Wechsel zum Tab „Veranstaltungssuche“.
    </li>
    <li>
       <button>Modulsuche</button> Wechsel zum Tab „Modulsuche“.
    </li>
    <li>
       <button>Tagsuche</button> Wechsel zum Tab „Tagsuche“.
    </li>
</ul>

### Tab „Mediensuche“
Im Tab „Mediensuche“ gibt es die vier Bereiche „Suchmaske“ (oben), „Seitennavigation“ (in der Seitenmitte rechts), „Treffer“ (unten links) und „Vorschau“ (unten rechts). Diese sind in den folgenden Screenshots eingezeichnet und werden im Folgenden nacheinander beschrieben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_medien_alles_maske.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_medien_alles_nav.png" width="800"/>  |
|:---: | :---: |
|Suchmaske|Seitennavigation|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_medien_alles_treffer.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_medien_alles_vorschau.png" width="800"/>  |
|Treffer|Vorschau|

#### Suchmaske
In der Suchmaske kommen die Bedienelemente Dropdownmenü, Eingabefeld, Checkbox, Radiobutton und Button vor.

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_medien_cut.png" width="5000"/>
        <ul>
          <li>
             Typ / Assoziiert zu / Verknüpfte Tags / EditorInnen<br></br> <form>
                <input type="checkbox" id="ass" name="ass" checked></input>
               <label for="ass"> alle</label>
             </form><br></br> bzw. <br></br><br></br>
              <form>
                  <p>
                     <label for="fname">Typ / Assoziiert zu / Verknüpfte Tags / EditorInnen</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                  </p>
               </form>
               <form>
                   <input type="checkbox" id="news" name="mis"></input>
                   <label for="news"> alle</label>
                </form>
                Checkbox und bei nicht gesetztem Haken auch Eingabefeld mit Dropdownmenü. Im Dropdownmenü können Typ / Assoziationen / verknüpfte Tags / Editor*innen des Mediums ausgewählt werden.
           </li>
           <li>
              Typ bzw. Assoziiert zu bzw. Verknüpfte Tags bzw. EditorInnen <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" height="12"/></button> Entferne den Medientyp bzw. die Veranstaltung oder das Modul bzw. den Begriff bzw. den/die EditorIn aus dem Feld.
           </li>
           <li>
             Assoziiert zu <form>
                <input type="radio" id="de" name="lang" checked></input>
                <label for="vererb"> mit Verebung</label>
                <input type="radio" id="de" name="lang"></input>
                <label for="ohnever"> ohne Vererbung</label>
             </form> Radiobuttons mit den Auswahlmöglichkeiten <em>mit Vererbung</em> und <em>ohne Vererbung</em>. Wenn <em>mit Vererbung</em> ausgewählt ist, werden bei Modulen auch mit Veranstaltungen und Sitzungen verknüpfte Medien und bei Veranstaltungen mit Sitzungen verknüpfte Medien berücksichtigt.
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
              </form> Radiobuttons mit den Auswahlmöglichkeiten <em>ODER</em> und <em>UND</em>. Bestimme, ob die Medien mindestens einen (<em>ODER</em>) oder alle (<em>UND</em>) Tags tragen sollen.
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
              </select><br></br> Dropdownmenü zur Einstellung der Zugriffsrechte. Zur Auswahl stehen <i>egal</i>, <i>frei</i>, <i>nur registrierte MaMpf-NutzerInnen</i>, <i>nur AbonnentInnen</i>, <i>gesperrt</i> und <i>unveröffentlicht</i>. Diese Eigenschaft kann auf der Seite <a href="/mampf/de/mampf-pages/edit-medium" target="_self">„Medium bearbeiten“</a> geändert werden.
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
        </ul>
     </td>
  </tr>
</table>

#### Seitennavigation
Wenn es mehr Treffer, als pro Seite angezeigt werden sollen, gibt, stehen folgende Buttons zur Seitennavigation zur Verfügung.

* <button name="button">n</button> Wechsel auf Seite n.
* <button name="button">Nächste</button> bzw. <button name="button">Vorige Wechsel</button> auf die nächste bzw. vorige Seite.
* <button name="button">Letzte</button> bzw. <button name="button">Erste</button> Wechsel auf die letzte bzw. erste Seite.

#### Treffer
Die Treffer werden in einer Tabelle mit den fünf Spalten „Beschreibung“ (Medientitel), „Assoziiert zu“, „Verknüpfte Tags“, „EditorInnen“ und „Zugänglichkeit“ präsentiert. Die Anzahl der Zeilen kann in der Suchmaske festgelegt werden.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_medien_treffer.png" width="5000"/>

In jeder Zeile gibt es bis zu drei Typen von Bedienelemente. Die Anzahl der Bedienelemente hängt einerseits von den angelegten Assoziationen und andererseits von den Nutzerrechten ab.

* <button>Modul</button>, <button>Veranstaltung</button>, <button>Sitzung</button> bzw. <button>Vortrag</button> Bei Personen mit entsprechenden Editorenrechten führt dies auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-module" target="_self">„Modul bearbeiten“</a>, <a href="/mampf/de/mampf-pages/ed-edit-event-series" target="_self">„Veranstaltung bearbeiten“</a>, <a href="/mampf/de/mampf-pages/ed-edit-lecture" target="_self">„Vorlesung bearbeiten“</a> (bei Sitzungen) bzw. <a href="/mampf/de/mampf-pages/ed-edit-seminar" target="_self">„Seminar bearbeiten“</a> (bei Vorträgen). Bei Personen ohne entsprechenden Editorenrechte gibt es <button>Modul</button> nicht. Sie gelangen auf die Seite <a href="/mampf/de/mampf-pages/event-series" target="_self">„Veranstaltung“</a>, <a href="/mampf/de/mampf-pages/seminar" target="_self">„Seminar“</a> bzw. <a href="/mampf/de/mampf-pages/lecture" target="_self">„Vorlesung“</a>.
* <button>Begriff</button> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a>.
* <button>Zeile</button> Öffne das Medium in der Vorschau.

Fährt man über eine Zeile, so färbt sie sich orange. Klickt man auf eine Zeile, so färbt sie sich grün und das zugehörige Medium wird in der Vorschau geöffnet. Dann werden weitere Bedienelemente verfügbar. Sobald man eine Zeile durch Anklicken ausgewählt hat, färben sich die Zeilen bei den aktuellen Sucherergebnissen nicht mehr orange, wenn man über sie hovert.

##### Zugänglichkeit
Die Zugänglichkeit der Medien wird mittels Icons angezeigt. Die Bedeutung der Icons kann der der nachfolgenden Tabelle entnommen werden:

| Symbol | Bedeutung |  Konsequenz |
| :---: | :---: | :--- |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/public.png" height="12"/> | frei | Alle Personen können über den entsprechenden Link auf das Medium zugreifen. Dazu ist kein MaMpf-Account erforderlich. |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/user-solid.png" height="12"/> | nur registrierte MaMpf-NutzerInnen | Alle Personen mit MaMpf-Account können über den entsprechenden Link auf das Medium zugreifen. Dazu müssen sie sich einloggen. |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/user-plus-solid.png" height="12"/> | nur AbonnentInnen | Alle Personen, die eine Veranstaltung abonniert haben, können über den entsprechenden Link auf das Medium zugreifen. Manche Veranstaltungen können nur mit einem Zugangsschlüssel abonniert werden. |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/lock-solid.png" height="12"/> | gesperrt | Einfache Nutzer*innen können das Medium nicht mehr öfnnen. |
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/eye-solid.png" height="12"/> | unveröffentlicht | Einfache Nutzer*inne können das Medium noch nicht öffnen. |

#### Vorschau
In der Vorschau kommen je nach gewähltem Medium und Rechten von Nutzer\*innen unterschiedliche Bedienelemente vor.

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_medien_vorschau.png" width="1000"/>
        Ohne Editorenrechte für das gewählte Medium:
        <ul>
            <li>
                <a href="/mampf/de/mampf-pages/ed-inspect-medium" target="_self"><button>Medium ansehen</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-inspect-medium" target="_self">„Medium inspizieren“</a>.
            </li>
            <li>
                <a href="/mampf/de/mampf-pages/thyme" target="_self"><button>THymE</button></a> (nur falls es ein Video gibt) Spiele das Video mit <a href="/mampf/de/mampf-pages/thyme" target="_self">THymE</a> ab.
            </li>
        </ul>
     </td>
     <td valign="top">
        Bei Editorenrechten für das gewählte Medium:
        <ul>
            <li>
                <a href="/mampf/de/mampf-pages/edit-medium" target="_self"><button>Medium bearbeiten</button></a> Wechsel zur Seite <a href="/mampf/de/mampf-pages/edit-medium" target="_self">„Medium bearbeiten“</a>.
            </li>
            <li>
                <a href="/mampf/de/mampf-pages/quiz-editor" target="_self"><button>Quiz bearbeiten</button></a> (nur bei Quizzes) Wechsel zum <a href="/mampf/de/mampf-pages/quiz-editor" target="_self">Quizeditor</a>.
            </li>
            <li>
                <a href="/mampf/de/mampf-pages/edit-question" target="_self"><button>Frage bearbeiten</button></a> (nur bei Fragen) Wechsel zur Seite <a href="/mampf/de/mampf-pages/edit-question" target="_self">„Frage bearbeiten“</a>.
            </li>
            <li>
                <a href="/mampf/de/mampf-pages/edit-remark" target="_self"><button>Bemerkung bearbeiten</button></a> (nur bei Erläuterungen) Wechsel zur Seite <a href="/mampf/de/mampf-pages/edit-remark" target="_self">„Bemerkung bearbeiten“</a>.
            </li>
            <li>
                <button>Tags bearbeiten</button> Zeige weitere Bedienelmente zum Bearbeiten der assoziierten Tags an.
            </li>
            <li>
                <a href="/mampf/de/mampf-pages/thyme" target="_self"><button>THymE</button></a> (nur falls es ein Video gibt) Spiele das Video mit <a href="/mampf/de/mampf-pages/thyme" target="_self">THymE</a> ab.
            </li>
            <li>
                <a href="/mampf/de/mampf-pages/thyme-editor" target="_self"><button>Editor</button></a> (nur falls es ein Video gibt) Öffne das Video im <a href="/mampf/de/mampf-pages/thyme-editor" target="_self">THymE-Editor</a>.
            </li>
        </ul>
     </td>
  </tr>
</table>

##### Tags bearbeiten
Für das Bearbeiten von Tags stehen die nachfolgenden Bedienelemente zur Verfügung.

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/tags_bearbeiten_suche.PNG" width="1000"/>
     </td>
     <td>
        <ul>
           <li>
              <form>
                 <p>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld und Dropdown-Menü. Tippe in das Eingabefeld oder scrolle durch die Liste verfügbarer Tags und wähle die aus, die mit dem Medium verknüpft werden sollen.
           </li>      
           <li>
              Verknüpfter Tag <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" height="15"/></button>
           </li> Löse die bestehende Verknüpfung von Medium und Tag auf.
           <li>
              <button>Speichern</button> Übernimm die Änderungen, sofern welche vorgenommen worden sind, und kehre zur vorigen Ansicht zurück.
           </li>
           <li>
              <button>Abbrechen</button> Verwirf die Änderungen, sofern welche vorgenommen worden sind, und kehre zur vorigen Ansicht zurück.
           </li>
        </ul>
     </td>
  </tr>
</table>

### Tab „Veranstaltungssuche“
Im Tab „Veranstaltungssuche“ gibt es die drei Bereiche „Suchmaske“ (oben), „Seitennavigation“ (in der Seitenmitte rechts) und „Treffer“ (unten). Diese sind in den folgenden Screenshots eingezeichnet und werden im Folgenden nacheinander beschrieben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_veranstaltungen_alles_maske.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_veranstaltungen_alles_nav.png" width="800"/>  |
|:---: | :---: |
|Suchmaske|Seitennavigation|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_veranstaltungen_alles_treffer.png" width="800"/> | |
|Treffer||

#### Suchmaske
In der Suchmaske kommen die Bedienelemente Dropdownmenü, Eingabefeld, Checkbox und Button vor.

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_veranstaltungen_cut.png" width="5000"/>
        <ul>
          <li>
             Typ / Semester / Studiengänge / DozentInnen <br></br> <form>
                <input type="checkbox" id="ass" name="ass" checked></input>
               <label for="ass"> alle</label>
             </form><br></br> bzw. <br></br><br></br>
              <form>
                  <p>
                     <label for="fname">Typ / Semester / Studiengänge / DozentInnen </label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                  </p>
               </form>
               <form>
                   <input type="checkbox" id="news" name="mis"></input>
                   <label for="news"> alle</label>
                </form>
                Checkbox und bei nicht gesetztem Haken auch Eingabefeld mit Dropdownmenü. Im Dropdownmenü können Typ / Semester / Studiengänge / DozentInnen der Veranstaltung ausgewählt werden.
           </li>
           <li>
             <label for="cars"></label>Typ <br></br>
             <select name="cars" id="cars">
                <option value="volvo" selected disabled hidden>auswählen</option>
                <option value="saab">Vorlesung</option>
                <option value="mercedes">Seminar</option>
                <option value="audi">Proseminar</option>
                <option value="volvo1">Oberseminar</option>
             </select><br></br> Dropdownmenü zur Einstellung des Veranstaltungstyps. Zur Auswahl stehen <i>Vorlesung</i>, <i>Seminar</i>, <i>Proseminar</i> und <i>Oberseminar</i>. Dabei können mehrere Veranstaltungstypen ausgewählt werden.
           </li>
        </ul>
     </td>
     <td valign="top">
        <ul>
           <li>
             <label for="cars"></label>Semester <br></br>
             <select name="cars" id="cars">
                <option value="volvo" selected disabled hidden>auswählen</option>
                <option value="saab">Semester 1</option>
                <option value="mercedes">Semester 2</option>
                <option value="audi">Semester 3</option>
             </select><br></br> Dropdownmenü zur Einstellung des Semesters. Dabei können mehrere Semester zur Auswahl hinzugefügt werden.
            </li>
            <li>
              <label for="cars"></label>Studiengänge <br></br>
              <select name="cars" id="cars">
                 <option value="volvo" selected disabled hidden>auswählen</option>
                 <option value="saab">Studiengang 1</option>
                 <option value="mercedes">Studiengang 2</option>
                 <option value="audi">Studiengang 3</option>
              </select><br></br> Dropdownmenü zur Einstellung des Studiengangs. Dabei können mehrere Studiengänge zur Auswahl hinzugefügt werden.
            </li>
            <li>
              <label for="cars"></label>DozentInnen <br></br>
              <select name="cars" id="cars">
                 <option value="volvo" selected disabled hidden>auswählen</option>
                 <option value="saab">DozentIn 1</option>
                 <option value="mercedes">DozentInn 2</option>
                 <option value="audi">DozentIn 3</option>
              </select><br></br> Dropdownmenü zur Einstellung der .
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
              <label for="cars"></label>Treffer pro Seite <br></br>
              <select name="cars" id="cars">
                 <option value="volvo">10</option>
                 <option value="saab" selected>20</option>
                 <option value="mercedes">50</option>
              </select><br></br> Dropdownmenü zur Einstellung der pro Seite angezeigten Treffer. Zur Auswahl stehen <i>10</i>, <i>20</i> und <i>50</i>.
            </li>
            <li>
              <button>Suchen</button> Starte eine Suche unter Verwendung der gewählten Kriterien.
            </li>
        </ul>
     </td>
  </tr>
</table>

#### Seitennavigation
Wenn es mehr Treffer, als pro Seite angezeigt werden sollen, gibt, stehen folgende Buttons zur Seitennavigation zur Verfügung.

* <button name="button">n</button> Wechsel auf Seite n.
* <button name="button">Nächste</button> bzw. <button name="button">Vorige Wechsel</button> auf die nächste bzw. vorige Seite.
* <button name="button">Letzte</button> bzw. <button name="button">Erste</button> Wechsel auf die letzte bzw. erste Seite.

#### Treffer
Die Treffer werden in einer Tabelle mit den fünf Spalten „Titel“, „Semester“, „DozentIn“, „Typ“ und „Aktion“ präsentiert. Die Anzahl der Zeilen kann in der Suchmaske festgelegt werden. In jeder Zeile gibt es in der Spalte „Aktion“ je nach vorhandenen Editorenrechten ein oder zwei Bedienelemente.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_veranstaltungen_treffer.png" width="5000"/>

* <a href="/mampf/de/mampf-pages/event-series" target="_self"><button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/eye-solid.png" height="12"/></button></a> Wechsel auf die <a href="/mampf/de/mampf-pages/event-series" target="_self">Seite der Veranstaltung</a>. Falls diese Veranstaltung nicht abonniert ist, schlägt MaMpf vor, ein Abo zu beginnen. (Aufforderung zum Abonnieren -> to do)
* <a href="/mampf/de/mampf-pages/ed-edit-event-series" target="_self"><button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/edit-regular.png" height="12"/></button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-event-series" target="_self">„Veranstaltung bearbeiten“</a>. Dieser Button ist nur bei Veranstaltungseditor*innen vorhanden.

### Tab „Modulsuche“
Im Tab „Modulsuche“ gibt es die drei Bereiche „Suchmaske“ (oben), „Seitennavigation“ (in der Seitenmitte rechts) und „Treffer“ (unten). Diese sind in den folgenden Screenshots eingezeichnet und werden im Folgenden nacheinander beschrieben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_module_alles_maske.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_module_alles_nav.png" width="800"/>  |
|:---: | :---: |
|Suchmaske|Seitennavigation|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_module_alles_treffer.png" width="800"/> | |
|Treffer||

#### Suchmaske
In der Suchmaske kommen die Bedienelemente Dropdownmenü, Eingabefeld, Checkbox und Button vor.

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_module_cut.png" width="5000"/>
        <ul>
          <li>
             EditorInnen / Studiengänge <br></br> <form>
                <input type="checkbox" id="ass" name="ass" checked></input>
               <label for="ass"> alle</label>
             </form><br></br> bzw. <br></br><br></br>
              <form>
                  <p>
                     <label for="fname">EditorInnen / Studiengänge </label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                  </p>
               </form>
               <form>
                   <input type="checkbox" id="news" name="mis"></input>
                   <label for="news"> alle</label>
                </form>
                Checkbox und bei nicht gesetztem Haken auch Eingabefeld mit Dropdownmenü. Im Dropdownmenü können EditorInnen / Studiengänge des Moduls ausgewählt werden.
           </li>
           <li>
             <label for="cars"></label>EditorInnen <br></br>
             <select name="cars" id="cars">
                <option value="volvo" selected disabled hidden>auswählen</option>
                <option value="saab">EditorIn 1</option>
                <option value="mercedes">EditorIn 2</option>
                <option value="audi">EditorIn 3</option>
             </select><br></br> Dropdownmenü zur Einstellung der Moduleditor*innen. Dabei können mehrere Editor*innen zur Auswahl hinzugefügt werden.
           </li>
        </ul>
     </td>
     <td valign="top">
        <ul>
            <li>
              <label for="cars"></label>Studiengänge <br></br>
              <select name="cars" id="cars">
                 <option value="volvo" selected disabled hidden>auswählen</option>
                 <option value="saab">Studiengang 1</option>
                 <option value="mercedes">Studiengang 2</option>
                 <option value="audi">Studiengang 3</option>
              </select><br></br> Dropdownmenü zur Einstellung des Studiengangs. Dabei können mehrere Studiengänge zur Auswahl hinzugefügt werden.
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
              <label for="cars"></label>Treffer pro Seite <br></br>
              <select name="cars" id="cars">
                 <option value="volvo">10</option>
                 <option value="saab" selected>20</option>
                 <option value="mercedes">50</option>
              </select><br></br> Dropdownmenü zur Einstellung der pro Seite angezeigten Treffer. Zur Auswahl stehen <i>10</i>, <i>20</i> und <i>50</i>.
            </li>
            <li>
               <form>
                   <input type="checkbox" id="news" name="mis"></input>
                   <label for="news"> semesterunabhängig </label>
                </form>
             Checkbox zur exklusiven Auswahl semesterunabhgängiger Module.
            </li>
            <li>
              <button>Suchen</button> Starte eine Suche unter Verwendung der gewählten Kriterien.
            </li>
        </ul>
     </td>
  </tr>
</table>

#### Seitennavigation
Wenn es mehr Treffer, als pro Seite angezeigt werden sollen, gibt, stehen folgende Buttons zur Seitennavigation zur Verfügung.

* <button name="button">n</button> Wechsel auf Seite n.
* <button name="button">Nächste</button> bzw. <button name="button">Vorige Wechsel</button> auf die nächste bzw. vorige Seite.
* <button name="button">Letzte</button> bzw. <button name="button">Erste</button> Wechsel auf die letzte bzw. erste Seite.

#### Treffer
Die Treffer werden in einer Tabelle mit den vier Spalten „Titel“, „Division“, „EditorInnen“, und „Aktion“ präsentiert. Die Anzahl der Zeilen kann in der Suchmaske festgelegt werden. In jeder Zeile gibt es in der Spalte „Aktion“ das Bedienelment <a href="/mampf/de/mampf-pages/ed-edit-module" target="_self"><button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/edit-regular.png" height="12"/></button></a>, sofern man über Moduleditorenrechten für dieses Modul verfügt. Das Bedienelement führt auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-module" target="_self">„Modul bearbeiten“</a>.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_module_treffer.png" width="5000"/>

### Tab „Tagsuche“
Im Tab „Tagsuche“ gibt es die drei Bereiche „Suchmaske“ (oben), „Seitennavigation“ (in der Seitenmitte rechts) und „Treffer“ (unten). Diese sind in den folgenden Screenshots eingezeichnet und werden im Folgenden nacheinander beschrieben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_tags_alles_maske.png" width="800"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_tags_alles_nav.png" width="800"/>  |
|:---: | :---: |
|Suchmaske|Seitennavigation|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_tags_alles_treffer.png" width="800"/> | |
|Treffer||

#### Suchmaske
In der Suchmaske kommen die Bedienelemente Dropdownmenü, Eingabefeld, Checkbox und Button vor.

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_tags_cut.png" width="5000"/>
        <ul>
           <li>
              <a href="/mampf/de/mampf-pages/ed-create-tag" target="_self"><button>Tag anlegen</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-create-tag" target="_self">„Tag anlegen“</a>. (to do)
           </li>
           <li>
              <form>
                 <p>
                    <label for="fname">Titel</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld für den Titel des Tags.
           </li>
           <li>
              Module<br></br> <form>
                 <input type="checkbox" id="ass" name="ass" checked></input>
                <label for="ass"> alle</label>
              </form><br></br> bzw. <br></br><br></br>
              <form>
                   <p>
                      <label for="fname">Module</label><br></br>
                     <input type="text" id="fname" name="fname"></input>
                   </p>
                </form>
                <form>
                    <input type="checkbox" id="news" name="mis"></input>
                    <label for="news"> alle</label>
                 </form>
                 Checkbox und bei nicht gesetztem Haken auch Eingabefeld mit Dropdownmenü für die Module, die nach Tags durchsucht werden sollen.
           </li>
        </ul>
     </td>
     <td valign="top">
        <ul>         
            <li>
               <button>von mir editierte Module</button> Trage in das Feld „Module“ alle Module ein, für die die suchende Person als Moduleditor*in eingetragen ist. Dabei wird der Haken der Checkbox „alle“ automatisch entfernt.
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
        </ul>
     </td>
  </tr>
</table>

#### Seitennavigation
Wenn es mehr Treffer, als pro Seite angezeigt werden sollen, gibt, stehen folgende Buttons zur Seitennavigation zur Verfügung.

* <button name="button">n</button> Wechsel auf Seite n.
* <button name="button">Nächste</button> bzw. <button name="button">Vorige Wechsel</button> auf die nächste bzw. vorige Seite.
* <button name="button">Letzte</button> bzw. <button name="button">Erste</button> Wechsel auf die letzte bzw. erste Seite.

#### Treffer
Die Treffer werden in einer Tabelle mit den vier Spalten „Titel“, „Module“, „Verknüpfte Tags“, und „Aktionen“ (-> sollte Aktion heißen) präsentiert. Die Anzahl der Zeilen kann in der Suchmaske festgelegt werden. In der Spalte „Verknüpfte Tags“ können Bedienelemente <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self"><button>Verknüpfter Tag</button></a> vorkommen, die auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a> führen. Außerdem gibt es in jeder Zeile der Spalte „Aktion“ das Bedienelment <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self"><button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/edit-regular.png" height="12"/></button></a>, mit dem man auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a> gelangt.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/suche_tags_treffer.png" width="5000"/>

## Von dieser Seite aus aufrufbare Seiten

* [Medium bearbeiten](edit-medium)
* [Medium inspizieren](ed-inspect-medium)
* [Modul bearbeiten](ed-edit-module)
* [Quizeditor](quiz-editor)
* [Quizerläuterung bearbeiten](edit-remarks)
* [Quizfrage bearbeiten](edit-question)
* [Seminar bearbeiten](ed-edit-seminar)
* [Veranstaltung bearbeiten](ed-edit-event-series)
* [Vorlesung bearbeiten](ed-edit-event-series)
* [Tag anlegen](ed-create-tag)
* [Tag bearbeiten](ed-edit-tag)
* [THymE](tyhme)
* [THymE-Editor](thyme-editor)

## Verwandte Seiten
* [Suchergebnisse](search-results)
