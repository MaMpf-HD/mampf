---
title: Registrieren
---
Auf der Seite „Registrieren“ kann man einen MaMpf-Account anlegen. Dazu benötigt man lediglich eine E-Mail-Adresse. Für das Erstellen des Accounts ist ein Passwort und die Zustimmung zur Speicherung und Verarbeitung der Daten erforderlich.

![](/img/Registrieren_thumb.png)

## Navigation zu dieser Seite
Die Seite „Registrieren“ kann direkt von folgenden Seiten über <button name="button">Registrieren</button>
 bzw. <button name="button">registrieren</button>
 erreicht werden:

* [Startseite](home-page.md)
* [Login](login.md)
* [Logout](logout.md)
* [Passwort vergessen](password-forgotten.md)
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)

## Bereiche der Seite
Die Seite „Registieren“ gliedert sich in drei große Teilbereiche: die eigentliche Seite „Registrieren“, die [Navigationsleiste](nav-bar.md) und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Sitzung“ eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Eigentliche_Seite_keine_Sidebar.png" height="300"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Navigationsleiste_keine_Sidebar.png" height="300"/>  | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/Footer_keine_Sidebar.png" height="300"/>|
|:---: | :---: | :---:|
|Eigentliche Seite|Navigationsleiste|Footer|

## Bedienelemente und mögliche Aktionen auf dieser Seite
Die Bedienelemente der Seite „Registrieren“ und mithilfe dieser mögliche Aktionen werden nun beschrieben.

![](/img/Registrieren.png)

* <form>
     <p>
        <label for="fname">Email</label><br></br>
        <input type="text" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Feld für die E-Mail-Adresse, mit der man sich registrieren möchte. Pro E-Mail-Adresse kann nur ein Account eingerichtet werden.
* <form>
     <p>
        <label for="fname">Passwort</label><br></br>
        <input type="password" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Feld für das Passwort, das man nutzen möchte. Das Passwort muss mindestens aus sechs Zeichen bestehen. Dabei sind alphanumerische und Sonderzeichen zulässig.
* <form>
     <p>
        <label for="fname">Passwortbestätigung</label><br></br>
        <input type="password" id="fname" name="fname"></input><br></br>
     </p>
  </form>
  Feld zu Bestätigung des Passworts. Das hier eingebene Passwort muss mit dem im Passwortfeld eingegebenen übereinstimmen.
* <form>
     <input type="checkbox" id="cook" name="cook"></input>
     <label for="cook">  Ich stimme der Speicherung und Verarbeitung meiner Daten gemäß der <a href="https://www.uni-heidelberg.de/datenschutzerklaerung_web.html" target="_blank" rel="noopener noreferrer">Datenschutzerklärung</a> der Universität Heidelberg zu.</label>
  </form>
  Stimme durch Setzen des Haken der Speicherung und Verarbeitung der Daten zu. Dies ist erforderlich für das Anlegen eines Accounts.
* <button name="button">Registrieren</button> Schicke die eingegebenen Daten ab, um den Registriervorgang zu beginnen.
* <form action="/mampf/de/docs/login"><input type="submit" value="Einloggen"/> Wechsel zur Seite <a href="/mampf/de/docs/login "target="_self">Loginseite</a>.</form>
* <form action="/mampf/de/docs/password-forgotten"><input type="submit" value="Passwort vergessen?"/> Wechsel zur Seite <a href="/mampf/de/docs/password-forgotten "target="_self">„Passwort vergessen“</a>.</form>
* <form action="/mampf/de/docs/activate-account"><input type="submit" value="Anleitung zur Bestätigung des Accounts nicht erhalten?"/> Wechsel zur Seite <a href="/mampf/de/docs/activate-account "target="_self">„Anleitung zur Bestätigung des Accounts erneut versenden“</a>.</form>

## Der Registriervorgang
Zur Registrierung muss man die Felder „E-Mail-Adresse“, „Passwort“ und „Passwortbestätigung“ ausfüllen, der [Datenschutzerklärung der Universität Heidelberg](https://www.uni-heidelberg.de/datenschutzerklaerung_web.html) durch Setzen eines Hakens zustimmen und den Button <button name="button">Registrieren</button> betätigen. Dann erscheint die [Startseite](home-page.md). Diese zeigt nun folgenden Text an:

![](/img/Erfolgreiche_Registrierung.png)

Zudem wird eine E-Mail an die angebene Adresse gesendet. Der Absender ist mampf@mathi.uni-heidelberg.de, der Betreff lautet „Anleitung zur Bestätigung Deines MaMpf-Accounts“. Wenn man keine E-Mail erhält, sollte man den Spamordner überprüfen. Um den Account zu aktivieren, muss man auf „Account bestätigen“ in der E-Mail klicken.

![](/img/Mail_Account_bestaetigen.png)

Infolgedessen öffnet sich Seite [„Profil“](profile.md), auf der man nun die Einstellungen für den Account (Username, Veranstaltungsabos und Einstellungen zu Sprache, angezeigten Inhalten und E-Mail-Benachrichtigungen) anpassen sollte.

## Fehlermeldungen
Bei unvollständiger oder fehlerhafter Dateneingabe gibt MaMpf eine Fehlermeldung zurück. Die folgende Tabelle gibt einen Überblick über Fehlermeldungen und Fehlerbehebung.

Fehlermeldung | Form der Fehlermeldung | Fehler | Fehlerbehebung
------------- | ---------------------- | ------ | --------------
Bitte geben Sie eine E-Mail-Adresse ein. | Rot umrahmtes Eingabefeld und Dialogfeld | Die eingebene E-Mail-Adresse weist nicht die für eine E-Mail-Adresse typische Zeichenfolge auf (alphanumerische Zeichen @ alphanumerische Zeichen). | Gib eine korrekte E-Mail-Adresse ein.
Konnte User nicht speichern: Es sind n Fehler aufgetreten: Email muss ausgefüllt werden | Roter Kasten am Seitenanfang | Das Feld für die E-Mail-Adresse ist nicht ausgeüllt worden. | Gib eine E-Mail-Adresse in das entsprechende Feld ein.
Konnte User nicht speichern: Es sind n Fehler aufgetreten: Email ist bereits vergeben | Roter Kasten am Seitenanfang | Zur die eingegebenen E-Mail-Adresse existiert bereits ein MaMpf-Account. | Verwende eine andere E-Mail-Adresse oder setze das Passwort für den Account zurück (klicke dazu auf <button name="button">Passwort vergessen?</button>).
Konnte User nicht speichern: Es sind n Fehler aufgetreten: Passwort muss ausgefüllt werden. | Roter Kasten am Seitenanfang | Kein Passwort angegeben. | Gib ein Passwort ein.
Konnte User nicht speichern: Es sind n Fehler aufgetreten: Passwort ist zu kurz (weniger als 6 Zeichen) | Roter Kasten am Seitenanfang | Das Passwort ist zu kurz. | Wähle ein längeres Passwort. Dieses muss aus mindestens sechs Zeichen bestehen.
Konnte User nicht speichern: Es sind n Fehler aufgetreten: Passwortbestätigung stimmt nicht mit Passwort überein | Roter Kasten am Seitenanfang | Passwort und Passwortbestätigung stimmen nicht überein. | Gib das Passwort und die Passwortbestätigung erneut ein.
Du hast der Speicherung und Verarbeitung Deiner Daten nicht zugestimmt. | Dialogfeld | Der Haken zur Zustimmung zur Speicherung und Verarbeitung der Daten ist nicht gesetzt worden. | Setze den Haken, um der Speicherung und Verarbeitung der Daten zuzustimmen.

## Von dieser Seite aus aufrufbare Seiten
* [Login](login.md)
* [Passwort vergessen](password-forgotten.md)
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)

## Ähnliche Seiten
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)
* [Login](login.md)
* [Logout](logout.md)
* [Meine Startseite](my-home-page.md)
* [Passwort ändern](change-password.md)
* [Passwort vergessen](password-forgotten.md)
* [Profil](profile.md)
* [Startseite](home-page.md)
* [Zugangsdaten ändern](change-login-data.md)
