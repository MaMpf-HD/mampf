---
title: THymE
---

THymE steht für „The Hypermedia Experience“. Dabei handelt es sich um den Videoplayer der MaMpf. THymE zeichnet sich dadurch aus, dass sich Betrachter\*innen von Videos eine Gliederung und Referenzen anzeigen lassen können, sofern diese von Editor\*innen hinzugefügt worden sind.

<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme2.png"/>

## Navigation zu THymE
\*Realisierung überlegen und ergänzen\*

## Bereiche von THymE
THymE gliedert sich in drei Teilbereiche: das Bild, die Steuerleiste und die Informationspalte. Diese Bereich sind in den folgenden Screenshots eingezeichnet.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme2_bild.png" height="160"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme3_no_pip_steuerung.png" height="160"/> | <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme3_no_pip_infospalte.png" height="160"/>|
|:---: | :---: | :---:|
|Bild|Steuerleiste|Informationsspalte|

Die Informationsspalte besteht aus Informationen zum Medium, der Videogliederung und den Referenzen.

|<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme3_no_pip_medieninfo.png" height="260"/>| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme3_no_pip_gliederung.png" height="260"/>|
|:---: |:---: |
| Medieninformationen|Videogliederung|
| <img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme3_no_pip_zurueck.png" height="260"/> |<img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/thyme3_no_pip_referenzen.png" height="260"/> |
| Zurück-Zwischenraum |Referenzen|

## Bedienelemente und mögliche Aktionen
Im Folgenden werden sämtliche mögliche Bedienelemente von THymE aufgeführt.

### Bild
Durch Klicken auf das Bild kann die Wiedergabe pausiert bzw. fortgesetzt werden.

### Steuerleiste
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/play-arrow.png" height="12"/></button> bzw. <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/pause.png" height="9"/></button> Spiele das Video ab bzw. pausiere es.
* <input type="range" min="1" max="10" class="slider" id="myRange"/> Zeitsuchleiste. Verschiebe den Regler, um die Wiedergabe am gewünschten Punkt fortzusetzen.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/replay-10.png" height="18"/></button> Spule das Video zehn Sekunden zurück.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/forward-10.png" height="18"/></button> Spule das Video zehn Sekunden vor.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/skip-previous.png" height="10"/></button> Springe zum vorherigen Gliederungspunkt.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/skip-next.png" height="10"/></button> Springe zum nächsten Gliederungspunkt.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/volume-up.png" height="12"/></button> bzw. <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/volume-off.png" height="12"/></button> Schalte den Ton aus bzw. ein.
* <input type="range" min="1" max="10" class="slider" id="myRange" height="5" width="5"/> Lautstärkeregler. Verschiebe den Regler, um die Lautstärke anzupassen.
* <label for="cars"></label><select name="cars" id="cars">
  <option value="volvo">0.85x</option>
  <option value="saab" selected>1x</option>
  <option value="mercedes">1.25x</option>
  <option value="audi">1.5x</option>
  <option value="volvo1">1.75x</option>
  <option value="saab2">2x</option>
</select> Lege die Wiedergabegeschwindigkeit fest. Zur Auswahl stehen das 0,85-, 1- (standardmäßig), 1,25-, 1,5-, 1,75- und 2-fache der Originalgeschwindigkeit.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/add-to-queue.png" height="12"/></button> bzw. <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/remove-from-queue.png" height="12"/></button> Blende die Informationsspalte ein bzw. aus.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/fullscreen.png" height="12"/></button> bzw. <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/fullscreen-exit.png" height="12"/></button> Wechsel in den Vollbildmodus bzw. beende den ihn.

### Informationsleiste

#### Informationen zum Medium
Mit dem Button <button name="button">x</button> kann die Informationsleiste geschlossen werden. Ansonsten gibt es sich in diesem Bereich keine weiteren Bedienelemente. Dort werden lediglich Informationen zum Medium aufführt, wie etwa der Medientyp und die übergeordnete Veranstaltung.

#### Videogliederung
Die Gliederung kann zum gezielten Springen im Video verwendet werden, in dem man auf den gewünschten <button name="button">Gliederungspunkt</button> klickt.

#### Zurück
Der <button name="button">Zurück zu ...</button>-Button ist nur nach einem Sprung mithilfe der Gliederung vorhanden. Er ermöglicht die Rückkehr zur Stelle im Video, von der aus man gesprungen ist.

#### Referenzen
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/video-library.png" height="12"/></button> Öffne das Video in THymE in einem neuen Tab.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/library-books.png" height="12"/></button> Öffne das PDF in einem neuen Tab.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/link.png" height="8"/></button> Öffne den externen Link in einem neuen Tab.
* <button name="button"><img src="https://media.githubusercontent.com/media/MaMpf-HD/mampf/docs/docs/static/img/videogame-asset.png" height="8"/></button> Öffne das Quiz in einem neuen Tab.

## Verwandtes

* [Veranstaltungsseite](event-series.md)
* [Sitzung](session.md)
* [Medium](medium.md)
