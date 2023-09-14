/**
  Objects of this class represent chapters in JavaScript
*/
class Chapter {

  /*
       name = The name of the chapter.
    content = The HTML content of the chapter.
    seconds = The timestamp of the chapter's start in seconds.
   */
  constructor(name, content, seconds) {
    this.name = name;
    this.content = content;
    this.seconds = seconds;
  }

  goto() {
    thymeAttributes.video.currentTime = seconds;
  }

}