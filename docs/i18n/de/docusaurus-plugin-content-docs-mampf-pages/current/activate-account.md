---
title: Anleitung zur Bestätigung des Account erneut versenden
---

Die Seite „Anleitung zur Bestätigung des Accounts erneut versenden“ wird benötigt, wenn man sich [registriert](registration.md), aber keine Bestätigungsmail erhalten hat. Bevor man diese Seite konsultiert, sollte man überprüfen, ob die Bestätigungsmail nicht im Spamordner gelandet ist. Falls man hingegen die E-Mail zum Zurücksetzen des Passworts nicht bekommen hat, sollte man sie erneut auf der Seite [„Passwort vergessen“](password-forgotten.md) anfordern. Um die E-Mail zur Aktivierung des Accounts zu erhalten, gibt man auf der Seite „Anleitung zur Bestätigung des Accounts erneut versenden“ die E-Mail-Adresse ein, mit der man sich vorher registriert hat. Diese E-Mail enthält einen Aktivierungslink, mit dem der Account freigeschaltet werden kann.

![](/img/Anleitung_zur_Bestaetigung_thumb.png)

## Navigation zu dieser Seite
Die Seite „Anleitung zur Bestätigung des Accounts erneut versenden“ kann direkt von folgenden Seiten über <button name="button">Anleitung zur Bestätigung des Account nicht erhalten?</button> erreicht werden:

* [Login](login.md)
* [Registrieren](registration.md)
* [Passwort vergessen](password-forgotten.md)

## Bereiche der Seite
Die Seite „Bestätigung des Accounts erneut versenden“ gliedert sich in drei große Teilbereiche: die eigentliche Seite „Bestätigung des Accounts erneut versenden“, die [Navigationsleiste](nav-bar.md) und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Sitzung“ eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Eigentliche_Seite_keine_Sidebar.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Navigationsleiste_keine_Sidebar.png" height="300"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer_keine_Sidebar.png" height="300"/>|
|:---: | :---: | :---:|
|Eigentliche Seite|Navigationsleiste|Footer|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Die Bedienelemente der Seite „Anleitung zur Bestätigung des Accounts erneut versenden“ und mithilfe dieser mögliche Aktionen werden nun beschrieben.

![](/img/Anleitung_zur_Bestaetigung.png)

* <form>
     <p>
        <label for="fname">Email</label><br></br>
        <input type="text" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Feld für die E-Mail-Adresse, mit der man sich bereits registriert hat.
* <button name="button">Anleitung zur Bestätigung des Accounts erneut versenden</button> Schicke die eingegebenen Daten ab, um eine E-Mail mit Freischaltungslink für den Account zu erhalten.
* <form action="/mampf/de/docs/login"><input type="submit" value="Einloggen"/> Wechsel zur <a href="/mampf/de/docs/login "target="_self">Loginseite</a>.</form>
* <form action="/mampf/de/docs/registration"><input type="submit" value="Registrieren"/> Wechsel zur Seite <a href="/mampf/de/docs/registration "target="_self">„Registrieren“</a>.</form>
* <form action="/mampf/de/docs/password-forgotten"><input type="submit" value="Passwort vergessen?"/> Wechsel zur Seite <a href="/mampf/de/docs/password-forgotten "target="_self">„Passwort vergessen“</a>.</form>

## Ablauf
Nachdem man sich registriert und keine Bestätigungsmail erhalten hat, gibt man auf der Seite „Anleitung zur Bestätigung des Accounts erneut versenden“ die E-Mail-Adresse, mit der man sich registriert hat, ein und schickt sie durch Betätigung des Buttons <a href="/mampf/de/docs/home-page" target="_self"><button name="button">Anleitung zur Bestätigung des Account nicht erhalten?</button></a>. Daraufhin wird man zurück auf die [Startseite](home-page.md) geleitet. Dort steht nun dieser zusätzliche Text:

![](/img/Registriert2.png)

Zudem sollte man eine E-Mail von mampf@mathi.uni-heidelberg.de mit dem Betreff „Anleitung zur Bestätigung Deines MaMpf-Accounts“ erhalten haben. Um den Account zu aktivieren, muss man auf „Account bestätigen“ in der E-Mail klicken.

![](/img/Mail_Account_bestaetigen.png)

Infolgedessen öffnet sich Seite [„Profil“](profile.md), auf der man nun die Einstellungen für den Account (Username, Veranstaltungsabos und Einstellungen zu Sprache, angezeigten Inhalten und E-Mail-Benachrichtigungen) anpassen sollte.

## Fehlermeldung
Wenn der Account bereits freigeschaltet worden ist, gibt MaMpf die folgende Fehlermeldung aus: „Konnte User nicht speichern: Es ist ein Fehler aufgetreten. Email-Account wurde bereits bestätigt“. In diesem Fall gibt es bereits einen Account zu dieser E-Mail-Adresse. Wenn man sich nicht mehr an das zugehörige Passwort erinnern kann, sollte man auf der Seite [„Passwort vergessen“](password-forgotten.md) ein neues anfordern.

\*Screenshot\*

## Von dieser Seite aus aufrufbare Seiten
* [Login](login.md)
* [Registrieren](registration.md)
* [Passwort vergessen](password-forgotten.md)

## Ähnliche Seiten
* [Login](login.md)
* [Logout](logout.md)
* [Meine Startseite](my-home-page.md)
* [Passwort ändern](change-password.md)
* [Passwort vergessen](password-forgotten.md)
* [Profil](profile.md)
* [Registrieren](registration.md)
* [Startseite](home-page.md)
* [Zugangsdaten ändern](change-login-data.md)
