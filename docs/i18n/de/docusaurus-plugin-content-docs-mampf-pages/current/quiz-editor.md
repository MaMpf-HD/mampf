---
title: Quizeditor
---

Mit dem Quizeditor kann man den Quizgraphen bearbeiten, indem man Ecken und Kanten anlegt oder verändert. Ferner kann man den Schwierigkeitsgrad des Quiz' festlegen und das Quiz linearisieren.

![](/img/quizeditor_complete_no_navbar.png)

## Navigation zu dieser Seite
Den Quizeditor erreicht man über die Seite [„Quiz bearbeiten“](edit-quiz). Dort klickt man auf <button>Bearbeiten</button> in der Box „Dokumente“.

## Bereiche der Seite
Die Seite „Quizeditor“ gliedert sich in zwei Teilbereiche: die eigentliche Seite „Quizeditor“ und die [Navigationsleiste](nav-bar.md). Die Bereiche sind exemplarisch in den folgenden Screenshots eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_complete_navbar.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_complete_eigentliche_seite.png" height="300"/>  |
|:---: | :---: |
|Navigationsleiste|Eigentliche Seite|

Die eigentliche Seite besteht aus dem Kopf, der Vorschau und den Boxen „Graph“ und „Ecke anlegen“ bzw. „Verzweigung“. Diese Bereiche sind in den folgenden Screenshots hervorgehoben.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_complete_kopf.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_complete_graph.png" height="300"/>  |
|:---: | :---: |
|Kopf|Graph|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_complete_vorschau.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_complete_ecke_anlegen.png" height="300"/>  |
|Vorschau|Ecke anlegen|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_verzweigung_green.png" height="300"/> | |
|Verzweigung||

Dabei ist zu beachten, dass die Box „Ecke anlegen“ bzw. die „Verzweigung“ nur vorhanden ist, wenn zuvor auf den entsprechenden Button geklickt worden ist. Die Vorschau wird nur angezeigt, wenn eine Ecke ausgewählt ist.

Es gibt unterschiedliche Ansichten des Quizgraphen. Der Quizgraph zeigt zunächst die Ausgangsansicht.

![](/img/quizeditor_graph.png)

Von dieser gelangt man weiter zu den Ansichten „Erläuterung“, „Frage“, „Kante“, „Schwierigkeitsgrad“ und „Start-Ecke“.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_unverzweigte_ecke.png" /> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_verweigte_ecke.png" />  |
|:---: | :---: |
|Ansicht „Erläuterung“|Ansicht „Frage“|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_kante.png" /> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_schwierigkeitsgrad.png" />  |
|Ansicht „Kante“|Ansicht „Schwierigkeitsgrad“|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_startecke.png" /> | |
|Ansicht „Start-Ecke“| |

Die Bedienansichten „Frage“ und „Erläuterung“ führen außerdem zur Ansicht „Standard-Ziel“.

![](/img/quizeditor_zielecke.png)

## Bedienelemente und mögliche Aktionen auf dieser Seite
In den Bereichen Kopf, Graph, Verzweigungen und der Box „Ecke anlegen“ kommen diverse Bedienelemente vor. Die Bedienelemente im Bereich Kopf sind immer gleich. Die Bedienelemente beim Quizgraphen hängen hingegen von der ausgewählten Ansicht ab. Das nun folgende Schaubild gibt eine Übersicht über die Erreichbarkeit und die Navigationselemente der verschiedenen Ansichten bzw. Elemente.

<a href="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_schaubild.png"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_schaubild.png" width="1000"/></a>

Sämtliche Bedienelemente werden nun bereichsweise bzw. ansichtsweise beschrieben.

### Kopf
Im Kopfbereich gibt es zwei Bedienelemente.
* <a href="/mampf/de/mampf-pages/edit-quiz" target="_self"><button name="button">zum Medium</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/edit-quiz" target="_self">„Quiz bearbeiten“</a>.
* <button name="button">Quiz spielen</button> Öffne das Quiz in der Nutzeransicht. Dazu muss der Quizgraph strukturell fehlerfrei sein, siehe dazu den gleichnamigen Abschnitt.

### Graph
In der Box „Quizgraph“ gibt es sowohl Bedienelemente im Graphen als auch rechts neben der Überschrift. Falls entsprechende Ecken und Kanten angelegt worden sind, stehen im Graphen Bedienelemente zur Verfügung. Zum Anlegen von Ecken siehe die Box „Ecke anlegen“. Zum Anlegen von Kanten siehe <button>Start-Ecke</button> in der Ausgangsansicht, <button>Standard-Ziel</button> in den Bedienansichten „Erläuterung“ und „Frage“ sowie <button>Verzweigung</button> in der Bedienansicht „Frage“. Mögliche Bedienelemente im Graphen sind:

* <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/square-regular.png" height="12"/></button> Wechsel zur Bedienansicht „Erläuterung“. Dort kann die Ecke bearbeitet oder gelöscht werden. Außerdem wird die ausgewählte Erläuterung rechts neben dem Quizgraphen in der Vorschau angezeigt.
* <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-regular.png" height="12"/></button> Wechsel zur Bedienansicht „Frage“. Dort kann die Ecke bearbeitet oder gelöscht werden. Außerdem wird die ausgewählte Frage rechts neben dem Quizgraphen in der Vorschau angezeigt.
* <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/edge2.png" height="12"/></button> Wechsel zur Bedienansicht „Kante“. Dort kann die ausgewählte Kante gelöscht werden.

Die Bedienelemente im Graphen können verwendet werden, sofern nicht bestimmte Bearbeitungsprozesse im Gang sind. Diese Prozesse können in den diversen Ansichten des Quizgraphen gestartet werden. Darauf wird in den jeweiligen Beschreibungen der Ansichten eingegangen, von denen es insgesamt sieben gibt: die Ausgangsansicht, die Ansichten „Erläuterung“, „Frage“, „Kante“, „Schwierigkeitsgrad“, „Standard-Ziel“ und „Start-Ecke“. Die Ansichten werden nun thematisiert.

#### Ausgangsansicht „Quizgraph“
Wenn man den Quizeditor öffnet, wird zunächst die Ausgangsansicht angezeigt.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_graph.png" width="800" />

In der Ausgangsansicht können die Bedienelemente im Graphen genutzt werden, sofern bereits Ecken (und Kanten) angelegt worden sind. Neben der Überschrift gibt es außerdem die folgenden Buttons:
* <button>Ecke anlegen</button> Lege im Quizgraphen eine neue Ecke, d.h. eine Frage oder eine Erläuterung, an. Infolgedessen öffnet sich die Box „Ecke anlegen“ unter dem Quizgraphen.
* <button>Quiz linearisieren</button> Linearisiere das Quiz. Dabei werden alle Verzweigungen entfernt und die Ecken so verbunden, dass ein linearer, alle Ecken erreichender Pfad vom Start zum Ziel führt. In Zuge dessen können Kanten zwischen zuvor nicht benachbarten Ecken entstehen.
* <button>Start-Ecke</button> Wechsel zur Bedienansicht „Startecke“. Durch anschließendes Anklicken einer Ecke im Graphen wird diese zur neuen Startecke, d.h. eine Kante zwischen Start und dieser Ecke wird angelegt. Falls es vorher bereits eine Startecke gab, wird die Kante zwischen dieser und Start gelöscht.
* <button>Schwierigkeitsgrad</button> Wechsel zur Bedienansichtt „Schwierigkeitsgrad“. Dort kann dem Quiz ein Schwierigkeitsgrad zugewiesen werden.

#### Bedienansicht „Erläuterung“
Die Bedienansicht „Erläuterung“ erreicht man, indem man in der Ausgangsansicht „Quizgraph“ auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/square-regular.png" height="12"/></button> im Quizgraphen klickt. Dazu muss bereits eine Erläuterung angelegt oder importiert worden sein, was in der Box „Ecke anlegen“ vorgenommen werden kann.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_unverzweigte_ecke.png" width="800" />

In der Ansicht „Erläuterung“ können die Bedienelemente im Graphen genutzt werden. Links neben der Box „Quizgraph“ erscheint eine Vorschau der Erläuterung, dort werden gegebenenfalls Hinweise und Warnungen angezeigt. In diesem Bereich befinden sich keine Bedienelemente. Rechts neben der Überschrift der Box „Quizgraph“ gibt es die folgenden fünf Buttons:

* <button>Zurück</button> Wechsel zur Ausgangsansicht „Quizgraph“.
* <a href="/mampf/de/mampf-pages/edit-remark" target="_self"><button>Bearbeiten</button></a> bzw. <button>Kopie erstellen</button> (bei importierten Erläuterungen, für die man keine Bearbeitungsrechte hat) Wechsel zur Seite <a href="/mampf/de/mampf-pages/edit-remark" target="_self">„Erläuterung bearbeiten“</a> bzw. öffne das Dialogfeld „Kopie erstellen“.
* <a href="/mampf/de/mampf-pages/edit-quiz" target="_self"><button>Medium</button></a> Wechsel zur Seite <a href="/mampf/de/mampf-pages/edit-quiz" target="_self">„Quiz bearbeiten“</a>.
* <button>Standard-Ziel</button> Wechsel zur Bedienansicht „Standard-Ziel“ (das Standardziel ist die Ecke, zu der man im Quiz als nächstes gelangt). Durch anschließendes Anklicken einer Ecke im Graphen wird diese zum neuen Standardziel, d.h. eine Kante zwischen der Erläuterung und der angeklickten Ecke wird angelegt. Falls es vorher bereits ein Standardziel gab, wird die Kante zwischen diesem und der Erläuterung gelöscht.
* <button>Ecke löschen</button> Lösche die Ecke.

#### Bedienansicht „Frage“
Die Bedienansicht „Frage“ erreicht man, indem man in der Ausgangsansicht „Quizgraph“ auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-regular.png" height="12"/></button> im Quizgraphen klickt. Dazu muss bereits eine Frage angelegt oder importiert worden sein, was in der Box „Ecke anlegen“ vorgenommen werden kann.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_verweigte_ecke.png" width="800" />

In der Ansicht „Frage“ können die Bedienelemente im Graphen genutzt werden. Links neben der Box „Quizgraph“ erscheint eine Vorschau der Frage, dort werden gegebenenfalls Hinweise und Warnungen angezeigt. In diesem Bereich befinden sich keine Bedienelemente. Rechts neben der Überschrift der Box „Quizgraph“ gibt es die folgenden sechs Buttons:

* <button>Zurück</button> Wechsel zur Ausgangsansicht „Quizgraph“.
* <a href="/mampf/de/mampf-pages/edit-question" target="_self"><button>Bearbeiten</button></a> bzw. <button>Kopie erstellen</button> (bei importierten Fragen, für die man keine Bearbeitungsrechte hat) Wechsel zur Seite <a href="/mampf/de/mampf-pages/edit-question" target="_self">„Frage bearbeiten“</a> bzw. öffne das Dialogfeld „Kopie erstellen“.
* <a href="/mampf/de/mampf-pages/edit-quiz" target="_self"><button>Medium</button></a> Wechsel zur Seite <a href="/mampf/de/mampf-pages/edit-quiz" target="_self">„Quiz bearbeiten“</a>.
* <button>Standard-Ziel</button> Wechsel zur Bedienansicht „Standard-Ziel“ (das Standardziel ist die Ecke, zu der man gelangt, nachdem man die Frage richtig beantwortet hat). Durch anschließendes Anklicken einer Ecke im Graphen wird diese zum neuen Standardziel, d.h. eine Kante zwischen der Frage und der angeklickten Ecke wird angelegt. Falls es vorher bereits ein Standardziel gab, wird die Kante zwischen diesem und der Frage gelöscht.
* <button>Verzweigung</button> Öffne die Verzweigungscards am Seitenende. Dort kann für jede Kombination gegebener falscher bzw. nicht komplett richtiger Antworten eine Zielecke festgelegt werden.
* <button>Ecke löschen</button> Lösche die Ecke.

#### Bedienansicht „Kante“
Die Bedienansicht „Kante“ erreicht man, indem man in der Ausgangsansicht „Quizgraph“ auf <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/edge2.png" height="12"/></button> im Quizgraphen klickt. Dazu muss bereits eine Kante angelegt worden sein. Zum Anlegen von Kanten siehe <button>Start-Ecke</button> in der Ausgangsansicht, <button>Standard-Ziel</button> in den Bedienansichten „Erläuterung“ und „Frage“ sowie <button>Verzweigung</button> in der Bedienansicht „Frage“.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_kante.png" width="800" />

In der Ansicht „Kante“ können die Bedienelemente im Graphen genutzt werden. Außerdem gibt es zwei Bedienelemente rechts neben der Überschrift:
* <button>Kante löschen</button> Lösche die Kante und wechsel zur Ausgangsansicht „Quizgraph“.
* <button>Abbrechen</button> Wechsel zur Ausangsansicht „Quizgraph“.

#### Bedienansicht „Schwierigkeitsgrad“
In der Bedienansicht „Schwierigkeitsgrad“ kann der Schwierigkeitsgrad des Quiz' ausgewählt werden. Diese Ansicht erreicht man über den Button <button>Schwierigkeitsgrad</button> in der Ausgangsansicht „Quizgraph“.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_schwierigkeitsgrad.png" width="800" />

In der Bedienansicht „Schwierigkeitsgrad“ können die Bedienelemente <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/square-regular.png" height="12"/></button> und <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-regular.png" height="12"/></button> des Graphen genutzt werden, sofern Ecken angelegt worden sind. Außerdem gibt es rechts neben der Überschrift die folgende Bedienelemente:

* <form>
     Schwierigkeitsgrad
     <input type="radio" id="de" name="lang" checked></input>
     <label for="easy"> leicht</label>
     <input type="radio" id="eng" name="lang" checked></input>
     <label for="average"> mittel</label>
     <input type="radio" id="de" name="lang"></input>
     <label for="difficult"> schwer</label>
  </form> Radiobuttons zur Wahl des Schwierigkeitsgrads. Zur Auswahl stehen <em>leicht</em>, <em>mittel</em> und <em>schwer</em>, wobei <em>mittel</em> der voreingestellte Wert ist. Änderungen am Schwierigkeitsgrad werden direkt übernommen, Speichern ist nicht erforderlich.
* <button>Zurück</button> Wechsel zur Ausgangsansicht „Quizgraph“. Dabei werden Änderungen am Schwierigkeitsgrad übernommen.

#### Bedienansicht „Standard-Ziel“
In der Bedienansicht „Standard-Ziel“ kann man ein Standard-Ziel festlegen. Bei Erläuterungen ist das Standard-Ziel das, was im Quiz auf die Erläuterung folgt. Bei Fragen verhält es sich ebenso, sofern es keine Verzweigung gibt. Wenn es hingegen eine Verzweigung gibt, wird das Quiz nur mit dem Standard-Ziel fortgesetzt, wenn die gegebene Antwort korrekt ist oder das Standard-Ziel als Ziel der gegebenen Antwort ausgewählt worden ist. Zum Anlegen und Bearbeiten von Verzweigungen siehe den gleichnamigen Abschnitt.

Die Bedienansicht „Standard-Ziel“ erreicht man über <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/square-regular.png" height="12"/></button> bzw. <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-regular.png" height="12"/></button> im  „Quizgraph“. In der Ansicht „Standard-Ziel“ können die Bedienelemente im Graphen nicht standardmäßig genutzt werden. Zunächst gibt es nur das Bedienelement <button>Abbrechen</button>. Klickt man eine Ecke im Quizgraphen an, so erscheinen der Button <button>Speichern</button> und eine dunkelgrüne Kante zwischen der Ecke und ihrem neuen möglichen Standardziel. Falls es vorher bereits ein Standardziel gab, wird die dazugehörige Kante nicht mehr angezeigt; diese Kante wird allerdings erst nach dem Abspeichern gelöscht.

*  <button>Abbrechen</button> Wechsel zur Ausgangsansicht „Quizgraph“.
*  <button>Speichern</button> Bestätige, dass die gewählte Ecke zum neuen Standard-Ziel werden soll. Nach dem Speichern wird dunkelgrüne Kante angelegt und färbt sich hellgrün. Falls es zuvor bereits ein Standard-Ziel gab, wird die Kante zu diesem gelöscht.

#### Bedienansicht „Start-Ecke“
In der Bedienansicht „Startecke“ kann man eine Startecke festlegen. Diese Ansicht erreicht man über den Button <button>Startecke</button> in der Ausgangsansicht „Quizgraph“. In der Ansicht „Start-Ecke“ können die Bedienelemente im Graphen nicht standardmäßig genutzt werden. Es gibt das Bedienelement <button>Abbrechen</button>. Außerdem ist jede Ecke im Graphen ein Bedienelement.

* <button>Abbrechen</button> Wechsel zur Ausgangsansicht „Quizgraph“.
* <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/square-regular.png" height="12"/></button> bzw. <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-regular.png" height="12"/></button> Mache die Ecke zur neuen Startecke. Infolgedessen wird eine Kante zwischen der gewählten Ecke und Start angelegt und gegebenenfalls die zuvor bestehende Kante zwischen Start und einer anderen Ecke gelöscht.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_startecke.png" width="800" />

### Verzweigung
In der Ansicht „Verzweigung“ kann man für jede Antwortmöglichkeit einer Frage festlegen, womit das Quiz fortzgesetzt werden soll. Die im Folgenden beschriebenen Bedienelemente werden angezeigt, nachdem man zuerst die gewünschte Frage im Quizgraphen und anschließend den Button <button>Verzweigung</button> angeklickt hat. In dieser Ansicht ist  <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/edge2.png" height="12"/></button> im Quizgraphen kein Bedienelement. <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/square-regular.png" height="12"/></button> und <button><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-regular.png" height="12"/></button> im Graphen sind weiterhin Bedienelemente, die dazu führen, dass sich die Bedienansicht „Erläuterung“ bzw. „Frage“ öffnet und die Ansicht „Verzweigung“ geschlossen wird.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_frage_verweigung.png" width="800" />

Für jede mögliche Kombination falscher und teilweise richtiger Antworten wird eine rote Kachel mit Bedienelementen aufgeführt. Über den Kacheln gibt es die beiden Buttons <button>Ziele speichern</button> und <button>Abbrechen</button>.
* <button>Ziele speichern</button> Speichere die vorgenommenen Änderungen und wechsel zur Ausgangsansicht „Quizgraph“.
* <button>Abbrechen</button> Schließe die Ansicht „Verzweigung“ und wechsel zur Bedienansicht der ausgewählten Frage.

Auf den Kacheln befindet sich jeweils ein Dropdownmenü und eine Checkbox.
* <label for="cars"></label>
<select name="cars" id="cars">
   <option value="volvo">Ecke</option>
   <option value="volvo2">Ecke</option>
   <option value="volvo3">Ecke</option>
</select><br></br> Dropdown aller bereits angelegter Ecken außer der gewählten. Lege ein Ziel für die Antwortmöglichkeit fest. Der vereingestellte Wert ist hierbei das Standardziel.
*  <form>
     <input type="checkbox" id="up" name="sub"></input>
        <label for="up"> Lösung verstecken </label><br></br>
   </form> Checkbox. Standardmäßig ist der Haken nicht gesetzt. Bei gesetztem Haken wird die Lösung nicht angezeigt. Diese Option sollte gewählt werden, wenn die Antwortmöglichkeit zu einer Hilfestellung führen und die falsch beantwortete Frage erneut gestellt werden soll.

### Box „Ecke anlegen“
In der Box „Ecke anlegen“ kann eine Frage oder eine Erläuterung angelegt werden. Editor\*innen können Fragen und Erläuterungen neu anlegen oder vorhandene aus der Datenbank importieren. Vortragende ohne zusätzliche Editorenrechte können hingegen nicht auf Inhalte der Datenbank zugreifen. Die Box „Ecke anlegen“ erscheint unter dem Quizgraphen, sobald auf das Bedienelemente <button>Ecke anlegen</button> in der Ausgangsansicht „Quizgraph“ geklickt worden ist.

Bedienelmente gibt es sowohl im Kopf als auch im Rumpf der Box „Ecke anlegen“. Neben der Überschrift kommt nur das Bedienelement <button>Abbrechen</button> vor. Mit diesem schließt man die Box „Ecke anlegen“, ohne eine neue Ecke anzulegen. Im Rumpf der Box gibt es bei Editor\*innen drei weitere Buttons, bei Vortragenden ohne weitere Editorenrechte zwei. Diese Buttons sind Überschriften von Tabs, hinter denen sich weitere Bedienelemente verbergen.

* <button>Inhalt importieren</button> (nur bei Editor*innen) Wechsel zum Tab „Inhalt importieren“. Dieser Tab ist bei Editor*innen zunächst ausgewählt. In diesem Tab kann die Datenbank mithilfe von Suchfiltern nach passenden Fragen und Erläuterungen durchsucht werden.
* <button>Quiz-Frage erstellen</button> Wechsel zum Tab „Quiz-Frage erstellen“. Dieser ist bei Vortragenden ohne weitere Editorenrechten zunächst ausgewählt. In diesem Tag kann eine Quizfrage angelegt werden.
* <button>Quiz-Erläuterung erstellen</button> Wechsel zum Tab „Quiz-Erläuterung erstellen“. In diesem Tab kann eine Quizerläuterung angelegt werden.

Nun werden die Bedienelemente der einzelnen Tabs beschrieben.

#### Tab „Inhalt importieren“ (nur bei Editor*innen)
Im Tab „Inhalt importieren“ gibt es zunächst nur die Suchmaske. Nachdem eine erfolgreiche Suche durchgeführt worden ist, werden zudem die Seitenbereiche Seitennavigation, Treffer, Auswahl und Vorschau angezeigt. Diese Bereiche sind in den folgenden Screenshots markiert.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/importieren_quiz_sucherfolg_maske.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/importieren_quiz_sucherfolg_seitennav.png" height="300"/>  |
|:---: | :---: |
|Suchmaske|Seitennavigation|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/importieren_quiz_sucherfolg_treffer.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/importieren_quiz_sucherfolg_auswahl.png" height="300"/>  |
|Treffer|Auswahl|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/importieren_quiz_sucherfolg_vorschau.png" height="300"/> | |
|Vorschau||

In allen Bereichen außer der Vorschau kommen Bedienelemente vor. Diese werden nun bereichsweise beschrieben.

##### Suchmaske
In der Suchemaske finden sich diverse Bedienelmente, unter anderem Dropdownmenüs, Checkboxen und Eingabefelder.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/importieren_quiz_maske.png" width="800" />

* Typ / Assoziiert zu / Verknüpfte Tags / EditorInnen<br></br> <form>
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
* Assoziiert zu <form>
     <input type="radio" id="de" name="lang" checked></input>
     <label for="vererb"> mit Verebung</label>
     <input type="radio" id="de" name="lang"></input>
     <label for="ohnever"> ohne Vererbung</label>
  </form> Radiobuttons mit den Auswahlmöglichkeiten <em>mit Vererbung</em> und <em>ohne Vererbung</em>. Wenn <em>mit Vererbung</em> ausgewählt ist, werden bei Modulen auch mit Veranstaltungen und Sitzungen verknüpfte Medien und bei Veranstaltungen mit Sitzungen verknüpfte Medien berücksichtigt.
* Verknüpfte Tags <form>
     <input type="radio" id="de" name="lang" checked></input>
     <label for="oder"> ODER</label>
     <input type="radio" id="de" name="lang"></input>
     <label for="und"> UND</label>
  </form> Radiobuttons mit den Auswahlmöglichkeiten <em>ODER</em> und <em>UND</em>. Bestimme, ob Medien mindestens einen (<em>ODER</em>) oder alle (<em>UND</em>) Tags tragen sollen.
* <form>
     <p>
        <label for="fname">Volltext</label><br></br>
        <input type="text" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Eingabefeld für den Suchbegriff. Dieses Feld muss nicht ausgefüllt werden, um eine Suche durchzuführen.
* <label for="cars"></label>Zugriffsrechte <br></br>
  <select name="cars" id="cars">
     <option value="volvo">egal</option>
     <option value="saab">frei</option>
     <option value="mercedes">nur registierte MaMpf-NutzerInnen</option>
     <option value="audi">nur AbonnentInnen</option>
     <option value="volvo1">gesperrt</option>
     <option value="saab2">unveröffentlicht</option>
  </select><br></br> Dropdownmeü zur Einstellung der Zugriffsrechte. Zur Auswahl stehen <i>egal</i>, <i>frei</i>, <i>nur registrierte MaMpf-NutzerInnen</i>, <i>nur AbonnentInnen</i>, <i>gesperrt</i> und <i>unveröffentlicht</i>.
* <label for="cars"></label>Anzahl der Antworten <br></br>
  <select name="cars" id="cars">
     <option value="volvo">egal</option>
     <option value="saab">1</option>
     <option value="mercedes">2</option>
     <option value="audi">3</option>
     <option value="volvo1">4</option>
     <option value="saab2">5</option>
     <option value="mercedes2">6</option>
     <option value="audi3">>6</option>
  </select><br></br> Dropdownmeü zur Einstellung der Anzahl der Antworten. Zur Auswahl stehen <i>egal</i>, <i>1</i>, <i>2</i>, <i>3</i>, <i>4</i>, <i>5</i>, <i>6</i> und <i>>6</i>.
* <label for="cars"></label>Treffer pro Seite <br></br>
  <select name="cars" id="cars">
     <option value="volvo">10</option>
     <option value="saab">20</option>
     <option value="mercedes">50</option>
  </select><br></br> Dropdownmeü zur Einstellung der pro Seite angezeigten Treffer. Zur Auswahl stehen <i>10</i>, <i>20</i> und <i>50</i>.
* <button>Suchen</button> Starte eine Suche unter Verwendung der gewählten Kriterien.

Wenn es Einträge in der Datenbank, die den eingestellten Kriterien genügen, gibt, werden die Suchergebnisse unterhalb der Suchmaske angezeigt.

##### Seitennavigation
Wenn es mehr Treffer, als pro Seite angezeigt werden sollen, gibt, stehen folgende Buttons zur Seitennavigation zur Verfügung.

* <button name="button">n</button> Wechsel auf Seite n.
* <button name="button">Nächste</button> bzw. <button name="button">Vorige Wechsel</button> auf die nächste bzw. vorige Seite.
* <button name="button">Letzte</button> bzw. <button name="button">Erste</button> Wechsel auf die letzte bzw. erste Seite.

##### Treffer
Die Treffer werden in einer Tabelle aufgeführt. Dort kommen weitere Bedienelemente, die nun erläutert werden, vor.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/importieren_quiz_treffer.png" width="800" />

* <button>Zeile</button> (nicht <button>Tag</button> oder <button>Modul</button>) Falls das Objekt noch nicht ausgewählt worden ist, nimm es in die in Auswahl auf. Entferne es andernfalls. Bei ausgewählten Treffern ist die Zeile grün, sofern sich der Cursor nicht auf dieser Zeile befindet.
* <a href="/mampf/de/mampf-pages/ed-edit-module" target="_self"><button>Modul</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-module" target="_self">„Modul bearbeiten“</a>. Dieser Button steht nur Editor*innen des entsprechenden Moduls zur Verfügung.
* <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self"><button>Tag</button></a> Wechsel auf die Seite <a href="/mampf/de/mampf-pages/ed-edit-tag" target="_self">„Tag bearbeiten“</a>.

Darüber hinaus gibt es eine weitere Funktionalität in der Tabelle. Wenn man mit dem Cursor über einen Treffer fährt, wird das entsprechende Objekt in der Vorschau angezeigt und die Zeile färbt sich orange. Dies erfolgt unabhängig davon, ob das Objekt in die Auswahl aufgenommen worden ist oder nicht.

##### Auswahl
In der Auswahl werden nur Bedienelemente angezeigt, wenn bereits Objekte in die Auswahl übernommen worden sind. Dann gibt es zwei Bedienelemente. Um einen Treffer aus der Tabelle in die Auswahl aufzunehmen, klickt man ihn an. Durch nochmaliges Anklicken wird der Treffer wieder aus der Auswahl entfernt. Ferner ist es möglich, Treffer aus unterschiedlichen Suchanfragen auszuwählen.

<table>
  <tr>
     <td>
        <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/importieren_quiz_vorschau.png" width="1300" />
     </td>
     <td>
        <ul>
           <li>
              <button>Übernehmen</button> Lege für alle ausgewählten Datenbankeinträge eine Ecke im Quizgraphen an und schließe die Box „Ecke anlegen“.
           </li>
           <li>
              <button>Zurücksetzen</button> Entferne alle Datenbankeinträge aus der Auswahl.
           </li>
        </ul>
     </td>
  </tr>
</table>

#### Tab „Quizfrage erstellen“
Im Tab „Quizfrage erstellen“ gibt es zwei Bedienelemente.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_ecke_frage.png" width="800" />

* <form>
     <p>
        <label for="fname">Titel</label><br></br>
        <input type="text" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Eingabefeld für den Titel der Frage. Dieses Feld muss ausgefüllt werden, um eine Frage anzulegen.
* <button>Speichern</button> Lege eine neue Frage mit dem im Eingabefeld gewählten Titel an und schließe die Box „Ecke anlegen“. Wenn das Eingabefeld nicht ausgefüllt wurde, wird durch Anklicken dieses Buttons keine Fragen angelegt.

#### Tab „Quizerläuterung erstellen“
Im Tab „Quizerläuterung erstellen“ gibt es zwei Bedienelemente.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/quizeditor_ecke_erlaeuterung.png" width="800" />

* <form>
     <p>
        <label for="fname">Titel</label><br></br>
        <input type="text" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Eingabefeld für den Titel der Erläuterung. Dieses Feld muss ausgefüllt werden, um eine Erläuterung anzulegen.
* <button>Speichern</button> Lege eine neue Erläuterung mit dem im Eingabefeld gewählten Titel an und schließe die Box „Ecke anlegen“. Wenn das Eingabefeld nicht ausgefüllt wurde, wird durch Anklicken dieses Buttons keine Erläuterung angelegt.

## Strukturell fehlerfreier Quizgraph
Damit es ein Quiz von Nutzer\*innen geöffnet werden kann, muss der Quizgraph strukturell fehlerfrei sein. Bei dem Quizgraphen handelt es sich um einen gerichteten, von der Startecke aus zusammenhängenden Multigraphen. (stimmt gar nicht; Ecken müssen nicht von Start aus erreichbar sein, solange sie zum Ziel führen; man kann Ecken haben, die niemals beim Spielen des Quiz' erreicht werden können)

Bsp. mit Screenshots: Fehlerfrei vs. fehlerhaft

* Jede Ecke (somit auch die Zielecke) ist von der Startecke aus erreichbar.
* Zwischen zwei Ecken kann es mehrere Kanten geben; dies ist der Fall, wenn mindestens zwei Antworten auf eine Frage zur gleichen Ecken führen.
* Zyklen sind bei Verzweigungen möglich.

, d.h. es gibt erstens eine Startecke, zweitens mindestens eine Verzweigung, die zum Ende führt, und drittens zu jeder sonstigen Ecke mindestens eine eingehende Kante und ein Standardziel.

keine Ecke darf unverbunden sein (zusammenhängend); die Startecke benötigt genau einen Nachfolger (Kind), die Zielecke benötigt mindestens einen Vorgänger (Elter); alle anderen Ecken benötigen einen Elter und ein Kind (mindestens ein Standardziel); zusammenhängender Graph/zusammenhängend von der Startecke aus (Multigraph: zwei Knoten können durch mehrere Kanten verbunden sein; ist der Fall, wenn es bei einer Frage keine Verzweigung gibt; Antwort = Kante)

; darf Zyklen enthalten (nur in Kombination mit Verzweigungen möglich); Start und Ziel eindeutig

## Von dieser Seite aus aufrufbare Seiten
* [Quiz bearbeiten](edit-quiz)
* [Quizerläuterung bearbeiten](edit-remark)
* [Quizfrage bearbeiten](edit-question)

## Verwandte Seiten
### Betrachtung
* [Medium](medium)

### Bearbeitung
* [Medium bearbeiten](edit-medium)
* [Quiz bearbeiten](edit-quiz)
* [Quizerläuterung bearbeiten](edit-medium-remark) (Medium)
* [Quizerläuterung bearbeiten](edit-remark)
* [Quizfrage bearbeiten](edit-medium-question) (Medium)
* [Quizfrage bearbeiten](edit-question)
