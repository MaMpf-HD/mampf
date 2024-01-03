/**
  All key shortcuts should be bundled here.
*/
const thymeKeyShortcuts = {
  /*
    SHORTCUT LIST:
      Arrow right - plus ten seconds
      Arrow left - minus ten seconds
      f - fullscreen
      Page up - volume up
      Page down - volume down
      m - mute
  */
  addGeneralShortcuts: function () {
    const video = document.getElementById("video");

    window.addEventListener("keydown", function (evt) {
      if (thymeAttributes.lockKeyListeners) {
        return;
      }
      const key = evt.key;
      if (key === " ") {
        if (video.paused) {
          video.play();
        }
        else {
          video.pause();
        }
      }
      else if (key === "ArrowRight") {
        $("#plus-ten").trigger("click");
      }
      else if (key === "ArrowLeft") {
        $("#minus-ten").trigger("click");
      }
      else if (key === "f") {
        $("#full-screen").trigger("click");
      }
      else if (key === "m") {
        $("#mute").trigger("click");
      }
      else if (key === "PageUp") {
        video.volume = Math.min(video.volume + 0.1, 1);
      }
      else if (key === "PageDown") {
        video.volume = Math.max(video.volume - 0.1, 0);
      }
    });
  },

  /*
    Thyme player specific

    SHORTCUT LIST:
      Arrow Up - next chapter
      Arrow Down - previous chapter
      i - toggle interactive area
  */
  addPlayerShortcuts() {
    window.addEventListener("keydown", function (evt) {
      if (thymeAttributes.lockKeyListeners) {
        return;
      }
      const key = evt.key;
      if (key === "i") {
        $("#ia-active").trigger("click");
      }
      else if (key === "ArrowUp") {
        $("#next-chapter").trigger("click");
      }
      else if (key === "ArrowDown") {
        $("#previous-chapter").trigger("click");
      }
      else if (key === "a") {
        $("#annotation-previous-button").trigger("click");
      }
      else if (key === "s") {
        $("#annotation-next-button").trigger("click");
      }
    });
  },

  /*
    Thyme feedback specific

    SHORTCUT LIST:
      q - toggle mistake annotations
      w - toggle presentation annotations
      e - toggle content annotations
      r - toggle note annotations
  */
  addFeedbackShortcuts() {
    window.addEventListener("keydown", function (evt) {
      if (thymeAttributes.lockKeyListeners) {
        return;
      }
      const key = evt.key;
      if (key === "q") {
        $("#toggle-mistake-annotations-check").trigger("click");
      }
      else if (key === "w") {
        $("#toggle-presentation-annotations-check").trigger("click");
      }
      else if (key === "e") {
        $("#toggle-content-annotations-check").trigger("click");
      }
      else if (key === "r") {
        $("#toggle-note-annotations-check").trigger("click");
      }
      else if (key === "a") {
        $("#annotation-previous-button").trigger("click");
      }
      else if (key === "s") {
        $("#annotation-next-button").trigger("click");
      }
    });
  },

  /*
    Thyme editor specific
  */
  // Add editor specific keyboard shortcuts here.
};
