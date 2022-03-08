---
title: Passwort vergessen
---
Auf der Seite „Passwort vergessen“ kann man einen Link zum Zurücksetzen des Passworts anfordern. Dieser wird per E-Mail an die angegebene Adresse geschickt und ermöglicht das Ändern des Passworts. Die Änderung eines bekannten Passworts sollte auf der Seite [„Profil“](profile.md) erfolgen.

![](/img/Passwort_vergessen_thumb.png)

## Navigation zu dieser Seite
Die Seite „Passwort vergessen“ kann direkt von folgenden Seiten über <button name="button">Passwort vergessen?</button> erreicht werden:

* [Login](login.md)
* [Registrieren](registration.md)
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)

## Bereiche der Seite
Die Seite „Passwort vergessen“ gliedert sich in drei große Teilbereiche: die eigentliche Seite „Passwort vergessen“, die [Navigationsleiste](nav-bar.md) und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Sitzung“ eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Eigentliche_Seite_keine_Sidebar.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Navigationsleiste_keine_Sidebar.png" height="300"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer_keine_Sidebar.png" height="300"/>|
|:---: | :---: | :---:|
|Eigentliche Seite|Navigationsleiste|Footer|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Die Bedienelemente der Seite „Passwort vergessen“ und mithilfe dieser mögliche Aktionen werden nun beschrieben.

![](/img/Passwort_vergessen_thumb.png)

* <form>
     <p>
        <label for="fname">Email</label><br></br>
        <input type="text" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Feld für die zum zurückzusetzenden Account gehörige E-Mail-Adresse.
* <button name="button">Schick mir eine Anleitung zur Änderung meines Passwortes</button> Schicke die eingegebenen Daten ab, um eine E-Mail mit einem Link zum Zurücksetzen des Passworts zu erhalten.
* <a href="/mampf/de/docs/login" target="_self"><button name="button">Einloggen</button></a> Wechsel zur <a href="/mampf/de/docs/login" target="_self">Loginseite</a>.
* <a href="/mampf/de/docs/registration" target="_self"><button name="button">Registrieren</button></a> Wechsel zur Seite <a href="/mampf/de/docs/registration" target="_self"> „Registrieren"</a>.
* <a href="/mampf/de/docs/activate-account" target="_self"><button name="button">Anleitung zur Bestätigung des Accounts nicht erhalten?</button></a> Wechsel zur Seite <a href="/mampf/de/docs/activate-account" target="_self">„Anleitung zur Bestätigung des Accounts erneut versenden"</a>.

## Ablauf
Nachdem man das Feld für die E-Mail-Adresse ausgefüllt und den Button <a href="/mampf/de/docs/login" target="_self"><button name="button">Schick mir eine Anleitung zur Änderung meines Passwortes</button></a>
 betätigt hat, wird man zurück auf die <a href="/mampf/de/docs/login" target="_self">Loginseite</a> geleitet. Auf dieser steht nun folgender Text:

![](/img/Passwort_zurueckgesetzt.png)

Zudem sollte man eine E-Mail von mampf@mathi.uni-heidelberg.de mit dem Betreff „Anleitung für das Zurücksetzen Deines MaMpf-Passworts“ erhalten. Wenn man keine E-Mail empfangen hat, sollte man den Spamordner überprüfen. Um das Passwort zurückzusetzen und ein neues festzulegen, muss man auf <button name="button">Passwort ändern</button> in der E-Mail klicken.

![](/img/Passwort_aendern_Mail.png)

Infolgedessen öffnet sich die Seite „Passwort ändern“, auf der man ein neues Passwort bestimmen kann.

## Fehlermeldungen
Wenn eine E-Mail-Adresse angegeben worden ist, zu der es keinen Mampf-Account gibt, erscheint auf MaMpf die folgende Fehlermeldung: „Konnte User nicht speichern: Es ist ein Fehler aufgetreten. Email nicht gefunden“. In diesem Fall sollte überprüft werden, ob die E-Mail-Adresse korrekt geschrieben ist. Falls es zu dieser E-Mail-Adresse noch keinen Account gibt, kann einer auf der Seite [„Registrieren“](registration.md) angelegt werden.

## Von dieser Seite aus aufrufbare Seite
* [Login](login.md)
* [Registrieren](registration.md)
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)

## Ähnliche Seiten
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)
* [Login](login.md)
* [Logout](logout.md)
* [Meine Startseite](my-home-page.md)
* [Passwort ändern](change-password.md)
* [Profil](profile.md)
* [Registrieren](registration.md)
* [Startseite](home-page.md)
* [Zugangsdaten ändern](change-login-data.md)
