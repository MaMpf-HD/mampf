---
title: Zugangsdaten ändern
---
Auf der Seite „Zugangsdaten ändern“ kann man die E-Mail-Adresse und das Passwort zum Account ändern.

![](/img/Zugangsdaten_aendern_thumb.png)

## Navigation zu dieser Seite
Die Seite „Zugangsdaten ändern“ erreicht man, indem man zunächst über den Button User-cog-solid.png in der Navigationsleiste zur Seite „Profil“ navigiert. Dort betätigt man dann den Button `Zugangsdaten ändern`.

\*Icon\*

## Bereiche der Seite
Die Seite „Zugangsdaten ändern“ gliedert sich in drei große Teilbereiche: die eigentliche Seite „Zugangsdaten ändern“, die [Navigationsleiste](nav-bar.md) und den [Footer](footer.md). Die Bereiche sind exemplarisch in den folgenden Screenshots einer Seite „Sitzung“ eingezeichnet. Dieser Artikel widmet sich der eigentlichen Seite.

\*Screenshots\*

## Bedienelemente und mögliche Aktionen auf dieser Seite
Die Bedienelemente der Seite „Zugangsdaten ändern“ und mithilfe dieser mögliche Aktionen werden nun beschrieben.

* Emailadresse
  Feld für die E-Mail-Adresse. Standardmäßig ist hier die aktuelle E-Mail-Adresse eingetragen. Dieses Feld muss nur bearbeitet werden, wenn man den Account auf eine andere E-Mail-Adresse umstellen möchte. In diesem Fall gibt man hier die neue E-Mail-Adresse ein.
* Aktuelles Passwort
  Feld für das aktuelle Passwort. Dieses Feld muss ausgefüllt werden.
* Neues Passwort
  Feld für das neue Passwort. Dieses Feld muss nur ausgefüllt werden, wenn das Passwort geändert werden soll. Das neue Passwort muss mindestens aus sechs Zeichen bestehen.
* Bestätigung des neuen Passworts
  Feld zur Bestätigung des neuen Passworts. Dieses Feld muss nur ausgefüllt werden, wenn das Passwort geändert werden soll. Die Eingabe muss mit der im Feld für das neue Passwort übereinstimmen.
* `Update` Bestätige die Eingaben, um Änderungen durchzuführen.
* `Zurück` Wechsel auf die [Seite Profil](profile.md).

\*Boxen\*

## Änderungen vornehmen
Auf der Seite „Zugangsdaten ändern“ können E-Mail-Adresse und Passwort geändert werden. Es ist sowohl möglich, nur eine andere E-Mail-Adresse oder nur ein anderes Passwort festzulegen, als auch beide gleichzeitig zu bearbeiten.

### E-Mail-Adresse
Um den Account mit einer neuen E-Mail-Adresse zu verknüpfen, gibt man die gewünschte Adresse und das aktuelle Passwort in die dafür vorgesehenen Felder ein. Anschließend klickt man auf `Update`. Daraufhin wird man auf die [Startseite](home-page.md) geleitet, bleibt aber eingeloggt. Auf der Startseite ist nun folgender Text zu lesen:

![](/img/E-Mail-Adresse_geaendert2.png)

Zudem wird eine E-Mail von mampf@mathi.uni-heidelberg.de mit dem Betreff „Anleitung zur Bestätigung Deines MaMpf-Accounts“ an die neue Adresse geschickt.

![](/img/Mail_Account_bestaetigen.png)

Um die Änderung abzuschließen, muss man in der E-Mail auf „Account bestätigen“ klicken. Vorher kann man sich nur mit der alten E-Mail-Adresse anmelden, nicht aber mit der neuen. Nachdem die Umstellung erfolgt ist, erhält man folgende Fehlermeldung, wenn man versucht, sich mit der alten Adresse anzumelden:

![](/img/Login_Mail_PW_ungueltig2.png)

Hat man besagte E-Mail nach einigen Minuten nicht erhalten und wird auch nicht im Spamordner fündig, kann man sie erneut anfordern. Dazu führt man die eben beschriebenen Schritte nochmals durch oder lässt sich einen Aktivierunglink zuschicken wie auf der [Seite „Anleitung zur Bestätitung des Accounts erneut versenden“](activate-account.md) beschrieben.

### Passwort
Für die Änderung des Passworts muss man alle vorhandenen Felder ausfüllen. Dabei ist zu beachten, dass das neue Passwort aus mindestens sechs Zeichen bestehen muss. Nach der Bestätigung der Eingabe durch Betätigen des Buttons `Update` wird man auf die [Startseite](home-page.md) geschickt. Dort wird ist zu lesen:

![](/img/Passwort_geaendert3.png)

### E-Mail-Adresse und Passwort
Um E-Mail-Adresse und Passwort gleichzeitig zu ändern, füllt man alle vorhandenen Felder aus und trägt dabei die neue E-Mail-Adresse in das dafür vorgesehene Feld ein. Anschließend klickt man auf `Update` und den Aktivierungslink in der daraufhin erhaltenen E-Mail.

## Fehlermeldungen
Bei unvollständiger oder fehlerhafter Dateneingabe gibt MaMpf eine Fehlermeldung zurück. Die folgende Tabelle gibt einen Überblick über Fehlermeldungen und Fehlerbehebung.

Fehlermeldung | Form der Fehlermeldung | Fehler | Fehlerbehebung
------------- | ---------------------- | ------ | --------------
Bitte geben Sie eine E-Mail-Adresse ein. | Rot umrahmtes Eingabefeld und Dialogfeld | Die eingebene E-Mail-Adresse weist nicht die für eine E-Mail-Adresse typische Zeichenfolge auf (alphanumerische Zeichen @ alphanumerische Zeichen). | Gib eine korrekte E-Mail-Adresse ein.
Konnte User nicht speichern: Es ist ein Fehler aufgetreten: Email muss ausgefüllt werden | Roter Kasten am Seitenanfang | Das Feld für die E-Mail-Adresse ist nicht ausgeüllt worden. | Gib eine E-Mail-Adresse in das entsprechende Feld ein.
Konnte User nicht speichern: Es ist ein Fehler aufgetreten: Email ist bereits vergeben | Roter Kasten am Seitenanfang | Für die eingegebene E-Mail-Adresse existiert bereits ein MaMpf-Account. | Verwende eine andere E-Mail-Adresse oder setze das Passwort für diesen Account mithilfe der [Seite „Passwort vergessen“](password-forgotten.md) zurück.
Konnte User nicht speichern: Es ist ein Fehler aufgetreten: Aktuelles Passwort muss ausgefüllt werden. | Roter Kasten am Seitenanfang | Aktuelles Passwort nicht angegeben. | Gib das aktuelle Passwort ein.
Konnte User nicht speichern: Es ist ein Fehler aufgetreten. Aktuelles Passwort ist nicht gültig | Roter Kasten am Seitenanfang | Fehlerhaftes Passwort | Gib das aktuelle Passwort erneut ein. Falls das aktuelle Passwort unbekannt ist, kann es mithilfe der [Seite „Passwort vergessen“](password-forgotten.md) geändert werden.
Konnte User nicht speichern: Es ist ein Fehler aufgetreten: Passwort ist zu kurz (weniger als 6 Zeichen) | Roter Kasten am Seitenanfang | Das Passwort ist zu kurz. | Wähle ein längeres Passwort. Dieses muss aus mindestens sechs Zeichen bestehen.
Konnte User nicht speichern. Es sind 2 Fehler aufgetreten. Passwort muss ausgefüllt werden; Passwortbestätigung stimmt nicht mit Passwort überein | Roter Kasten am Seitenanfang | Unausgefülltes Passwortfeld. | Gib das neue Passwort ein.
Konnte User nicht speichern: Es ist ein Fehler aufgetreten: Passwortbestätigung stimmt nicht mit Passwort überein | Roter Kasten am Seitenanfang | Fehlende Passwortbestätigung oder Passwort und Passwortbestätigung stimmen nicht überein. | Gib das Passwort und die Passwortbestätigung erneut ein.

\*Screenshots\*

## Von dieser Seite aus aufrufbare Seite
Von Seite „Zugangsdaten ändern“ aus kann nur zur [Seite „Profil“](profile.md) navigiert werden. Dies erfolgt über den Button `Zurück`.

## Ähnliche Seiten
* [Anleitung zur Bestätigung des Accounts erneut versenden](activate-account.md)
* [Login](login.md)
* [Logout](logout.md)
* [Meine Startseite](my-home-page.md)
* [Passwort ändern](change-password.md)
* [Passwort vergessen](password-forgotten.md)
* [Profil](profile.md)
* [Registrieren](registration.md)
* [Startseite](home-page.md)
