---
title: Login
---

Auf der Loginseite kann man sich einloggen, wenn man bereits einen MaMpf-Account besitzt. Falls man sich noch nicht auf MaMpf registriert hat, gelangt man von dort aus zur Seite [„Registrieren“](registration.md), auf der man einen Account anlegen kann. Wenn man das Passwort vergessen oder die E-Mail zum Zurücksetzen nicht erhalten hat, kann man die dafür vorgesehenen Seiten [„Passwort vergessen“](password-forgotten.md) und [„Anleitung zur Bestätigung des Accounts erneut versenden“](activate-account.md) öffnen.

![](/img/Login_thumb.png)

## Navigation zu dieser Seite
Zur Loginseite gelangt man, indem man <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/sign-in-alt-solid.png" height="12"/></button> in der [Navigationsleiste](nav-bar.md) anklickt. Dieser Button ist nur vorhanden, wenn auf dem verwendeten Gerät gerade niemand auf MaMpf eingeloggt ist.

## Bereiche der Seite
Die Seite „Login“ gliedert sich in drei große Teilbereiche: die eigentliche Seite „Login“, die [Navigationsleiste](nav-bar.md) und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Sitzung“ eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Eigentliche_Seite_keine_Sidebar.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Navigationsleiste_keine_Sidebar.png" height="300"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer_keine_Sidebar.png" height="300"/>|
|:---: | :---: | :---:|
|Eigentliche Seite|Navigationsleiste|Footer|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Die Bedienelemente der Loginseite und mithilfe dieser mögliche Aktionen werden nun beschrieben.

* <form>
     <p>
        <label for="fname">Email</label><br></br>
        <input type="text" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Um sich einzuloggen, muss man die E-Mail-Adresse eingeben, mit der man sich zuvor auf MaMpf registriert hat.
* <form>
     <p>
        <label for="fname">Passwort</label><br></br>
        <input type="password" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Um sich einzuloggen, muss man das für den Account angelegte Passwort eingeben.
* <form>
     <input type="checkbox" id="cook" name="cook"></input>
     <label for="cook"> Erinnere dich an mich (hierzu wird ein Cookie gesetzt)</label>
  </form> ???
* <button name="button">Einloggen</button> Schicke die eingegebenen Daten ab, um den Einlogvorgang zu starten.
* <form action="/mampf/de/docs/registration"><input type="submit" value="Registrieren"/> Wechsel zur Seite <a href="/mampf/de/docs/registration "target="_self">„Registrieren“</a>.</form>
* <form action="/mampf/de/docs/password-forgotten"><input type="submit" value="Passwort vergessen?"/> Wechsel zur Seite <a href="/mampf/de/docs/password-forgotten "target="_self">„Passwort vergessen“</a>.</form>
* <form action="/mampf/de/docs/activate-account"><input type="submit" value="Anleitung zur Bestätigung des Accounts nicht erhalten?"/> Wechsel zur Seite <a href="/mampf/de/docs/activate-account "target="_self">„Anleitung zur Bestätigung des Accounts erneut versenden“</a>.</form>

## Ablauf
Nachdem gültige Anmeldedaten eingegeben und der Button <a href="/mampf/de/docs/my-home-page" target="_self"><button name="button">Einloggen</button></a> angeglickt worden ist, gelangt man auf die [persönliche Startseite](my-home-page.md).

## Fehlermeldungen
Bei unvollständigen oder falschen Daten sowie unbestätigtem Account gibt MaMpf eine Fehlermeldung zurück. Bevor ein Account genutzt werden kann, muss der Aktivierungslink in der Bestätigungsmail angeklickt werden. Diese Mail wird an die E-Mail-Adresse geschickt, mit der man sich registriert hat. Siehe dazu auch [Registrieren (Seite)](registration.md).

| **Fehlermeldung** | **Form der Fehlermeldung** | **Fehler** | **Fehlerbehebung** |
|:------------------ |:--------------------| :--------------------|:-----------------|
| Anmeldedaten ungültig | Roter Kasten am Seitenanfang | Keine E-Mail-Adresse eingegeben. | Gib eine E-Mail-Adresse ein. |
| E-Mail-Adresse oder Passwort ungültig | Roter Kasten am Seitenanfang | Die eingebene E-Mail-Adresse ist inkorrekt oder nicht registriert oder das eingegebene Passwort ist falsch. | Überprüfe die Schreibung der E-Mail-Adresse und gib das Passwort erneut ein. |
|Account nicht bestätigt | Roter Kasten am Seitenanfang | Die E-Mail-Adresse ist registriert, aber nicht aktiviert. | Klicke auf den Aktivierungslink in der Bestätigungsmail. Falls keine solche E-Mail eingegangen ist, fordere erneut eine auf der Seite [„Anleitung zur Bestätigung des Accounts erneut versenden“](activate-account.md) an. |

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Login_ungueltige_Anmeldedaten.png" height="200"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Login_Mail_PW_ungueltig.png" height="200"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Account_nicht_bestaetigt.png" height="200"/>|
|:---: | :---: | :---:|
|Anmeldedaten ungültig|E-Mail-Adresse oder Passwort ungültig |Account nicht bestätigt |

## Von dieser Seite aus aufrufbare Seiten
* [Persönliche Startseite](my-home-page.md)
* [Registrieren](registration.md)
* [Passwort vergessen](password-forgotten.md)
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)

## Ähnliche Seiten
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)
* [Logout](logout.md)
* [Meine Startseite](my-home-page.md)
* [Passwort ändern](change-password.md)
* [Passwort vergessen](password-forgotten.md)
* [Profil](profile.md)
* [Registrieren](registration.md)
* [Startseite](home-page.md)
* [Zugangsdaten ändern](change-login-data.md)
