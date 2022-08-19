---
title: Tag anlegen
---

Auf der Seite „Tag anlegen“ können Editor\*innen einen neuen Tag anlegen.

![](/img/tag_anlegen1.png)

## Navigation zu dieser Seite
Die Seite kann über die [Tagsuche](ed-search-extended) mithilfe des Buttons <button>Tag anlegen</button> erreicht werden.

## Bereiche der Seite
Die Seite gliedert sich in zwei große Teilbereiche: die eigentliche Seite und die [Navigationsleiste](nav-bar). Die Bereiche sind exemplarisch in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/tag_anlegen_navbar.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/tag_anlegen_eigentlich.png" height="300"/>  |
|:---: | :---: |
|Navigationsleiste|Eigentliche Seite|

Die eigentliche Seite besteht aus dem Kopf und der Box „Basisdaten“. Diese Bereiche sind in den folgenden Screenshots hervorgehoben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/tag_anlegen_kopf.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/tag_anlegen_basisdaten.png" height="300"/>  |
|:---: | :---: |
|Kopf|Basisdaten|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Nun werden die Bedienelemente der Seite „Tag anlegen“ beschrieben. Dabei werden erst die Bedienelemente im Kopf und anschließend die in der Box „Basisdaten“ behandelt.

### Kopf
In diesem Bereich gibt es bis zu drei Buttons.

* <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self"><button>Speichern</button></a> Übernimm die vorgenommenen Änderungen. Dieser Button erscheint erst, nachdem Änderungen vorgenommen worden sind. Damit der Tag angelegt wird, muss mindestens in einer Sprache ein Titel eingetragen werden. Dabei darf kein Titel eingetragen werden, den es bereits gibt. Nach dem erfolgreichen Anlegen eines Tags erfolgt eine Umleitung auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a>.
* <button>Verwerfen</button> Verwirf die vorgenommenen Änderungen. Dieser Button erscheint erst, nachdem Änderungen vorgenommen worden sind.
* <a href="/mampf/de/mampf-pages/ed-search-extended" target="_self"><button>Tagsuche</button></a> Wechsel zur <a href="/mampf/de/mampf-pages/ed-search-extended" target="_self">Tagsuche</a>.

### Basisdaten
In der Box „Basisdaten“ gibt es Eingabefelder und Dropdownmenüs.

<table>
  <tr>
     <td valign="top">
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/tag_anlegen_basisdaten_cut.png" width="1500" /><br></br><br></br>
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
              Eingabefeld und Dropdown-Menü. Tippe in das Eingabefeld oder scrolle durch die Liste verfügbarer Tags und wähle die aus, die mit der Tag verknüpft werden sollen. Dies kann nachträglich auf der Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a> verändert werden.
           </li>
           <li>
              <form>
                 <p>
                    <label for="fname">Module</label><br></br>
                    <input type="text" id="fname" name="fname"></input><br></br>
                 </p>
              </form>
              Eingabefeld und Dropdown-Menü. Tippe in das Eingabefeld oder scrolle durch die Liste verfügbarer Module und wähle die aus, die mit der Tag verknüpft werden sollen. Dies kann nachträglich auf der Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a> verändert werden. Um einen Tag in einem Modul anzulegen, benötigt man mindestens Editorenrechte in einer Veranstaltung des Moduls.
           </li>
        </ul>
     </td>
  </tr>
</table>

## Von dieser Seite aus aufrufbare Seiten
* [Tagsuche](ed-search-extended)
* [Tag bearbeiten](ed-edit-tag) (Auf diese Seite wird man automatisch nach dem erfolgreichen Erstellen eines Tags umgeleitet.)

## Verwandte Seiten
* [Seite des Begriffs](tag)
* [Tag bearbeiten](ed-edit-tag)
