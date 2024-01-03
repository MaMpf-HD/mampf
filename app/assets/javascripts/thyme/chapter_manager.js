/**
  This file wraps up most functionality of the thyme player(s) concerning chapters.
*/
// eslint-disable-next-line no-unused-vars
class ChapterManager {
  constructor(chapterListId, iaBackButton) {
    this.chapterListId = chapterListId;
    this.iaBackButton = iaBackButton;
  }

  load() {
    let initialChapters = true;
    const videoId = thymeAttributes.video.id;
    const chaptersElement = $("#" + videoId + ' track[kind="chapters"]').get(0);
    const chapterManager = this;

    /* after video metadata have been loaded, display chapters in the interactive area
     Originally (and more appropriately, according to the standards),
     only the 'loadedmetadata' event was used. However, Firefox triggers this event too soon,
     i.e. when the readyStates for chapters and elements are 1 (loading) instead of 2 (loaded)
     for the events, see https://www.w3schools.com/jsref/event_oncanplay.asp */
    video.addEventListener("loadedmetadata", function () {
      if (initialChapters && chaptersElement.readyState === 2) {
        chapterManager.#displayChapters();
        initialChapters = false;
      }
    });
    video.addEventListener("canplay", function () {
      if (initialChapters && chaptersElement.readyState === 2) {
        chapterManager.#displayChapters();
        initialChapters = false;
      }
    });
  }

  previousChapterStart() {
    const currentTime = thymeAttributes.video.currentTime;
    /* NOTE: We cannot use times as an attribute (yet) because it's initialized
       before the dataset times is loaded into the HTML. */
    const times = JSON.parse(document.getElementById(this.chapterListId).dataset.times);
    if (times.length === 0) {
      return;
    }
    for (let i = times.length - 1; i >= 0; i--) {
      if (times[i] < currentTime) {
        if (currentTime - times[i] > 3) {
          return times[i];
        }
        else if (i > 0) {
          return times[i - 1];
        }
      }
    }
  }

  nextChapterStart() {
    const currentTime = thymeAttributes.video.currentTime;
    const times = JSON.parse(document.getElementById(this.chapterListId).dataset.times);
    if (times.length === 0) {
      return;
    }
    for (let i = 0; i < times.length; i++) {
      if (times[i] > currentTime) {
        return times[i];
      }
    }
  }

  #displayChapters() {
    const videoId = thymeAttributes.video.id;
    const chapterListId = this.chapterListId;
    const iaBackButton = this.iaBackButton;
    const chapterList = $("#" + chapterListId);
    const chaptersElement = $("#" + videoId + ' track[kind="chapters"]').get(0);
    const currentChapter = $("#" + chapterListId + " .current");

    let chaptersTrack;
    if (chaptersElement.readyState === 2 && (chaptersTrack = chaptersElement.track)) {
      chaptersTrack.mode = "hidden";
      let times = [];
      // read out the chapter track cues and generate html elements for chapters,
      // run katex on them
      for (let i = 0; i < chaptersTrack.cues.length; i++) {
        const cue = chaptersTrack.cues[i];
        const chapterName = cue.text;
        const start = cue.startTime;
        times.push(start);
        const $listItem = $("<li/>");
        const $link = $("<a/>", {
          id: "c-" + start,
          text: chapterName,
        });
        chapterList.append($listItem.append($link));
        const chapterElement = $link.get(0);
        thymeUtility.renderLatex(chapterElement);
        $link.data("text", chapterName);
        // if a chapter element is clicked, transport to chapter start time
        $link.on("click", function () {
          iaBackButton.update();
          video.currentTime = this.id.replace("c-", "");
        });
      }
      // store start times as data attribute
      chapterList.get(0).dataset.times = JSON.stringify(times);
      chapterList.show();
      // if the chapters cue changes (i.e. a switch between chapters), highlight
      // current chapter elment and scroll it into view, remove highlighting from
      // old chapter
      $(chaptersTrack).on("cuechange", function () {
        $("#" + chapterListId + " li a").removeClass("current");
        if (this.activeCues.length > 0) {
          const activeStart = this.activeCues[0].startTime;
          let chapter;
          if (chapter = document.getElementById("c-" + activeStart)) {
            $(chapter).addClass("current");
            chapter.scrollIntoView();
          }
        }
      });
    }
  }
}
