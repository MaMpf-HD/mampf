/**
  This file wraps up most functionality of the thyme player(s) concerning metadata.
*/
// eslint-disable-next-line no-unused-vars
class MetadataManager {
  constructor(metadataListId) {
    this.metadataListId = metadataListId;
  }

  load() {
    let initialMetadata = true;
    const videoId = thymeAttributes.video.id;
    const metadataElement = $("#" + videoId + ' track[kind="metadata"]').get(0);
    const metadataManager = this;

    /* after video metadata have been loaded, display chapters in the interactive area
     Originally (and more appropriately, according to the standards),
     only the 'loadedmetadata' event was used. However, Firefox triggers this event too soon,
     i.e. when the readyStates for chapters and elements are 1 (loading) instead of 2 (loaded)
     for the events, see https://www.w3schools.com/jsref/event_oncanplay.asp */
    video.addEventListener("loadedmetadata", function () {
      if (initialMetadata && metadataElement.readyState === 2) {
        metadataManager.#displayMetadata();
        initialMetadata = false;
      }
    });
    video.addEventListener("canplay", function () {
      if (initialMetadata && metadataElement.readyState === 2) {
        metadataManager.#displayMetadata();
        initialMetadata = false;
      }
    });
  }

  /* returns the jQuery object of all metadata elements that start before the
     given time in seconds */
  #metadataBefore(seconds) {
    return $('[id^="m-"]').not(this.#metadataAfter(seconds));
  }

  /* returns the jQuery object of all metadata elements that start after the
   given time in seconds */
  #metadataAfter(seconds) {
    const metaList = document.getElementById(this.metadataListId);
    const times = JSON.parse(metaList.dataset.times);
    if (times.length === 0) {
      return $();
    }
    for (let i = 0; i < times.length; i++) {
      if (times[i] > seconds) {
        const $nextMeta = $("#m-" + $.escapeSelector(times[i]));
        return $nextMeta.add($nextMeta.nextAll());
      }
    }
    return $();
  }

  /* for a given time, show all metadata elements that start before this time
   and hide all that start later */
  metaIntoView(time) {
    this.#metadataAfter(time).hide();
    const $before = this.#metadataBefore(time);
    $before.show();
    const previousLength = $before.length;
    if (previousLength > 0) {
      $before.get(previousLength - 1).scrollIntoView();
    }
  }

  // set up the metadata elements
  #displayMetadata() {
    const video = thymeAttributes.video;
    const metadataManager = this;
    const metadataListId = this.metadataListId;
    const $metaList = $("#" + metadataListId);
    const metadataElement = $("#" + video.id + ' track[kind="metadata"]').get(0);

    let metaTrack;
    if (metadataElement.readyState === 2 && (metaTrack = metadataElement.track)) {
      metaTrack.mode = "hidden";
      let times = [];
      // read out the metadata track cues and generate html elements for
      // metadata, run katex on them
      for (let i = 0; i < metaTrack.cues.length; i++) {
        const cue = metaTrack.cues[i];
        const meta = JSON.parse(cue.text);
        const start = cue.startTime;
        times.push(start);
        const $listItem = $("<li/>", {
          id: "m-" + start,
        });
        $listItem.hide();
        const $link = $("<a/>", {
          text: meta.reference,
          class: "item",
          id: "l-" + start,
        });
        const $videoIcon = $("<i/>", {
          text: "video_library",
          class: "material-icons",
        });
        const $videoRef = $("<a/>", {
          href: meta.video,
          target: "_blank",
        });
        $videoRef.append($videoIcon);
        if (!meta.video) {
          $videoRef.hide();
        }
        const $manIcon = $("<i/>", {
          text: "library_books",
          class: "material-icons",
        });
        const $manRef = $("<a/>", {
          href: meta.manuscript,
          target: "_blank",
        });
        $manRef.append($manIcon);
        if (!meta.manuscript) {
          $manRef.hide();
        }
        const $scriptIcon = $("<i/>", {
          text: "menu_book",
          class: "material-icons",
        });
        const $scriptRef = $("<a/>", {
          href: meta.script,
          target: "_blank",
        });
        $scriptRef.append($scriptIcon);
        if (!meta.script) {
          $scriptRef.hide();
        }
        const $quizIcon = $("<i/>", {
          text: "videogame_asset",
          class: "material-icons",
        });
        const $quizRef = $("<a/>", {
          href: meta.quiz,
          target: "_blank",
        });
        $quizRef.append($quizIcon);
        if (!meta.quiz) {
          $quizRef.hide();
        }
        const $extIcon = $("<i/>", {
          text: "link",
          class: "material-icons",
        });
        const $extRef = $("<a/>", {
          href: meta.link,
          target: "_blank",
        });
        $extRef.append($extIcon);
        if (!meta.link) {
          $extRef.hide();
        }
        const $description = $("<div/>", {
          text: meta.text,
          class: "mx-3",
        });
        const $explanation = $("<div/>", {
          text: meta.explanation,
          class: "m-3",
        });
        const $details = $("<div/>");
        $details.append($link).append($description).append($explanation);
        let $icons = $("<div/>", {
          style: "flex-shrink: 3; display: flex; flex-direction: column;",
        });
        $icons.append($videoRef).append($manRef).append($scriptRef).append($quizRef).append($extRef);
        $listItem.append($details).append($icons);
        $metaList.append($listItem);
        $videoRef.on("click", function () {
          video.pause();
        });
        $manRef.on("click", function () {
          video.pause();
        });
        $extRef.on("click", function () {
          video.pause();
        });
        $link.on("click", function () {
          // displayBackButton();
          video.currentTime = this.id.replace("l-", "");
        });
        let metaElement = $listItem.get(0);
        thymeUtility.renderLatex(metaElement);
      }
      // store metadata start times as data attribute
      $metaList.get(0).dataset.times = JSON.stringify(times);
      // if user jumps to a new position in the video, display all metadata
      // that start before this time and hide all that start later
      $(video).on("seeked", function () {
        const time = video.currentTime;
        metadataManager.metaIntoView(time);
      });
      // if the metadata cue changes, highlight all current media and scroll
      // them into view
      $(metaTrack).on("cuechange", function () {
        let j = 0;
        $("#" + metadataListId + " li").removeClass("current");
        while (j < this.activeCues.length) {
          const activeStart = this.activeCues[j].startTime;
          let metalink = document.getElementById("m-" + activeStart);
          if (metalink) {
            $(metalink).show();
            $(metalink).addClass("current");
          }
          ++j;
        }
        const currentLength = $("#" + metadataListId + " .current").length;
        if (currentLength > 0) {
          $("#" + metadataListId + " .current").get(length - 1).scrollIntoView();
        }
      });
    }
  }
}
