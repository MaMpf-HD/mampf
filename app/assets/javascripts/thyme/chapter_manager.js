/**
  This file wraps up most functionality of the thyme player(s) concerning chapters.
*/
class ChapterManager {

  loadChapters() {
    //TODO
  }

  previousChapterStart(seconds) {
    /* NOTE: We cannot use times as an attribute (yet) because it's initialized
       before the dataset times is loaded into the HTML. */
    const times = JSON.parse(document.getElementById('chapters').dataset.times);
    if (times.length === 0) {
      return;
    }
    for (let i = times.length - 1; i >= 0; i--) {
      if (times[i] < seconds) {
        if (seconds - times[i] > 3) {
          return times[i];
        } else if (i > 0) {
          return times[i - 1];
        }
      }
    }
  }

  nextChapterStart(seconds) {
    const times = JSON.parse(document.getElementById('chapters').dataset.times);
    if (times.length === 0) {
      return;
    }
    for (let i = 0; i < times.length; i++) {
      if (times[i] > seconds) {
        return times[i];
      }
    }
  }

};
