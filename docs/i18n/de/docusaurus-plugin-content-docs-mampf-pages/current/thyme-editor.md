---
title: THymE-Editor
---

Mit dem THymE-Editor können Videos mit einer Gliederung und Referenzen versehen werden. Diese können Nutzer\*innen dann bei der Videobetrachtung mit [THymE](thyme), dem mampf-eigenen Hypermediaplayer, ein- und ausblenden.

![](/img/thyme_editor.png)

## Navigation zu dieser Seite
Der THymE-Editor ist erreichbar über die Bearbeitungsseiten von Medien, zu denen ein Video hochgeladen worden ist. Dafür kommen die Seiten [„Medium bearbeiten“](edit-medium), [„Quiz bearbeiten“](edit-quiz), [„Frage bearbeiten“](edit-question) und [„Erläuterung bearbeiten“](edit-remark) infrage. Gibt es ein Video zum Medium, so befindet sich in der Box „Dokumente“ bei „Video“ der Button <button>Editor</button>, der zum THymE-Editor führt.

## Bereiche der Seite
Der THymE-Editor gliedert sich in fünf Teilbereiche: das Bild mit Steuerleiste, den Aktionsbereich, das Inhaltsverzeichnis, die Referenzen und den Screenshot. Diese Bereich sind in den folgenden Screenshots eingezeichnet.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme_editor_player.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme_editor_aktion.png" height="300"/>  |
|:---: | :---: |
|Bild mit Steuerleiste|Aktionsbereich|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme_editor_inhalt.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme_editor_referenzen.png" height="300"/>  |
|Inhaltsverzeichnis|Referenzen|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme_editor_screenshot.png" height="300"/> | |
|Screenshot||

## Bedienelemente und mögliche Aktionen auf dieser Seite
Im Folgenden werden sämtliche mögliche Bedienelemente der THymE-Editors aufgeführt. Dabei werden die einzelnen Teilbereiche des Editors nacheinander behandelt.

### Bild mit Steuerleiste
Oben links befindet sich die Steuerleiste mit Bild. Dort kann das Video abgespielt und manipuliert werden. Dazu sind die folgenden Bedienelemente verfügbar.

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme_editor_player_cut.png" width="3500"/>
        <ul>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></button> bzw. <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/pause.png" height="9"/></button> Spiele das Video ab bzw. pausiere es.
            </li>
            <li>
                <input type="range" min="1" max="10" class="slider" id="myRange"/> Zeitsuchleiste. Verschiebe den Regler, um die Wiedergabe am gewünschten Punkt fortzusetzen.
            </li>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/replay-10.png" height="18"/></button> Spule das Video zehn Sekunden zurück.
            </li>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/replay-5.png" height="18"/></button> Spule das Video fünf Sekunden zurück.
            </li>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/keyboard-arrow-left_2.png" height="18"/></button> Springe zum vorherigen Gliederungspunkt.
            </li>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/keyboard-arrow-right_2.png" height="18"/></button> Springe zum nächsten Gliederungspunkt.
            </li>
        </ul>
     </td>
     <td>
        <ul>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/forward-5.png" height="18"/></button> Spule das Video fünf Sekunden vor.
            </li>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/forward-10.png" height="18"/></button> Spule das Video zehn Sekunden vor.
            </li>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/playlist-add.png" height="12"/></button> Lege einen neuen Eintrag im Inhaltsverzeichnis an. Infolgedessen öffnet sich im Aktionsbereich die Bearbeitungsansicht „Eintrag anlegen“.
            </li>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="10"/></button> Lege eine neue Referenz an. Infolgedessen öffnet sich im Aktionsbereich die Bearbeitungsansicht „Referenz anlegen“.
            </li>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/add-a-photo.png" height="14"/></button> Speichere das aktuelle Videobild und verwende dieses als Vorschaubild. Das Bild wird daraufhin in der Box „Screenshot“ angezeigt und kann dort gelöscht werden.
            </li>
            <li>
                <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/volume-up.png" height="12"/></button> bzw. <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/volume-off.png" height="12"/></button> Schalte den Ton aus bzw. ein.
            </li>
            <li>
                <input type="range" min="1" max="10" class="slider" id="myRange" height="5" width="5"/> Lautstärkeregler. Verschiebe den Regler, um die Lautstärke anzupassen.
            </li>
        </ul>
     </td>
  </tr>
</table>

### Aktionsbereich
Der Aktionsbereich befindet sich oben rechts. Er gliedert sich in einen Kopf und einen Rumpf. Im Kopf gibt es immer drei Buttons zur Navigation. Im Rumpf können Einträge des Inhaltsverzeichnisses und Referenzen angelegt und bearbeitet werden. Dieses Inhaltsverzeichnis wird auf der [Medienseite](medium) und bei Betrachtung des Videos im [THymE-Player](thyme) angezeigt, die Referenzen nur im THymE-Player. In Vorlesungen erscheint das Inhaltsverzeichnis bei Lektionen zudem auch auf der [Seite der assoziierten Sitzung](session). Das Inhaltsverzeichnis wird auf allen Seiten immer vollständig angezeigt und im THymE-Player ist außerdem der derzeit abgespielte Eintrag hellblau eingefärbt. Die Referenzen hingegen werden im THymE-Player erst bei Erreichen ihrer Zeitmarke eingeblendet und sind dann zehn Sekunden lang orange.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/inhalt_thyme.PNG" width="1000"/> |
|:---: |
|Gliederung und Referenzen im THmyE-Player |
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/inhalt_medienseite.PNG" width="1000"/> |
|Gliederung auf der Medienseite (in ähnlicher Weise auch auf der Sitzungsseite)|

Der Aktionsbereich ist leer, bis eine Aktion begonnen wird. Dann erscheint je nach Auswahl die Aktion „Eintrag anlegen“, „Referenz anlegen“, „Eintrag bearbeiten“ oder „Referenz bearbeiten“. Um eine Aktion zu starten, klickt man auf <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/playlist-add.png" height="12"/></button> oder <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="10"/></button> in der Steuerleiste oder einen bereits vorhandenen <button>Eintrag</button> im Inhaltsverzeichnis oder bei den Referenzen.

![](/img/thyme_editor_eintrag_bearbeiten.png)

#### Kopf
Im Kopf gibt es rechts die folgenden drei Buttons.
* <a href="/mampf/de/docs/thyme" target="_self"><button>THymE-Vorschau</button></a> Wechsel zum <a href="/mampf/de/docs/thyme" target="_self">THymE-Player</a>, um das Video aus Nutzersicht zu betrachten.
* <button>zurück zum Medium</button> Wechsel zur Bearbeitungsseite des Mediums, zu dem das Video gehört. Dabei handelt es sich entweder um die Seite <a href="/mampf/de/docs/edit-medium-remark" target="_self">„Erläuterung bearbeiten“ (Medium)</a>, <a href="/mampf/de/docs/edit-medium-question" target="_self">„Frage bearbeiten“ (Medium)</a>, <a href="/mampf/de/docs/edit-medium" target="_self">„Medium bearbeiten“</a> oder <a href="/mampf/de/docs/edit-quiz" target="_self">„Quiz bearbeiten“</a>.   
* <button>zur Veranstaltung</button> Wechsel zur <a href="/mampf/de/docs/ed-edit-event-series" target="_self">Bearbeitungsseite der Veranstaltung</a> (bei Editor*innen) bzw. zur <a href="/mampf/de/docs/event-series" target="_self">Veranstaltungsseite</a> (bei Vortragenden).

#### Rumpf
Im Rumpf können die Aktionen „Eintrag anlegen“, „Referenz anlegen“, „Eintrag bearbeiten“ und „Referenz bearbeiten“ ausgeführt werden. Wenn keine Aktion ausgewählt ist, wird in diesem Bereich nichts angezeigt. Nachdem eine Aktion durch Speichern oder Abbruch beendet worden ist, verschwinden alle Elemente aus diesem Bereich wieder. Im Folgenden werden die je nach Aktion verfügbaren Bedienelemente beschrieben.

##### Eintrag anlegen oder bearbeiten
Da sich die Bedienelemente der Aktionen „Eintrag anlegen“ und „Eintrag bearbeiten“ nur geringfügig unterscheiden, werden sie gemeinsam vorgestellt. Um die Aktion „Eintrag anlegen“ zu beginnen, klickt man auf <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/playlist-add.png" height="12"/></button> in der Steuerleiste. Zum Starten der Aktion „Eintrag bearbeiten“ klickt man auf einen bereits vorhandenen Eintrag im Inhaltsverzeichnis. Im Aktionsbereich kommen dann die nun aufgeführten Bedienelemente vor. Dabei ist zu beachten, dass der Button <button>Löschen</button> nur bei der Aktion „Eintrag bearbeiten“ auftritt. Außerdem gibt es das Dropdown-Menü „Abschnitt“ nur in Vorlesungen bei Lektionen, die zu einer Sitzung assoziiert sind, zu der wiederum mindestens ein Abschnitt assoziiert ist.

![](/img/thyme_editor_eintrag_bearbeiten.png)

* <form>
     <p>
        <label for="fname">Startzeit </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für die Startzeit des Gliederungspunktes. Beim Anlegen eines Eintrag steht hier zunächst die Zeit, an der sich die Zeitsuchleiste beim Anklicken von <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/playlist-add.png" height="12"/></button> befand. Gib die gewünschte Startzeit manuell ein.
* Startzeit <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/timer_black.png" height="16"/></button> Übernimm die aktuelle Zeit aus der Zeitsuchleiste als Startzeit für den Gliederungseintrag. Wenn das Video in dem Moment, in dem der Button angeklickt wird, läuft, wird es dadurch pausiert.
* Typ <label for="cars"></label>
  <select name="cars" id="cars">
     <option value="1">Abbildung</option>
     <option value="2">Abschnitt</option>
     <option value="3">Algorithmus</option>
     <option value="4">Anmerkung</option>
     <option value="5">Aufgabe</option>
     <option value="6">Beispiel</option>
     <option value="7">Bemerkung</option>
     <option value="8">Definition</option>
     <option value="9">Folgerung</option>
     <option value="10">Gleichung</option>
     <option value="11">Hilfssatz</option>
     <option value="12">Kapitel</option>
     <option value="13">Korollar</option>
     <option value="14">Lemma</option>
     <option value="15">Markierung</option>
     <option value="16">Proposition</option>
     <option value="17">Satz</option>
     <option value="18">Theorem</option>
     <option value="19">Unterabschnitt</option>
  </select><br></br> Dropdown-Menü zur Festlegung des Typs. Zur Auswahl stehen <i>Abbildung</i>, <i>Abschnitt</i>, <i>Algorithmus</i>, <i>Anmerkung</i>, <i>Aufgabe</i>, <i>Beispiel</i>, <i>Bemerkung</i>, <i>Definition</i>, <i>Folgerung</i>, <i>Gleichung</i>, <i>Hilfssatz</i>, <i>Kapitel</i>, <i>Korollar</i>, <i>Lemma</i>, <i>Markierung</i>, <i>Proposition</i>, <i>Satz</i>, <i>Theorem</i> und <i>Unterabschnitt</i>.
* Abschnitt <label for="cars"></label>
  <select name="cars" id="cars">
     <option value="a">Assoziierter Abschnitt 1 x</option>
     <option value="b">Assoziierter Abschnitt 2 x</option>
     <option value="c">Assoziierter Abschnitt 3 x</option>
  </select><br></br> Dropdown-Menü mit Eingabefeld zur Auswahl eines assoziierten Abschnitts. Dieses Bedienelement ist nur in Vorlesungen bei Lektionen, die zu einer Sitzung assoziiert sind, vorhanden. Zur Sitzung muss außerdem mindestens ein Abschnitt assoziiert sein. Im Dropdown-Menü werden alle zur Sitzung assoziierten Abschnitte aufgeführt. Im Menü kann höchstens ein Abschnitt ausgewählt werden. Um die Assoziation zwischen Abschnitt und Eintrag auzuheben, klickt man auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" height="12"/></button>.
* <form>
     <p>
        <label for="fname">Nummer </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für die Nummer. Diese wird zusammen mit dem Typ angezeigt. Mit Ausnahme der Markierung können alle Typen mit einer Nummer versehen werden. Dieses Feld ist optional.
* <form><input type="checkbox" id="not" name="ev"></input>
        <label for="not"> verstecken</label></form>
  Checkbox. Setze durch Anklicken einen Haken, um den Eintrag zu verstecken. Er wird dann nicht beim Abspielen des Videos mit THymE in der Gliederung angezeigt. Referenzen auf den Eintrag sind aber weiterhin möglich.
* <form>
     <p>
        <label for="fname">Beschreibung bzw. Titel (bei Abschnitt und Kapitel) </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für die Beschreibung bzw. den Titel des Eintrags. Dieses Feld ist optional.
* <form>
     <p>
        <label for="fname">Seite im pdf </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für die Seitenzahl. Mithilfe der Buttons <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/angle-up-solid.png" height="12"/></button> und <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/angle-down-solid.png" height="12"/></button> kann die Seitenzahl um Eins herauf- bzw. herabgesetzt werden. Dieses Feld ist nur vorhanden, wenn es ein PDF gibt, und optional.
* <button>pdf ansehen</button> Öffne das PDF. Dieser Button ist nur verfügbar, wenn zum Medium ein PDF hinzugefügt worden ist.
* <button>Speichern</button> Speichere den Eintrag und beende die Aktion.
* <button>Abbrechen</button> Beende die Aktion, ohne den Eintrag zu speichern.
* <button>Löschen</button> (nicht beim Anlegen, nur beim Bearbeiten) Lösche den Eintrag. Dieser Button ist nur beim Bearbeiten eines Eintrags vorhanden. Beim Anlegen führt ein Abbruch dazu, dass der Eintrag nicht angelegt wird.

Bei Betrachtung des Videos im THymE-Player wird der aktuelle Eintrag blau eingefärbt, alle anderen Einträge sind weiß. Im THymE-Editor sowie auf der Medien- und Sitzungsseite werden für die verschiedenen Typen Farben verwendet. Diese und weitere Besonderheiten der Darstellung sind in der nun folgenden Tabelle zusammengefasst.

| Typ | Bezeichung des Eingabefelds | Vergabe einer Nummer möglich | In der Gliederung verwendete Kurzform | In der Gliederung verwendete Farbe |
|:---: | :---: | :---:| :---:| :---:|
| Abbildung | Beschreibung | ja | Abb. Nr. | blau |
| Abschnitt | Titel | ja | § Nr. (ohne Nr. leer) | keine |
| Algorithmus | Beschreibung | ja | Alg. Nr. | grün |
| Anmerkung | Beschreibung | ja | Anm. Nr. | blau |
| Aufgabe | Beschreibung | ja | Aufg. Nr. | blau |
| Beispiel | Beschreibung | ja | Bsp. Nr. | blau |
| Bemerkung | Beschreibung | ja | Bem. Nr. | grün |
| Definition | Beschreibung | ja | Def. Nr. | blau |
| Folgerung | Beschreibung | ja | Folg. Nr. | grün |
| Gleichung | Beschreibung | ja | Gl. Nr. | blau |
| Hilfssatz | Beschreibung  | ja | Hilfssatz Nr. | grün |
| Kapitel | Titel (vor dem Speichern, danach: Beschreibung) | ja | Kap. Nr. | farblos |
| Korollar | Beschreibung | ja | Kor. Nr. | grün |
| Lemma | Beschreibung | ja | Lemma Nr. | grün |
| Markierung | Beschreibung | nein | leer | farblos |
| Proposition | Beschreibung | ja | Prop. Nr. | grün |
| Satz | Beschreibung | ja | Satz Nr. | grün |
| Theorem | Beschreibung | ja | Thm. Nr. | grün |
| Unterabschnitt | Beschreibung (warum nicht Titel?) | ja | Unterabschnitt Nr. | farblos |

##### Referenz anlegen oder bearbeiten
Da sich die Bedienelemente von „Referenz bearbeiten“ und der finalen Ansicht von „Referenz anlegen“  nur geringfügig unterscheiden (bei „Referenz bearbeiten“ gibt es einen <button>Löschen</button>-Button, bei „Referenz anlegen“ gibt es ihn nicht), werden die Bedienelemente von „Referenz bearbeiten“ nicht eigens aufgeführt. Um die Aktion „Referenz anlegen“ zu beginnen, klickt man auf <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="10"/></button> in der Steuerleiste. Zum Starten der Aktion „Referenz bearbeiten“ klickt man auf eine bereits vorhandene Referenz.

![](/img/thyme_editor_referenz_bearbeiten.png)

Mithilfe des THymE-Editors können zwei Typen von Referenzen zu einem Video hinzugefügt und bearbeitet werden: interne und externe. Zwischen diesen gibt es Unterschiede hinsichtlich der Bedienelemente. Beim Anlegen einer Referenz sind zunächst nicht alle Bedienelemente verfügbar. Bei beiden Referenztypen führt erst die Auswahl eines Eintrags dazu, dass alle Bedienelemente angezeigt werden. Im Folgenden wird  erläutert, wie man zur finalen Ansicht beim Anlegen von internen und externen Referenzen gelangt. Anschließend werden die Bedienelemente der finalen Ansicht beschrieben, da in dieser alle möglichen Bedienelemente des jeweiligen Referenztyps vorkommen.

###### Interne Referenzen
Nachdem die Aktion „Referenz anlegen“ begonnen worden ist, wird im Aktionsbereich Folgendes angezeigt:

![](/img/referenz_default.png)

Die standardmäßige Voreinstellung im Dropdown-Menü „Vorauswahl“ richtet sich nach der Ebene, auf der das bearbeitete Medium angesiedelt ist. Bei Medien auf Veranstaltungsebene ist die Veranstaltung vorausgewählt, bei Medien auf Modulebene sind es alle Veranstaltungen des Moduls. Im Dropdown-Menü „Eintrag“ kann aus allen Medien und Gliederungseinträgen der gewählten Veranstaltung(en) ein Eintrag ausgewählt werden. Infolgedessen sind alle möglichen Bedienelemente verfügbar.

![](/img/thyme_editor_neue_referenz.png)

* <form>
     <p>
        <label for="fname">Startzeit </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für die Startzeit der Referenz. Beim Anlegen der Referenz steht hier zunächst die Zeit, an der sich die Zeitsuchleiste beim Anklicken von <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="10"/></button> befand. Gib die gewünschte Startzeit manuell ein.
* Startzeit <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/timer_black.png" height="16"/></button> Übernimm die aktuelle Zeit aus der Zeitsuchleiste als Startzeit für die Referenz. Wenn das Video in dem Moment, in dem der Button angeklickt wird, läuft, wird es dadurch pausiert.
* <form>
     <p>
        <label for="fname">Endzeit </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für die Endzeit der Referenz. Beim Anlegen der Referenz steht hier zunächst eine Minute nach der Zeit, an der sich die Zeitsuchleiste beim Anklicken von <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="10"/></button> befand. Gib die gewünschte Endzeit manuell ein.
* Endzeit <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/timer_black.png" height="16"/></button> Übernimm die aktuelle Zeit aus der Zeitsuchleiste als Endzeit für die Referenz. Wenn das Video in dem Moment, in dem der Button angeklickt wird, läuft, wird es dadurch pausiert.
* Vorauswahl <label for="cars"></label>
  <select name="cars" id="cars">
     <option value="a">Veranstaltung (alle) x</option>
     <option value="b">Veranstaltung x</option>
     <option value="c">extern (alle) x</option>
  </select><br></br> Dropdown-Menü mit Eingabefeld zur Auswahl einer Veranstaltung, aller Veranstaltungen eines Moduls oder aller externer Referenzen. Um die Auswahl auzuheben, klickt man auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" height="12"/></button>.
* Eintrag <label for="cars"></label>
  <select name="cars" id="cars">
     <option value="a">Medium x</option>
     <option value="b">Gliederungseintrag x</option>
  </select><br></br> Dropdown-Menü mit Eingabefeld zur Auswahl eines Mediums oder eines Gliederungseintrags. Um die Auswahl auzuheben, klickt man auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" height="12"/></button>.
* Medien: <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/file-pdf-regular.png" height="16"/></button>, <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/film-solid.png" height="12"/></button> und/oder <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/videogame-asset.png" height="12"/></button> Öffne das Medium, auf das verwiesen wird.
* zusätzliches Medium: <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/file-pdf-regular.png" height="16"/></button> (nur bei importierten Einträgen, d.h. Einträge aus Skripten, die mit dem MaMpf-Paket getext und deren Gliederungen von MaMpf importiert worden sind) Öffne das Skript, aus dem der Eintrag stammt.
* <form>
     <p>
        <label for="fname">Erläuterung </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für eine näherere Erläuterung der Referenz.
* <button>Speichern</button> Speichere die Referenz und beende die Aktion.
* <button>Abbrechen</button> Beende die Aktion, ohne die Referenz zu speichern. Bei neu angelegten Referenzen führt dies dazu, dass keine neue Referenz angelegt wird. Bei bereits vorhandenen Referenzen werden die vorgenommenen Änderungen nicht übernommen.
* <button>Löschen</button> (nicht beim Anlegen, nur beim Bearbeiten) Lösche die Referenz. Dieser Button ist nur beim Bearbeiten einer Referenz vorhanden. Beim Anlegen führt ein Abbruch dazu, dass die Referenz nicht angelegt wird.

###### Externe Referenzen
Nachdem die Aktion „Referenz anlegen“ begonnen worden ist, wird im Aktionsbereich Folgendes angezeigt:

![](/img/referenz_default.png)

Die standardmäßige Voreinstellung im Dropdown-Menü „Vorauswahl“ richtet sich nach der Ebene, auf der das bearbeitete Medium angesiedelt ist. Bei Medien auf Veranstaltungsebene ist die Veranstaltung vorausgewählt, bei Medien auf Modulebene sind es alle Veranstaltungen des Moduls. Um eine externe Referenz im Video anzulegen, wählt man im Dropdown-Menü „Vorauswahl“ die Option „extern (alle)“. Daraufhin ändert sich die Nutzeroberfläche und sieht nun folgendermaßen aus:

![](/img/thyme_editor_referenz_anlegen.png)

Nun kann entweder ein bereits vorhandener Eintrag im Dropdown-Menü „Eintrag“ ausgewählt oder über <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/note-add.png" height="12"/></button> ein neuer Eintrag angelegt werden. Zum Anlegen eines neuen Eintrags öffnet sich das folgende Formular:  

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme_editor_externe_referenz.png" width="3500"/> <br></br><br></br>
        <ul>
             <li> <button>x</button> Schließe das Fenster, ohne den neuen Eintrag anzulegen.
             </li>
             <li><form>
                  <p>
                     <label for="fname">Titel </label>
                     <input type="text" id="fname" name="fname"></input>
                 </p>
                  </form> Eingabefeld für den Titel des neuen Eintrags.
             </li>
        </ul>
     </td>
     <td>
        <ul>
            <li><form>
                   <p>
                       <label for="fname">Link </label>
                       <input type="text" id="fname" name="fname"></input>
                    </p>
                 </form> Eingabefeld für den Link.
            </li>
            <li>
                Link <button>Test</button> Öffne den Link in einem neuen Tab.
            </li>
            <li><form>
                 <p>
                    <label for="fname">Erläuterung </label>
                    <input type="text" id="fname" name="fname"></input>
                 </p>
                 </form> Eingabefeld für eine näherere Erläuterung des neuen Eintrags.
            </li>
            <li>
                <button>Speichern</button> Speichere den neuen Eintrag und schließe das Fenster.
            </li>
            <li>
                <button>Abbrechen</button> Brich ab, ohne den Eintrag zu speichern, und schließe das Fenster.
            </li>
        </ul>
     </td>
  </tr>
</table>

Nachdem ein bereits vorhandener Eintrag im Dropdown-Menü „Eintrag“ ausgewählt oder mithilfe von obigem Formular ein neuer Eintrag angelegt worden ist, sind alle Bedienelemente verfügar:

![](/img/thyme_editor_externe_referenz_bereits_verwendet.png)

* <form>
     <p>
        <label for="fname">Startzeit </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für die Startzeit der Referenz. Beim Anlegen der Referenz steht hier zunächst die Zeit, an der sich die Zeitsuchleiste beim Anklicken von <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="10"/></button> befand. Gib die gewünschte Startzeit manuell ein.
* Startzeit <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/timer_black.png" height="16"/></button> Übernimm die aktuelle Zeit aus der Zeitsuchleiste als Startzeit für die Referenz. Wenn das Video in dem Moment, in dem der Button angeklickt wird, läuft, wird es dadurch pausiert.
* <form>
     <p>
        <label for="fname">Endzeit </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für die Endzeit der Referenz. Beim Anlegen der Referenz steht hier zunächst eine Minute nach der Zeit, an der sich die Zeitsuchleiste beim Anklicken von <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="10"/></button> befand. Gib die gewünschte Endzeit manuell ein.
* Endzeit <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/timer_black.png" height="16"/></button> Übernimm die aktuelle Zeit aus der Zeitsuchleiste als Endzeit für die Referenz. Wenn das Video in dem Moment, in dem der Button angeklickt wird, läuft, wird es dadurch pausiert.
* Vorauswahl <label for="cars"></label>
  <select name="cars" id="cars">
     <option value="c">extern (alle) x</option>
     <option value="a">Veranstaltung (alle) x</option>
     <option value="b">Veranstaltung x</option>
  </select><br></br> Dropdown-Menü mit Eingabefeld zur Auswahl einer Veranstaltung, aller Veranstaltungen eines Moduls oder aller externer Referenzen. Um die Auswahl auzuheben, klickt man auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/xmark-solid.png" height="12"/></button>.
* Vorauswahl <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/note-add.png" height="12"/></button> Öffne das Formular zum Anlegen eines neuen Eintrags.
* Eintrag <label for="cars"></label>
  <select name="cars" id="cars">
     <option value="a">Externe Referenz 1</option>
     <option value="b">Externe Referenz 2</option>
     <option value="c">Externe Referenz 3</option>
  </select><br></br> Dropdown-Menü mit Eingabefeld zur Auswahl eines bereits vorhandenen Eintrags.
* <form>
     <p>
        <label for="fname">Titel </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für den Titel der Referenz.
*  <form>
     <p>
        <label for="fname">Link </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für den Link.
* Link <button>Test</button> Öffne den Link in einem neuen Tab.
* <form>
     <p>
        <label for="fname">Erläuterung </label>
        <input type="text" id="fname" name="fname"></input>
     </p>
  </form> Eingabefeld für eine näherere Erläuterung der Referenz.
* <button>Speichern</button> Speichere die Referenz und beende die Aktion.
* <button>Abbrechen</button> Beende die Aktion, ohne die Referenz zu speichern. Bei neu angelegten Referenzen führt dies dazu, dass keine neue Referenz angelegt wird. Bei bereits vorhandenen Referenzen werden die vorgenommenen Änderungen nicht übernommen.
* <button>Löschen</button> (nicht beim Anlegen, nur beim Bearbeiten) Lösche die Referenz. Dieser Button ist nur beim Bearbeiten einer Referenz vorhanden. Beim Anlegen führt ein Abbruch dazu, dass die Referenz nicht angelegt wird.

Die gelb umkreisten Ausrufzeichen kommen nur bei Referenzen vor, die bereits an anderer Stelle verwendet werden. Änderungen an auf diese Weise gekennzeichneten Feldern sind global, d.h. sie werden überall, wo die Referenz gesetzt ist, realisiert.

### Gliederung
Im Bereich „Gliederung“ werden alle bereits angelegten Einträge des Inhaltsvereichnisses angezeigt. Jeder Eintrag  ist ein Bedienelement. Wenn man einen <button>Eintrag</button> anklickt, öffnet sich dieser zur Bearbeitung im Aktionsbereich. Außerdem springt das Video an die Stelle, an der Eintrag beginnt.

![](/img/thyme_editor_inhalt_cut.png)

### Referenzen
Im Bereich „Referenz“ werden alle bereits angelegten Referenzen angezeigt. Jede Referenz ist ein Bedienelement. Wenn man eine <button>Referenz</button> anklickt, öffnet sich diese zur Bearbeitung im Aktionsbereich. Außerdem springt das Video an die Stelle, an der referenziert wird.

![](/img/thyme_editor_referenzen_cut.png)

### Screenshot
Im Bereich „Screenshot“ wird ein Screenshot angezeigt, sofern mithilfe <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/add-a-photo.png" height="14"/></button> in der Steuerleiste des Bildes ein Screenshot angefertigt worden ist. Falls es einen Screenshot gibt, so steht in diesem Bereich genau ein Bedienelement zur Verfügung. Dabei handelt es sich um den Button <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/trash-alt-solid.png" height="12"/></button> zum Löschen des Screenshots.

![](/img/thyme_editor_screenshot_cut.png)

## Von dieser Seite aus aufrufbare Seiten
### Bei Vortragenden und Editor*innen
* [Erläuterung bearbeiten](edit-medium-remark) (Medium)
* [Frage bearbeiten](edit-medium-question) (Medium)
* [Medium bearbeiten](edit-medium)
* [Quiz bearbeiten](edit-quiz)
* [THymE-Player](thyme)

### Nur bei Vortragenden
* [Seminar](seminar)
* [Veranstaltung](event-series)
* [Vorlesung](lecture)

### Nur bei Editor*innen

* [Veranstaltung bearbeiten](ed-edit-event-series)
* [Seminar bearbeiten](ed-edit-seminar)
* [Vorlesung bearbeiten](ed-edit-lecture)

## Verwandte Seiten

* [Erläuterung bearbeiten](edit-medium-remark) (Medium)
* [Frage bearbeiten](edit-medium-question) (Medium)
* [Medium bearbeiten](edit-medium)
* [Quiz bearbeiten](edit-quiz)
* [THymE-Player](thyme)
