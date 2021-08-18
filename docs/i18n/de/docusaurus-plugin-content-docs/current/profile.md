---
title: Profileinstellungen
---

\*Diese Seite ist in Bearbeitung.\*

Auf der Seite „Profil“ kann der Account verwaltet werden. Dort ist es möglich, die Zugangsdaten zu ändern, den Account zu löschen, Veranstaltungen zu abonnieren oder abzubestellen sowie Änderungen an den Einstellungen vorzunehmen.

## Navigation zu dieser Seite
Die Seite „Profil“ erreicht man, indem auf <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/user-cog-solid.png" height="12"/></button> in der [Navigationsleiste](nav-bar.md) klickt. Auf diese Seite wird man auch direkt nach der Aktivierung des Accounts geleitet.

## Bereiche der Seite
Die Seite „Profil“ gliedert sich in drei große Teilbereiche: die eigentliche Seite „Profil“, die [Navigationsleiste](nav-bar.md) und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Sitzung“ eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Eigentliche_Seite_keine_Sidebar.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Navigationsleiste_keine_Sidebar.png" height="300"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer_keine_Sidebar.png" height="300"/>|
|:---: | :---: | :---:|
|Eigentliche Seite|Navigationsleiste|Footer|

Die eigentliche Seite besteht aus den vier Boxen „Account“, „Module“, „Einstellungen“ und „E-Mail-Benachrichtigungen“. Die Box „Module“ enthält ein Akkordeon. Durch Anklicken eines Studiengangs darin öffnet sich eine Übersicht über die vorhandenen Module. Diese sind nach Typ sortiert und werden ebenfalls in Akkordeons präsentiert.

## Bedienelemente und mögliche Aktionen auf dieser Seite
Die Bedienelemente der Seite „Profil“ und mithilfe dieser mögliche Aktionen werden nun beschrieben. Der Button <button name="button">Profil updaten</button> am Seitenanfang erscheint erst, nachdem das Profil bearbeitet worden ist. Die Änderungen werden nur übernommen, wenn dieser Button gedrückt wird. Alle anderen Buttons werden immer angezeigt bzw. öffnen sich durch Ausklappen eines Akkordeons und sind im Folgenden beschrieben. Dabei wird jede Box gesondert behandelt.

### Account
![](/img/Profil-Account.png)

* <a href="/mampf/de/docs/change-login-data" target="_self"><button name="button">Zugangsdaten ändern</button></a> Wechsel auf die Seite <a href="/mampf/de/docs/change-login-data" target="_self">„Zugangsdaten ändern“</a>. Dort kann der Account auf eine andere E-Mail-Adresse umgestellt und das Passwort geändert werden.
* <button name="button">Account löschen</button> Lösche den Account.
* <form>
  <p><label for="fname">Anzeigename</label><br></br>
  <input type="text" id="fname" name="fname" value="anonymer Musterstudi"></input><br></br>
  </p></form>
Name, der anderen Nutzer*innen und Editor*innen in MaMpf angezeigt wird. Dies betrifft Teilnehmerlisten, Kommentare und Forumsbeiträge. Zunächst steht hier der Anfang der E-Mail-Adresse, über die der Account läuft, bis zum @.
* <form>
  <p><label for="fname">Name in Übungsgruppen</label><br></br>
  <input type="text" id="fname" name="fname" value="Musterstudi"></input><br></br>
  </p></form>  
Name, der Tutor*innen bei Abgaben und anderen Mitgliedern des eigenen Abgabeteams angezeigt wird. Bei Tutor*innen ist dies der Name, mithilfe dem Editor*innen die Tutorien zuteilen. Hier sollte der richtige Name eingetragen werden, um allen Beteiligten die Zuordnung zu erleichtern. Wenn dieses Feld nicht ausgefüllt ist, wird der Anzeigename für die eben genannten Zwecke verwendet.

Änderungen an den Namen werden erst wirksam, nachdem der Button <button name="button">Profil updaten</button> am Seitenanfang angeklickt worden ist. Dieser erscheint, sobald eine Veränderung der Name vorgenommen und anschließend auf einen beliebigen Punkt außerhalb des Eingabefeld für den Namen geklickt worden ist.

### Module
Die Box „Module“ besteht aus einem Akkordeon, in dessen Feldern Studiengänge aufgeführt sind. Wenn ein solches Feld angeklickt wird, klappen Module zu diesem Studiengang aus. Die Module sind nach Typ sortiert und selbst wieder Felder von Akkordeons. Diese enthalten die zu diesem Modul verfügbaren Veranstaltungen.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Profil-Veranstaltungsakkordeon-1.png" height="300"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Profil-Veranstaltungsakkordeon-2a.png" height="250"/>|
|:---: | :---: |
|Modulakkordeon|Studiengang ausgewählt|
|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Profil-Veranstaltungsakkordeon-3a.png" height="300"/>|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Profil-Veranstaltungsakkordeon-4a.png" height="250"/>|
|Abonniertes Modul ausgewählt|Nicht abonniertes Modul ausgewählt|

* <button name="button">Studiengang</button> Klappe alle zu diesem Studiengang verfügbaren Module aus.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/circle-regular.png" height="12"/> Modul&nbsp;</button> bzw. <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/check-circle-solid.png" height="12"/> Modul&nbsp;</button> Klappe alle zu diesem  verfügbaren Veranstaltungen aus. Dieses Bedienelement erscheint erst, wenn ein Studiengang angeklickt worden ist. Der Haken wird nur angezeigt, wenn in einem Modul eine Veranstaltung abonniert ist.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/square-regular.png" height="12"/> Veranstaltung&nbsp;</button> bzw. <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/check-square-regular.png" height="12"/> Veranstaltung&nbsp;</button> Beginne bzw. beende ein Veranstaltungsabo durch Setzen bzw. Entfernen eines Hakens. Dieses Bedienelement erscheint erst, nachdem ein Modul angeklickt worden ist.

Abonnements werden erst durch das Klicken auf den Button <button name="button">Profil updaten</button> am Seitenanfang abgeschlossen bzw. beendet.

### Einstellungen
![](/img/Profil-Einstellungen.png)

In der Box „Einstellungen“ können die Sprache und die angezeigten verknüpften Inhalte bearbeitet werden. Dies erfolgt durch Anklicken der gewünschten Option. Die Auswahlmöglichkeiten werden in Form von Radio Buttons präsentiert. Radio Buttons zeichnen sich dadurch aus, dass immer nur genau eine Option aus den voreingestellten Möglichkeiten ausgewählt werden kann und muss.

* <form>
 Sprache<br></br>
 <input type="radio" id="de" name="lang" checked></input>
 <label for="de"> Deutsch</label><br></br>
 <input type="radio" id="eng" name="lang"></input>
 <label for="eng"> Englisch</label>
</form>
<br></br>
Zur Auswahl stehen die Sprachen Deutsch und Englisch. Die hier ausgewählte Sprachepräferenz wird nur außerhalb von Veranstaltungen berücksichtigt. Die in einer Veranstaltung verwendete Sprache wird von den Veranstaltungseditor*innen festgelegt und kann nicht durch Nutzer*innen beeinflusst werden.

* <form>
 MaMpf liefert eine Vielzahl von verknüpften Inhalten. Ich möchte verknüpfte Inhalte (wenn diese freigegeben sind)<br></br>
 <input type="radio" id="before" name="content" checked></input>
 <label for="before"> auch aus allen Modulen sehen, die sich inhaltlich vor den von mir abonnierten Modulen einsortieren.</label><br></br>
 <input type="radio" id="all" name="content"></input>
 <label for="all"> aus allen Modulen sehen.</label><br></br>
 <input type="radio" id="subs" name="content"></input>
 <label for="subs"> ausschließlich aus den von mir abonnierten Modulen sehen.</label>
</form>
<br></br>
Bei den verknüpften Inhalten kann man wählen, ob alle verfügbaren Inhalte angezeigt oder diese eingeschränkt werden. Dabei können entweder nur Inhalte aus abonnierten Modulen zugelassen werden oder auch Inhalte aus Modulen, auf denen die abonnierten Module aufbauen.

Um Änderungen an den Einstellungen zu übernehmen, muss der Button <button name="button">Profil updaten</button> am Seitenanfang angeklickt werden.

### E-Mail-Benachrichtigungen
\*Baustelle\*

![](/img/Profil-Mailbenachrichtigungen.png)

In der Box „E-Mail-Benachrichtungen“ können Benachrichtigungsanlässe hinzugefügt oder entfernt werden. MaMpf bietet Benachrichtigungen zu Veranstaltungen und Modulen, zur Abgabe von Übungsaufgaben und zu Neuigkeiten auf MaMpf an. Standardmäßig sind keine Benachrichtungsanlässe ausgewählt. Die Verwaltung von Benachrichtungsanlässen erfolgt über Checkboxen. Diese zeichnen sich dadurch aus, dass eine beliebige Anzahl an Optionen ausgewählt werden kann. Durch Anklicken einer leeren Checkbox kann ein Haken gesetzt und damit ein Benachrichtungsanlass hinzugefügt werden. Durch Anklicken einer ausgefüllten Checkbox kann ein Haken entfernt werden und damit auch der entsprechende Benachrichtungsanlass.

* <form>
 Veranstaltungen und Module<br></br>
 <input type="checkbox" id="not" name="ev"></input>
 <label for="not"> neue Mitteilungen in von mir abonnierten Veranstaltungen</label><br></br>
 <input type="checkbox" id="med" name="ev"></input>
 <label for="med"> neue Medien in vor mir abonnierten Veranstaltungen oder Modulen</label><br></br>
 <input type="checkbox" id="eve" name="ev"></input>
 <label for="eve"> neu angelegte Veranstaltungen oder Module</label>
</form><br></br>
*mehr Infos und Links*

* <form>
 Abgabe von Übungsaufgaben<br></br>
 <input type="checkbox" id="up" name="sub"></input>
 <label for="up"> erfolgreiches Hochladen einer Datei durch ein Teammitglied</label><br></br>
 <input type="checkbox" id="del" name="sub"></input>
 <label for="del"> Löschen einer Datei durch ein anderes Teammitglied</label><br></br>
 <input type="checkbox" id="join" name="sub"></input>
 <label for="join"> Beitritt eines Teammitglieds</label><br></br>
 <input type="checkbox" id="quit" name="sub"></input>
 <label for="quit"> Austritt eines Teammitglieds</label><br></br>
 <input type="checkbox" id="av" name="sub"></input>
 <label for="av"> Verfügbarkeit der Korrektur</label><br></br>
 <input type="checkbox" id="del" name="sub"></input>
 <label for="del"> Annahme oder Ablehnung einer verspäteten Korrektur</label>
</form><br></br>
*mehr Infos und Links*
Es ist nicht möglich, MaMpf das Verschicken von Einladungen zu einer Abgabe zu untersagen.

* <form>
 Sonstiges<br></br>
 <input type="checkbox" id="news" name="mis"></input>
 <label for="news"> Neuigkeiten über MaMpf</label></form><br></br>
 *mehr Infos und Links*

Damit Änderungen an ausgewählten Benachrichtigungsanlässen übernommen werden, muss der Button <button name="button">Profil updaten</button> am Seitenanfang angeklickt werden.

## Profil bearbeiten
Sobald Änderungen am Profil vorgenommen worden sind, erscheint oben auf der Seite der Button <button name="button">Profil updaten</button> sowie folgender Text:

![](/img/Aenderungen_speichern.png)

Die Änderungen werden nur gespeichert, wenn sie durch Betätigen des Buttons <button name="button">Profil updaten</button> bestätigt werden.

## Account löschen
Um einen Account zu löschen, muss man auf den Button <button name="button">Account löschen</button> klicken. Im Anschluss daran, öffnet sich ein Dialogfenster, in dem man die Löschung durch Passworteingabe bestätigen muss. In diesem Dialogfenster wird man zudem darüber informiert, wie mit hochgeladenen Abgaben und erhaltenen Korrekturen verfahren wird: Mit der Löschung des Accounts werden auch alle Einzelabgaben und die dazugehörige Korrekturen unwiderruflich aus MaMpf entfernt. Teamabgaben und die dazugehörige Korrekturen werden hingegen erst gelöscht, wenn das letzte verbleibende Teammitglied seinen Account löscht oder das regulären Löschungsdatum (zwei Wochen nach Beginn der nächsten Vorlesungszeit) erreicht ist. Wenn Tutor\*innen ihren Account löschen, bleiben ihre Korrekturen bis zum regulären Löschungstermin im System.

![](/img/Account_loeschen_neu.png)

Nachdem man auf <a href="/mampf/de/docs/home-page" target="_self"><button name="button">Account löschen</button></a> geklickt hat, wird die Löschung durchgeführt. Dann wird man auf die [Startseite](home-page.md) geschickt, wo nun folgender zusätzlicher Text steht:

![](/img/Account_geloescht2.png)

## Von dieser Seite aus aufrufbare Seiten
Von Seite „Profil“ aus kann nur zur Seite [„Zugangsdaten ändern“](change-login-data.md) navigiert werden. Dies erfolgt über den Button <a href="/mampf/de/docs/change-login-data" target="_self"><button name="button">Zugangsdaten ändern</button></a>.

## Ähnliche Seiten
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)
* [Login](login.md)
* [Logout](logout.md)
* [Meine Startseite](my-home-page.md)
* [Passwort ändern](change-password.md)
* [Passwort vergessen](password-forgotten.md)
* [Registrieren](registration.md)
* [Startseite](home-page.md)
* [Zugangsdaten ändern](change-login-data.md)
