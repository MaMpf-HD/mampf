import { onVideoMetadataLoaded, renderLatex } from "./utility";

/**
  This file wraps up most functionality of the thyme player(s) concerning chapters.
*/
export class ChapterManager {
  constructor(chapterListId, iaBackButton) {
    this.chapterListId = chapterListId;
    this.iaBackButton = iaBackButton;
  }

  /**
   * Loads chapters from the video element and displays them in the interactive area.
   * @param {function} onLoad - Callback function that is called when chapters have been loaded.
   * It receives a boolean value that indicates whether chapters are present.
   */
  load(onLoad) {
    const chapters = this.#getChapters();
    const chapterManager = this;
    let notified = false;

    // "Chapters are ready" is tied to the chapters track element itself, not to a
    // single video event. onVideoMetadataLoaded/canplay can fire before the track
    // has parsed its cues (readyState 2) — notably when the video is already
    // buffered (e.g. under test). The old code only called onLoad from the
    // loadedmetadata handler, and only if the track happened to be ready at that
    // instant; otherwise onLoad never fired, onVideoDataReady hung, and the
    // content sidebar stayed hidden (flaky in CI). Listening to the track's own
    // load/error events as well makes onLoad fire exactly once, whichever wins.
    const notifyIfReady = () => {
      if (notified) {
        return;
      }
      if (chapters.readyState === 2) {
        notified = true;
        chapterManager.#displayChapters();
        if (onLoad) {
          onLoad(chapters.track ? (chapters.track.cues.length > 0) : false);
        }
      }
      else if (chapters.readyState === 3) {
        notified = true;
        if (onLoad) {
          onLoad(false);
        }
      }
    };

    notifyIfReady();
    chapters.addEventListener("load", notifyIfReady);
    chapters.addEventListener("error", notifyIfReady);
    onVideoMetadataLoaded(thymeAttributes.video, notifyIfReady);
    thymeAttributes.video.addEventListener("canplay", notifyIfReady);
  }

  previousChapterStart() {
    const currentTime = thymeAttributes.video.currentTime;
    // NOTE: We cannot use times as an attribute (yet) because it's initialized
    // before the dataset times is loaded into the HTML.
    const chapterList = document.getElementById(this.chapterListId);
    if (!chapterList || !chapterList.dataset.times) {
      console.error("Chapter list not found or dataset times not set.");
      return;
    }
    const times = JSON.parse(chapterList.dataset.times);
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

  #getChapters() {
    const videoId = thymeAttributes.video.id;
    return $("#" + videoId + ' track[kind="chapters"]').get(0);
  }

  #displayChapters() {
    const chapterListId = this.chapterListId;
    const iaBackButton = this.iaBackButton;
    const chapterList = $("#" + chapterListId);

    const chapters = this.#getChapters();
    if (chapters.readyState != 2) {
      return;
    }
    const track = chapters.track;
    if (!track) {
      return;
    }

    track.mode = "hidden";
    const times = [];
    // read out the chapter track cues and generate html elements for chapters,
    // run katex on them
    for (let i = 0; i < track.cues.length; i++) {
      const cue = track.cues[i];
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
      renderLatex(chapterElement);
      $link.data("text", chapterName);
      // if a chapter element is clicked, transport to chapter start time
      $link.on("click", function () {
        iaBackButton.update();
        thymeAttributes.video.currentTime = this.id.replace("c-", "");
      });
    }
    // store start times as data attribute
    chapterList.get(0).dataset.times = JSON.stringify(times);
    chapterList.show();
    // if the chapters cue changes (i.e. a switch between chapters), highlight
    // current chapter elment and scroll it into view, remove highlighting from
    // old chapter
    $(track).on("cuechange", function () {
      $("#" + chapterListId + " li a").removeClass("current");
      if (this.activeCues.length > 0) {
        const activeStart = this.activeCues[0].startTime;
        const chapter = document.getElementById("c-" + activeStart);
        if (chapter) {
          $(chapter).addClass("current");
          chapter.scrollIntoView();
        }
      }
    });
  }
}
