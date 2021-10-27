---
title: Quizzes erstellen
---
This page will be written soon.

## Fragen mit Parametern

Man kann im Fragen-Textfeld durch \\para{name, range} einen Parameter mit Bezeichnung name und Bereich range einführen.
z.B.: \\para{n, [1..5]}  
Es wird dann der Parametername getexed und blau markiert. Im Antwortfeld kann man dann die den Parameter verwenden, im obigen Bsp. zu Beispiel
in n^2
Wenn ein Nutzer dann die Frage im Quiz aufruft, spezialisiert MaMpf den Parameter in Fragentext und -antwort.
Also z.B:
Frage im Frageneditor:
Was ist das Quadrat von $\\para{n,[1..5]}$?
Antwort: Ausdruck -> n^2
Für Nutzer im Quiz dann z.B.: Was ist das Quadrat von 3?
Antwort: 9

![](/img/quiz_parameter.png)
