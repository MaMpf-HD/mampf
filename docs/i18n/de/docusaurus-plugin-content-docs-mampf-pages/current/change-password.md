---
title: Passwort ändern
---
Auf der Seite „Passwort ändern“ kann man das Passwort ändern, wenn man es vergessen hat. Falls man das Passwort hingegen kennt und ändern möchte, ist dies auf der [Seite „Profil“](profile.md) möglich. Um die Seite „Passwort ändern“ zu öffnen, muss man die Änderung des Passworts auf der Seite [„Passwort vergessen“](password-forgotten.md) anfordern und auf den Link „Passwort ändern“ in der im Anschluss daran erhaltenen E-Mail klicken.

![](/img/Passwort_aendern_thumb.png)

## Navigation zu dieser Seite
Zur Seite „Passwort ändern“ gelangt man, indem man sich auf der Seite [„Passwort vergessen“](password-forgotten.md) eine Anleitung zur Änderung des Passworts zuschicken lässt. Die Seite „Passwort vergessen“ kann direkt von folgenden Seiten über <button name="button">Passwort vergessen?</button> erreicht werden:

* [Login](login.md)
* [Registrieren](registration.md)
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)

Nachdem man auf der Seite „Passwort vergessen“ das Feld für die E-Mail-Adresse ausgefüllt und den Button <button name="button">Schick mir eine Anleitung zur Änderung meines Passwortes</button> betätigt hat, erhält man eine E-Mail mit Betreff „Anleitung für das Zurücksetzen Deines MaMpf-Passworts“ von mampf@mathi.uni-heidelberg. Diese E-Mail enthält den Link „Passwort ändern“, der einen auf die Seite „Passwort ändern“ führt.

## Bereiche der Seite
Die Seite „Passwort ändern“ gliedert sich in drei große Teilbereiche: die eigentliche Seite „Passwort ändern“, die [Navigationsleiste](nav-bar.md) und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Sitzung“ eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Eigentliche_Seite_keine_Sidebar.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Navigationsleiste_keine_Sidebar.png" height="300"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer_keine_Sidebar.png" height="300"/>|
|:---: | :---: | :---:|
|Eigentliche Seite|Navigationsleiste|Footer|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Die Bedienelemente der Seite „Passwort ändern“ und mithilfe dieser mögliche Aktionen werden nun beschrieben.

![](/img/Passwort_aendern.png)

* <form>
     <p>
        <label for="fname">Neues Passwort</label><br></br>
        <input type="password" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Feld für das neue Passwort, das man nutzen möchte. Das Passwort muss mindestens aus sechs Zeichen bestehen. Dabei sind alphanumerische und Sonderzeichen zulässig.
* <form>
     <p>
        <label for="fname">Neues Passwort bestätigen</label><br></br>
        <input type="password" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Feld zur Bestätigung des neuen Passworts. Das hier eingebene Passwort muss mit dem im Passwortfeld eingegebenen übereinstimmen.
* <button name="button">Passwort ändern</button> Bestätige das eingegebene Passwort und führe den Login durch.
* <a href="/mampf/de/mampf-pages/login "target="_self"><button>Einloggen</button></a> Wechsel zur <a href="/mampf/de/mampf-pages/login "target="_self">Loginseite</a>.
* <a href="/mampf/de/mampf-pages/registration "target="_self"><button>Registrieren</button></a> Wechsel zur Seite <a href="/mampf/de/mampf-pages/registration "target="_self">„Registrieren“</a>.
* <a href="/mampf/de/mampf-pages/activate-account "target="_self"><button>Anleitung zur Bestätigung des Accounts nicht erhalten?</button></a>  Wechsel zur Seite <a href="/mampf/de/mampf-pages/activate-account "target="_self">„Anleitung zur Bestätigung des Accounts erneut versenden“</a>.

## Ablauf
Nachdem man die beiden Felder für das neue Passwort ausgefüllt und durch Klicken auf den Button <a href="/mampf/de/mampf-pages/my-home-page" target="_self"><button name="button">Passwort ändern</button></a> bestätigt hat, öffnet sich die [persönliche Startseite](my-home-page.md). Dort erwartet einen der Text:

![](/img/Passwort_geaendert.png)

## Fehlermeldungen
Bei unvollständiger oder fehlerhafter Dateneingabe gibt MaMpf eine Fehlermeldung zurück. Die folgende Tabelle gibt einen Überblick über Fehlermeldungen und Fehlerbehebung.

Fehlermeldung  | Form der Fehlermeldung | Fehler | Fehlerbehebung
-------------- | ---------------------- | ------ |---------------
Konnte User nicht speichern: Es ist ein Fehler aufgetreten: Passwort muss ausgefüllt werden. | Roter Kasten am Seitenanfang | Kein Passwort angegeben. | Gib ein Passwort ein.
Konnte User nicht speichern: Es ist ein Fehler aufgetreten: Passwort ist zu kurz (weniger als 6 Zeichen) | Roter Kasten am Seitenanfang | Roter Kasten am Seitenanfang  | Wähle ein längeres Passwort. Dieses muss aus mindestens sechs Zeichen bestehen.
Konnte User nicht speichern: Es ist ein Fehler aufgetreten: Passwortbestätigung stimmt nicht mit Passwort überein | Roter Kasten am Seitenanfang | Passwort und Passwortbestätigung stimmen nicht überein. | Gib das Passwort und die Passwortbestätigung erneut ein.

## Von dieser Seite aus aufrufbare Seiten
* [Persönliche Startseite](my-home-page.md)
* [Login](login.md)
* [Registrieren](registration.md)
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)

## Ähnliche Seiten
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)
* [Login](login.md)
* [Logout](logout.md)
* [Meine Startseite](my-home-page.md)
* [Passwort vergessen](password-forgotten.md)
* [Profil](profile.md)
* [Registrieren](registration.md)
* [Startseite](home-page.md)
* [Zugangsdaten ändern](change-login-data.md)